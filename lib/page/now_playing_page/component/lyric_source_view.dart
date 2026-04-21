import 'dart:math';

import 'package:border_player/library/audio_library.dart';
import 'package:border_player/lyric/lrc.dart';
import 'package:border_player/lyric/lyric.dart';
import 'package:border_player/lyric/lyric_source.dart';
import 'package:border_player/music_matcher.dart';
import 'package:border_player/page/now_playing_page/component/now_playing_popup.dart';
import 'package:border_player/page/now_playing_page/component/vertical_lyric_view.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SetLyricSourceBtn extends StatelessWidget {
  const SetLyricSourceBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayService.instance.lyricService,
      builder: (context, _) => FutureBuilder(
        future: PlayService.instance.lyricService.currLyricFuture,
        builder: (context, snapshot) {
          const loadingWidget = IconButton(
            onPressed: null,
            icon: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(),
            ),
          );
          final lyricNullable = snapshot.data;
          final isLocal = lyricNullable == null
              ? null
              : (lyricNullable is Lrc &&
                  lyricNullable.source == LrcSource.local);
          return switch (snapshot.connectionState) {
            ConnectionState.none => loadingWidget,
            ConnectionState.waiting => loadingWidget,
            ConnectionState.active => loadingWidget,
            ConnectionState.done => _SetLyricSourceBtn(isLocal: isLocal),
          };
        },
      ),
    );
  }
}

class _SetLyricSourceBtn extends StatelessWidget {
  final bool? isLocal;
  const _SetLyricSourceBtn({this.isLocal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lyricService = PlayService.instance.lyricService;
    return IconButton(
      onPressed: PlayService.instance.playbackService.nowPlaying == null
          ? null
          : () {
              ALWAYS_SHOW_LYRIC_VIEW_CONTROLS = true;
              showNowPlayingGlassPopup<void>(
                context: context,
                width: 170,
                height: 162,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  children: [
                    _LyricPopupAction(
                      label: "指定默认歌词",
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        final nowPlaying =
                            PlayService.instance.playbackService.nowPlaying;
                        showNowPlayingGlassPopup<void>(
                          context: context,
                          title: "默认歌词",
                          width: 540,
                          height: 560,
                          child: _SetLyricSourceDialog(audio: nowPlaying!),
                        );
                      },
                    ),
                    _LyricPopupAction(
                      label: "在线",
                      checked: isLocal == false,
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        lyricService.useOnlineLyric();
                      },
                    ),
                    _LyricPopupAction(
                      label: "本地",
                      checked: isLocal == true,
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        lyricService.useLocalLyric();
                      },
                    ),
                  ],
                ),
              ).whenComplete(() {
                ALWAYS_SHOW_LYRIC_VIEW_CONTROLS = false;
              });
            },
      icon: const Icon(Symbols.lyrics),
      color: scheme.onSecondaryContainer,
    );
  }
}

class _LyricPopupAction extends StatelessWidget {
  const _LyricPopupAction({
    required this.label,
    required this.onTap,
    this.checked = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: checked
                  ? Icon(Symbols.check, size: 20, color: scheme.onSurface)
                  : null,
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetLyricSourceDialog extends StatelessWidget {
  const _SetLyricSourceDialog({required this.audio});

  final Audio audio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text("使用本地歌词"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            onTap: () {
              LYRIC_SOURCES[audio.path] = LyricSource(LyricSourceType.local);
              PlayService.instance.lyricService.useLocalLyric();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder(
              future: uniSearch(audio),
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) => _LyricSourceTile(
                    audio: audio,
                    searchResult: snapshot.data![i],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricSourceTile extends StatefulWidget {
  const _LyricSourceTile({
    required this.searchResult,
    required this.audio,
  });

  final Audio audio;
  final SongSearchResult searchResult;

  @override
  State<_LyricSourceTile> createState() => _LyricSourceTileState();
}

class _LyricSourceTileState extends State<_LyricSourceTile> {
  late final lyric = getOnlineLyric(
    qqSongId: widget.searchResult.qqSongId,
    kugouSongHash: widget.searchResult.kugouSongHash,
    neteaseSongId: widget.searchResult.neteaseSongId,
  );
  @override
  Widget build(BuildContext context) {
    const loadingWidget = Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(),
        ),
      ),
    );
    return FutureBuilder(
      future: lyric,
      builder: (context, lyricSnapshot) =>
          switch (lyricSnapshot.connectionState) {
        ConnectionState.none => loadingWidget,
        ConnectionState.waiting => loadingWidget,
        ConnectionState.active => loadingWidget,
        ConnectionState.done =>
          lyricSnapshot.data == null || lyricSnapshot.data!.lines.isEmpty
              ? const SizedBox.shrink()
              : buildTile(
                  context,
                  widget.audio,
                  widget.searchResult,
                  lyricSnapshot.data!,
                ),
      },
    );
  }

  Widget buildTile(
    BuildContext context,
    Audio audio,
    SongSearchResult searchResult,
    Lyric lyric,
  ) {
    return ListTile(
      onTap: () {
        LyricSourceType source = switch (searchResult.source) {
          ResultSource.qq => LyricSourceType.qq,
          ResultSource.kugou => LyricSourceType.kugou,
          ResultSource.netease => LyricSourceType.netease,
        };
        LYRIC_SOURCES[audio.path] = LyricSource(
          source,
          qqSongId: searchResult.qqSongId,
          kugouSongHash: searchResult.kugouSongHash,
          neteaseSongId: searchResult.neteaseSongId,
        );
        PlayService.instance.lyricService.useSpecificLyric(lyric);

        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      leading: Text(lyric is Lrc ? "LRC" : "逐字"),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            searchResult.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "${searchResult.artists} - ${searchResult.album}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      subtitle: StreamBuilder(
        stream: PlayService.instance.playbackService.positionStream,
        builder: (context, positionSnapshot) {
          final currLineIndex = max(lyric.lines.lastIndexWhere(
            (element) {
              return element.start.inMilliseconds <
                  (positionSnapshot.data ?? 0) * 1000;
            },
          ), 0);

          final LyricLine currLine = lyric.lines[currLineIndex];
          if (currLine is LrcLine) {
            return Text(
              "当前：${currLine.content}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          } else {
            final syncLine = currLine as SyncLyricLine;

            return Text(
              "当前：${syncLine.content}${syncLine.translation != null ? "┃${syncLine.translation}" : ""}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }
        },
      ),
    );
  }
}
