import 'dart:convert';
import 'dart:io';

import 'package:border_player/app_settings.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/utils.dart';

class PlayStatistics {
  PlayStatistics._();

  static final PlayStatistics instance = PlayStatistics._();

  final Map<String, int> _legacyTotalCounts = {};
  final Map<String, List<DateTime>> _playEvents = {};

  bool _loaded = false;

  Future<File> _statsFile() async {
    final dir = await getAppDataDir();
    return File("${dir.path}\\play_statistics.json");
  }

  Future<void> load() async {
    if (_loaded) return;

    try {
      final file = await _statsFile();
      if (!file.existsSync()) {
        _loaded = true;
        return;
      }

      final raw = json.decode(await file.readAsString());
      if (raw is Map) {
        _legacyTotalCounts.clear();
        _playEvents.clear();

        if (raw["version"] == 2) {
          final totalCounts = raw["totalCounts"];
          if (totalCounts is Map) {
            _legacyTotalCounts.addAll(
              totalCounts.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is int ? value : int.tryParse(value.toString()) ?? 0,
                ),
              ),
            );
          }

          final events = raw["events"];
          if (events is Map) {
            for (final item in events.entries) {
              final value = item.value;
              if (value is! List) continue;
              _playEvents[item.key.toString()] = [
                for (final rawDate in value)
                  if (DateTime.tryParse(rawDate.toString()) != null)
                    DateTime.parse(rawDate.toString()),
              ];
            }
          }
        } else {
          _legacyTotalCounts.addAll(
            raw.map(
              (key, value) => MapEntry(
                key.toString(),
                value is int ? value : int.tryParse(value.toString()) ?? 0,
              ),
            ),
          );
        }
      }
    } catch (err, trace) {
      LOGGER.e("[play statistics] fail to load", error: err, stackTrace: trace);
    } finally {
      _loaded = true;
    }
  }

  Future<void> save() async {
    try {
      if (!_loaded) {
        await load();
      }

      final file = await _statsFile();
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      await file.writeAsString(
        const JsonEncoder.withIndent("  ").convert({
          "version": 2,
          "totalCounts": _legacyTotalCounts,
          "events": _playEvents.map(
            (key, value) => MapEntry(
              key,
              [for (final date in value) date.toIso8601String()],
            ),
          ),
        }),
      );
    } catch (err, trace) {
      LOGGER.e("[play statistics] fail to save", error: err, stackTrace: trace);
    }
  }

  Future<void> recordPlay(Audio audio) async {
    await load();
    _playEvents.putIfAbsent(audio.path, () => []).add(DateTime.now());
    await save();
  }

  int countOf(Audio audio, PlayStatRange range) {
    final path = audio.path;
    final events = _playEvents[path] ?? const [];

    if (range == PlayStatRange.total) {
      return (_legacyTotalCounts[path] ?? 0) + events.length;
    }

    final start = range.startOf(DateTime.now());
    return events.where((event) => !event.isBefore(start)).length;
  }

  Future<List<AudioPlayStat>> allStats(PlayStatRange range) async {
    await load();
    final stats = [
      for (final audio in AudioLibrary.instance.audioCollection)
        if (countOf(audio, range) > 0)
          AudioPlayStat(audio: audio, count: countOf(audio, range)),
    ];
    stats.sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) return countCompare;
      return a.audio.title.localeCompareTo(b.audio.title);
    });
    return stats;
  }
}

enum PlayStatRange {
  week("周"),
  month("月"),
  year("年"),
  total("总");

  const PlayStatRange(this.label);

  final String label;

  DateTime startOf(DateTime date) {
    switch (this) {
      case PlayStatRange.week:
        final today = DateTime(date.year, date.month, date.day);
        return today.subtract(Duration(days: today.weekday - 1));
      case PlayStatRange.month:
        return DateTime(date.year, date.month);
      case PlayStatRange.year:
        return DateTime(date.year);
      case PlayStatRange.total:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

class AudioPlayStat {
  const AudioPlayStat({
    required this.audio,
    required this.count,
  });

  final Audio audio;
  final int count;
}
