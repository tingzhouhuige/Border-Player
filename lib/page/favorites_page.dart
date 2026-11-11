import 'package:border_player/app_preference.dart';
import 'package:border_player/component/audio_tile.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/library/favorites.dart';
import 'package:border_player/page/uni_page.dart';
import 'package:border_player/utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Favorites.instance,
        builder: (context, _) {
          final audios = Favorites.instance.audios;
          return UniPage<Audio>(
            pref: AppPreference.instance.favoritesPagePref,
            title: '喜爱歌曲',
            subtitle:
                audios.isEmpty ? '点击歌曲旁的爱心，将喜欢的音乐留在这里' : '${audios.length} 首乐曲',
            contentList: audios,
            contentBuilder: (context, item, index, controller) => AudioTile(
              audioIndex: index,
              playlist: audios,
            ),
            enableShufflePlay: true,
            enableSortMethod: true,
            enableSortOrder: true,
            enableContentViewSwitch: true,
            sortMethods: [
              SortMethodDesc(
                icon: Symbols.title,
                name: '标题',
                nameExtractor: (Audio audio) => audio.title,
                method: (list, order) => list.sort((a, b) =>
                    order == SortOrder.ascending
                        ? a.title.localeCompareTo(b.title)
                        : b.title.localeCompareTo(a.title)),
              ),
              SortMethodDesc(
                icon: Symbols.artist,
                name: '艺术家',
                nameExtractor: (Audio audio) => audio.artist,
                method: (list, order) => list.sort((a, b) =>
                    order == SortOrder.ascending
                        ? a.artist.localeCompareTo(b.artist)
                        : b.artist.localeCompareTo(a.artist)),
              ),
            ],
          );
        },
      );
}
