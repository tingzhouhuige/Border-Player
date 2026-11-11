import 'dart:convert';
import 'dart:io';
import 'package:border_player/app_settings.dart';

import 'package:border_player/library/audio_library.dart';
import 'package:border_player/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Stored with user data, independently of the executable and ordinary playlists.
class Favorites extends ChangeNotifier {
  Favorites(this.file);

  final File file;
  static late Favorites instance;
  Map<String, Audio> _audios = {};
  Future<void> _writes = Future.value();
  bool _loaded = false;

  static Future<void> initialize() async {
    instance =
        Favorites(File(p.join((await getAppDataDir()).path, 'favorites.json')));
    try {
      await instance.load();
    } catch (error, trace) {
      // Keep the original file intact if it cannot be read.
      LOGGER.e(error, stackTrace: trace);
    }
  }

  String _key(String path) => p.windows.normalize(path).toLowerCase();
  bool contains(Audio audio) => _audios.containsKey(_key(audio.path));

  List<Audio> get audios => _audios.values.toList();

  Future<void> load() async {
    final loaded = <String, Audio>{};
    if (await file.exists()) {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (data['version'] != 1) throw const FormatException('未知收藏数据版本');
      for (final item in data['audios'] as List) {
        final audio = Audio.fromMap(item as Map);
        loaded[_key(audio.path)] = audio;
      }
    }
    _audios = loaded;
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(Audio audio) => _update([audio], toggle: true);
  Future<void> removeAll(Iterable<Audio> audios) => _update(audios.toList());

  Future<void> _update(List<Audio> audios, {bool toggle = false}) {
    final operation = _writes.then((_) async {
      if (!_loaded) throw StateError('收藏数据未能读取，已保留原文件，请检查用户数据目录');
      final next = Map<String, Audio>.of(_audios);
      for (final audio in audios) {
        final key = _key(audio.path);
        if (toggle && !next.containsKey(key)) {
          next[key] = audio;
        } else {
          next.remove(key);
        }
      }
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
          jsonEncode({
            'version': 1,
            'audios': next.values.map((audio) => audio.toMap()).toList(),
          }),
          flush: true);
      await temporary.rename(file.path);
      _audios = next;
      notifyListeners();
    });
    // A failed write must not prevent subsequent attempts.
    _writes =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}
