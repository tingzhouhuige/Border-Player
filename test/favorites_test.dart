import 'dart:io';
import 'package:border_player/component/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:border_player/library/audio_library.dart';
import 'package:border_player/library/favorites.dart';
import 'package:flutter_test/flutter_test.dart';

Audio song(String path) =>
    Audio('歌曲', '艺术家', '专辑', 1, 180, null, null, path, 0, 0, null);

void main() {
  late Directory directory;
  late File file;
  late Favorites favorites;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('border_favorites_');
    file = File('${directory.path}/favorites.json');
    favorites = Favorites(file);
    await favorites.load();
  });

  tearDown(() async {
    favorites.dispose();
    await directory.delete(recursive: true);
  });

  test('favorites survive restart and program replacement in another folder',
      () async {
    final audio = song(r'D:\Music\歌曲.flac');
    await favorites.toggle(audio);
    final restarted = Favorites(file);
    await restarted.load();
    expect(restarted.contains(audio), isTrue);
    expect(restarted.audios.single.title, '歌曲');
    await restarted.toggle(audio);
    final again = Favorites(file);
    await again.load();
    expect(again.audios, isEmpty);
    restarted.dispose();
    again.dispose();
  });

  test('rapid writes are serialized and Windows path case is deduplicated',
      () async {
    final first = song(r'D:\Music\One.flac');
    final second = song(r'D:\Music\Two.flac');
    await Future.wait([favorites.toggle(first), favorites.toggle(second)]);
    expect(favorites.audios.length, 2);
    await favorites.toggle(song(r'd:/music/ONE.flac'));
    expect(favorites.contains(first), isFalse);
    final restarted = Favorites(file);
    await restarted.load();
    expect(restarted.audios.single.path, second.path);
    restarted.dispose();
  });

  test('unreadable data is preserved rather than replaced by an empty list',
      () async {
    await file.writeAsString('damaged original');
    final broken = Favorites(file);
    await expectLater(broken.load(), throwsFormatException);
    await expectLater(
        broken.toggle(song(r'D:\Music\One.flac')), throwsStateError);
    expect(await file.readAsString(), 'damaged original');
    broken.dispose();
  });

  test('failed writes leave state intact and allow a later retry', () async {
    final audio = song(r'D:\Music\One.flac');
    final blocked = Directory('${file.path}.tmp');
    await blocked.create();
    await expectLater(
        favorites.toggle(audio), throwsA(isA<FileSystemException>()));
    expect(favorites.contains(audio), isFalse);
    await blocked.delete();
    await favorites.toggle(audio);
    expect(favorites.contains(audio), isTrue);
  });

  testWidgets('heart buttons stay in sync and do not trigger the parent tap',
      (tester) async {
    Favorites.instance = favorites;
    final audio = song(r'D:\Music\One.flac');
    var parentTaps = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InkWell(
      onTap: () => parentTaps++,
      child: Row(children: [
        FavoriteButton(audio: audio),
        FavoriteButton(audio: audio)
      ]),
    ))));
    expect(find.byTooltip('喜爱歌曲'), findsNWidgets(2));
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('喜爱歌曲').first);
      // Wait for the serialized disk operation rather than a fixed delay.
      await favorites.removeAll([]);
    });
    await tester.pumpAndSettle();
    expect(find.byTooltip('取消喜爱'), findsNWidgets(2));
    expect(
        tester
            .widgetList<Icon>(find.byIcon(Symbols.favorite))
            .every((icon) => icon.fill == 1),
        isTrue);
    expect(parentTaps, 0);
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('取消喜爱').last);
      await favorites.removeAll([]);
    });
    await tester.pumpAndSettle();
    expect(find.byTooltip('喜爱歌曲'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
