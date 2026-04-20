import 'package:border_player/app_preference.dart';
import 'package:border_player/utils.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/component/audio_tile.dart';
import 'package:border_player/app_paths.dart' as app_paths;
import 'package:border_player/page/uni_detail_page.dart';
import 'package:border_player/page/uni_page.dart';
import 'package:border_player/page/uni_page_components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class ArtistDetailPage extends StatelessWidget {
  const ArtistDetailPage({super.key, required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final secondaryContent = List<Audio>.from(artist.works);
    final multiSelectController = MultiSelectController<Audio>();

    return UniDetailPage<Artist, Audio, Album>(
      pref: AppPreference.instance.artistDetailPagePref,
      primaryContent: artist,
      primaryPic: artist.picture,
      backgroundPic: artist.works.first.cover,
      picShape: PicShape.oval,
      title: artist.name,
      subtitle: "${artist.works.length} 首作品",
      secondaryContent: secondaryContent,
      secondaryContentBuilder: (context, audio, i, multiSelectController) =>
          AudioTile(
        audioIndex: i,
        playlist: secondaryContent,
        multiSelectController: multiSelectController,
      ),
      tertiaryContentTitle: "专辑",
      tertiaryContent: artist.albumsMap.values.toList(),
      tertiaryContentBuilder: (context, album, i, multiSelectController) =>
          ListTile(
        onTap: () => context.push(app_paths.ALBUM_DETAIL_PAGE, extra: album),
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        title: Text(
          album.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      enableShufflePlay: true,
      enableSortMethod: true,
      enableSortOrder: true,
      enableSecondaryContentViewSwitch: true,
      multiSelectController: multiSelectController,
      multiSelectViewActions: [
        AddAllToPlaylist(multiSelectController: multiSelectController),
        MultiSelectSelectOrClearAll(
          multiSelectController: multiSelectController,
          contentList: secondaryContent,
        ),
        MultiSelectExit(multiSelectController: multiSelectController),
      ],
      sortMethods: [
        SortMethodDesc(
          icon: Symbols.title,
          name: "标题",
          method: (list, order) {
            switch (order) {
              case SortOrder.ascending:
                list.sort((a, b) => a.title.localeCompareTo(b.title));
                break;
              case SortOrder.decending:
                list.sort((a, b) => b.title.localeCompareTo(a.title));
                break;
            }
          },
        ),
        SortMethodDesc(
          icon: Symbols.album,
          name: "专辑",
          method: (list, order) {
            switch (order) {
              case SortOrder.ascending:
                list.sort((a, b) => a.album.localeCompareTo(b.album));
                break;
              case SortOrder.decending:
                list.sort((a, b) => b.album.localeCompareTo(a.album));
                break;
            }
          },
        ),
        SortMethodDesc(
          icon: Symbols.add,
          name: "创建时间",
          method: (list, order) {
            switch (order) {
              case SortOrder.ascending:
                list.sort((a, b) => a.created.compareTo(b.created));
                break;
              case SortOrder.decending:
                list.sort((a, b) => b.created.compareTo(a.created));
                break;
            }
          },
        ),
        SortMethodDesc(
          icon: Symbols.edit,
          name: "修改时间",
          method: (list, order) {
            switch (order) {
              case SortOrder.ascending:
                list.sort((a, b) => a.modified.compareTo(b.modified));
                break;
              case SortOrder.decending:
                list.sort((a, b) => b.modified.compareTo(a.modified));
                break;
            }
          },
        ),
      ],
    );
  }
}
