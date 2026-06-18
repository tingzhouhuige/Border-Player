import 'dart:async';
import 'dart:math';

import 'package:border_player/app_settings.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/lyric/lrc.dart';
import 'package:border_player/lyric/lyric.dart';
import 'package:border_player/lyric/lyric_source.dart';
import 'package:border_player/music_matcher.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/foundation.dart';

/// 只通知 lyric 变更
class LyricService extends ChangeNotifier {
  final PlayService playService;

  late StreamSubscription _positionStreamSubscription;
  Lyric? _currentLyric;
  int _lyricRequestId = 0;

  LyricService(this.playService) {
    _positionStreamSubscription =
        playService.playbackService.positionStream.listen(_handlePosition);
  }

  Audio? _getNowPlaying() => playService.playbackService.nowPlaying;

  /// 供 widget 使用
  Future<Lyric?> currLyricFuture = Future.value(null);

  /// 下一行歌词
  int _nextLyricLine = 0;
  late final StreamController<int> _lyricLineStreamController =
      StreamController.broadcast(onListen: () {
    _lyricLineStreamController.add(max(_nextLyricLine - 1, 0));
  });

  Stream<int> get lyricLineStream => _lyricLineStreamController.stream;

  void _handlePosition(double pos) {
    final lyric = _currentLyric;
    if (lyric == null) return;
    if (_nextLyricLine >= lyric.lines.length) return;

    if ((pos * 1000) > lyric.lines[_nextLyricLine].start.inMilliseconds) {
      _nextLyricLine += 1;

      final currLineIndex = _nextLyricLine - 1;
      _lyricLineStreamController.add(currLineIndex);

      playService.desktopLyricService.canSendMessage.then((canSend) {
        if (!canSend) return;
        if (currLineIndex >= lyric.lines.length) return;

        final currLine = lyric.lines[currLineIndex];
        playService.desktopLyricService.sendLyricLineMessage(currLine);
      });
    }
  }

  void _setCurrLyricFuture(Future<Lyric?> future,
      {bool syncToPosition = true}) {
    final requestId = ++_lyricRequestId;
    _currentLyric = null;
    currLyricFuture = future;
    currLyricFuture.then((value) {
      if (requestId != _lyricRequestId) return;
      _currentLyric = value;
      if (syncToPosition) {
        findCurrLyricLine();
      } else {
        _nextLyricLine = 0;
        _lyricLineStreamController.add(0);
      }
    });
  }

  /// 重新计算歌词进行到第几行
  void findCurrLyricLine() {
    final value = _currentLyric;
    if (value == null) return;

    final next = value.lines.indexWhere(
      (element) =>
          element.start.inMilliseconds / 1000 >
          playService.playbackService.position,
    );
    _nextLyricLine = next == -1 ? value.lines.length : next;
    _lyricLineStreamController.add(max(_nextLyricLine - 1, 0));
  }

  Future<Lyric?> _getLyricDefault(bool localFirst) async {
    final nowPlaying = _getNowPlaying();
    if (nowPlaying == null) return Future.value(null);

    if (localFirst) {
      return (await Lrc.fromAudioPath(nowPlaying)) ??
          (await getMostMatchedLyric(nowPlaying));
    }
    return (await getMostMatchedLyric(nowPlaying)) ??
        (await Lrc.fromAudioPath(nowPlaying));
  }

  /// 根据默认歌词来源获取歌词：
  /// 1. 如果没有指定来源，按照现在的方式寻找歌词（本地优先或在线优先）
  /// 2. 如果指定来源，按照指定的来源获取
  void updateLyric() {
    final nowPlaying = _getNowPlaying();
    if (nowPlaying == null) return;

    final lyricSource = LYRIC_SOURCES[nowPlaying.path];
    if (lyricSource == null) {
      _setCurrLyricFuture(
        _getLyricDefault(AppSettings.instance.localLyricFirst),
      );
    } else {
      if (lyricSource.source == LyricSourceType.local) {
        _setCurrLyricFuture(
          Lrc.fromAudioPath(nowPlaying),
        );
      } else {
        _setCurrLyricFuture(
          getOnlineLyric(
            qqSongId: lyricSource.qqSongId,
            kugouSongHash: lyricSource.kugouSongHash,
            neteaseSongId: lyricSource.neteaseSongId,
          ),
        );
      }
    }

    notifyListeners();
  }

  void useLocalLyric() {
    final nowPlaying = _getNowPlaying();
    if (nowPlaying == null) return;

    _setCurrLyricFuture(Lrc.fromAudioPath(nowPlaying));

    notifyListeners();
  }

  void useOnlineLyric() {
    final nowPlaying = _getNowPlaying();
    if (nowPlaying == null) return;

    _setCurrLyricFuture(getMostMatchedLyric(nowPlaying));

    notifyListeners();
  }

  void useSpecificLyric(Lyric lyric) {
    _setCurrLyricFuture(Future.value(lyric));

    notifyListeners();
  }

  @override
  void dispose() {
    _lyricLineStreamController.close();
    _positionStreamSubscription.cancel();
    super.dispose();
  }
}
