import 'package:border_player/component/scroll_aware_future_builder.dart';
import 'package:border_player/app_motion.dart';
import 'package:border_player/page/now_playing_page/component/now_playing_popup.dart';
import 'package:border_player/utils.dart';
import 'package:border_player/app_settings.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/page/uni_page.dart';
import 'package:border_player/library/playlist.dart';
import 'package:border_player/app_paths.dart' as app_paths;
import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 由[playlist]和[audioIndex]确定audio，而不是直接传入audio，
/// 这是为了实现点击列表项播放乐曲时指定该列表为播放列表。
/// 同时，播放乐曲时也是需要index和playlist来定位audio和设置播放列表。
class AudioTile extends StatelessWidget {
  const AudioTile({
    super.key,
    required this.audioIndex,
    required this.playlist,
    this.focus = false,
    this.leading,
    this.action,
    this.multiSelectController,
  });

  final int audioIndex;
  final List<Audio> playlist;
  final bool focus;
  final Widget? leading;
  final Widget? action;
  final MultiSelectController? multiSelectController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final audio = playlist[audioIndex];

    return MenuAnchor(
      consumeOutsideTap: true,
      style: nowPlayingGlassMenuStyle(context),
      menuChildren: [
        /// artists
        AppMotion.menuEntryTransition(
          index: 0,
          child: SubmenuButton(
            style: nowPlayingGlassMenuItemStyle(context),
            menuStyle: nowPlayingGlassSubmenuStyle(context),
            menuChildren: List.generate(
              audio.splitedArtists.length,
              (i) => AppMotion.menuEntryTransition(
                index: i,
                child: MenuItemButton(
                  style: nowPlayingGlassMenuItemStyle(context),
                  onPressed: () {
                    final Artist artist = AudioLibrary
                        .instance.artistCollection[audio.splitedArtists[i]]!;
                    context.push(
                      app_paths.ARTIST_DETAIL_PAGE,
                      extra: artist,
                    );
                  },
                  leadingIcon: const Icon(Symbols.artist),
                  child: Text(audio.splitedArtists[i]),
                ),
              ),
            ),
            child: const Text("艺术家"),
          ),
        ),

        /// album
        AppMotion.menuEntryTransition(
          index: 1,
          child: MenuItemButton(
            style: nowPlayingGlassMenuItemStyle(context),
            onPressed: () {
              final Album album =
                  AudioLibrary.instance.albumCollection[audio.album]!;
              context.push(app_paths.ALBUM_DETAIL_PAGE, extra: album);
            },
            leadingIcon: const Icon(Symbols.album),
            child: Text(audio.album),
          ),
        ),

        /// 下一首播放
        AppMotion.menuEntryTransition(
          index: 2,
          child: MenuItemButton(
            style: nowPlayingGlassMenuItemStyle(context),
            onPressed: () {
              PlayService.instance.playbackService.addToNext(audio);
            },
            leadingIcon: const Icon(Symbols.plus_one),
            child: const Text("下一首播放"),
          ),
        ),

        /// 多选
        if (multiSelectController != null)
          AppMotion.menuEntryTransition(
            index: 3,
            child: MenuItemButton(
              style: nowPlayingGlassMenuItemStyle(context),
              onPressed: () {
                multiSelectController!.useMultiSelectView(true);
                multiSelectController!.select(audio);
              },
              leadingIcon: const Icon(Symbols.select),
              child: const Text("多选"),
            ),
          ),

        /// add to playlist
        AppMotion.menuEntryTransition(
          index: multiSelectController != null ? 4 : 3,
          child: SubmenuButton(
            style: nowPlayingGlassMenuItemStyle(context),
            menuStyle: nowPlayingGlassSubmenuStyle(context),
            menuChildren: List.generate(
              PLAYLISTS.length,
              (i) => AppMotion.menuEntryTransition(
                index: i,
                child: MenuItemButton(
                  style: nowPlayingGlassMenuItemStyle(context),
                  onPressed: () {
                    final added = PLAYLISTS[i].audios.containsKey(audio.path);
                    if (added) {
                      showTextOnSnackBar("歌曲“${audio.title}”已存在");
                      return;
                    }

                    PLAYLISTS[i].audios[audio.path] = audio;
                    showTextOnSnackBar(
                      "成功将“${audio.title}”添加到歌单“${PLAYLISTS[i].name}”",
                    );
                  },
                  leadingIcon: const Icon(Symbols.queue_music),
                  child: Text(PLAYLISTS[i].name),
                ),
              ),
            ),
            child: const Text("添加到歌单"),
          ),
        ),

        /// to detail page
        AppMotion.menuEntryTransition(
          index: multiSelectController != null ? 5 : 4,
          child: MenuItemButton(
            style: nowPlayingGlassMenuItemStyle(context),
            onPressed: () {
              context.push(app_paths.AUDIO_DETAIL_PAGE, extra: audio);
            },
            leadingIcon: const Icon(Symbols.info),
            child: const Text("详细信息"),
          ),
        ),
      ],
      builder: (context, controller, _) {
        final textColor = focus ? scheme.primary : scheme.onSurface;
        final useGlassAccent = AppSettings.instance.dynamicTheme &&
            AppSettings.instance.homeCoverBackdrop;
        final selectedFill = useGlassAccent
            ? Color.alphaBlend(
                scheme.primaryContainer.withValues(alpha: 0.14),
                scheme.surface.withValues(alpha: 0.30),
              )
            : scheme.secondaryContainer;
        final trackNumber = audio.track > 0 ? audio.track : audioIndex + 1;
        final placeholder = Icon(
          Symbols.broken_image,
          size: 42.0,
          color: scheme.onSurface,
        );

        return Ink(
          height: 56.0,
          decoration: BoxDecoration(
            color: multiSelectController == null
                ? Colors.transparent
                : multiSelectController!.selected.contains(audio)
                    ? selectedFill
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            focusColor: Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            onTap: () {
              if (controller.isOpen) {
                controller.close();
                return;
              }

              if (multiSelectController == null ||
                  !multiSelectController!.enableMultiSelectView) {
                PlayService.instance.playbackService.play(audioIndex, playlist);
              } else {
                if (multiSelectController!.selected.contains(audio)) {
                  multiSelectController!.unselect(audio);
                } else {
                  multiSelectController!.select(audio);
                }
              }
            },
            onSecondaryTapDown: (details) {
              if (multiSelectController?.enableMultiSelectView == true) return;

              if (useGlassAccent) {
                _showAudioGlassContextMenu(
                  context: context,
                  audio: audio,
                  multiSelectController: multiSelectController,
                  globalPosition: details.globalPosition,
                );
                return;
              }

              controller.open(
                position: details.localPosition.translate(0, -240),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 26.0, 0),
              child: Row(children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      child: leading!,
                    ),
                  ),
                if (leading == null) ...[
                  SizedBox(
                    width: 26,
                    child: Text(
                      trackNumber.toString().padLeft(2, "0"),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                /// cover
                ScrollAwareFutureBuilder(
                  cacheKey: audio.path,
                  future: () => audio.cover,
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return placeholder;
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: Image(
                        image: snapshot.data!,
                        width: 42.0,
                        height: 42.0,
                        errorBuilder: (_, __, ___) => placeholder,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14.0),

                /// title, artist and album
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        "${audio.artist} - ${audio.album}",
                        style: TextStyle(
                          color:
                              focus ? scheme.primary : scheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  Duration(seconds: audio.duration).toStringHMMSS(),
                  style: TextStyle(
                    color: focus ? scheme.primary : scheme.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (action != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: action!,
                  ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showAudioGlassContextMenu({
  required BuildContext context,
  required Audio audio,
  required MultiSelectController? multiSelectController,
  required Offset globalPosition,
}) {
  final itemCount = multiSelectController == null ? 5 : 6;
  return showNowPlayingGlassPopup<void>(
    context: context,
    globalPosition: globalPosition,
    width: 220,
    height: 18 + itemCount * 48,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: _AudioGlassContextMenu(
      audio: audio,
      multiSelectController: multiSelectController,
    ),
  );
}

class _AudioGlassContextMenu extends StatelessWidget {
  const _AudioGlassContextMenu({
    required this.audio,
    required this.multiSelectController,
  });

  final Audio audio;
  final MultiSelectController? multiSelectController;

  void _close(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (rowContext) => _GlassMenuRow(
            icon: Symbols.artist,
            label: "艺术家",
            trailing: Symbols.chevron_right,
            onPressed: () {
              _showArtistsSubmenu(
                context: rowContext,
                parentContext: context,
                audio: audio,
              );
            },
          ),
        ),
        _GlassMenuRow(
          icon: Symbols.album,
          label: audio.album,
          onPressed: () {
            _close(context);
            final album = AudioLibrary.instance.albumCollection[audio.album]!;
            context.push(app_paths.ALBUM_DETAIL_PAGE, extra: album);
          },
        ),
        _GlassMenuRow(
          icon: Symbols.plus_one,
          label: "下一首播放",
          onPressed: () {
            _close(context);
            PlayService.instance.playbackService.addToNext(audio);
          },
        ),
        if (multiSelectController != null)
          _GlassMenuRow(
            icon: Symbols.select,
            label: "多选",
            onPressed: () {
              _close(context);
              multiSelectController!.useMultiSelectView(true);
              multiSelectController!.select(audio);
            },
          ),
        Builder(
          builder: (rowContext) => _GlassMenuRow(
            icon: Symbols.queue_music,
            label: "添加到歌单",
            trailing: Symbols.chevron_right,
            enabled: PLAYLISTS.isNotEmpty,
            onPressed: () {
              _showPlaylistsSubmenu(
                context: rowContext,
                parentContext: context,
                audio: audio,
              );
            },
          ),
        ),
        _GlassMenuRow(
          icon: Symbols.info,
          label: "详细信息",
          onPressed: () {
            _close(context);
            context.push(app_paths.AUDIO_DETAIL_PAGE, extra: audio);
          },
        ),
      ],
    );
  }
}

Future<void> _showArtistsSubmenu({
  required BuildContext context,
  required BuildContext parentContext,
  required Audio audio,
}) {
  final height = (18 + audio.splitedArtists.length * 48).clamp(84, 320);
  return showNowPlayingGlassPopup<void>(
    context: context,
    width: 236,
    height: height.toDouble(),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: ListView(
      padding: EdgeInsets.zero,
      children: List.generate(
        audio.splitedArtists.length,
        (i) => _GlassMenuRow(
          icon: Symbols.artist,
          label: audio.splitedArtists[i],
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(parentContext, rootNavigator: true).pop();
            final artist = AudioLibrary
                .instance.artistCollection[audio.splitedArtists[i]]!;
            parentContext.push(app_paths.ARTIST_DETAIL_PAGE, extra: artist);
          },
        ),
      ),
    ),
  );
}

Future<void> _showPlaylistsSubmenu({
  required BuildContext context,
  required BuildContext parentContext,
  required Audio audio,
}) {
  final height = (18 + PLAYLISTS.length * 48).clamp(84, 360);
  return showNowPlayingGlassPopup<void>(
    context: context,
    width: 236,
    height: height.toDouble(),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: ListView(
      padding: EdgeInsets.zero,
      children: List.generate(
        PLAYLISTS.length,
        (i) => _GlassMenuRow(
          icon: Symbols.queue_music,
          label: PLAYLISTS[i].name,
          onPressed: () {
            final added = PLAYLISTS[i].audios.containsKey(audio.path);
            if (added) {
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(parentContext, rootNavigator: true).pop();
              showTextOnSnackBar("歌曲“${audio.title}”已存在");
              return;
            }

            PLAYLISTS[i].audios[audio.path] = audio;
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(parentContext, rootNavigator: true).pop();
            showTextOnSnackBar(
              "成功将“${audio.title}”添加到歌单“${PLAYLISTS[i].name}”",
            );
          },
        ),
      ),
    ),
  );
}

class _GlassMenuRow extends StatelessWidget {
  const _GlassMenuRow({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailing,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final IconData? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Icon(
                      icon,
                      size: 22,
                      color: scheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Icon(
                      trailing,
                      size: 22,
                      color: scheme.onSurface.withValues(alpha: 0.58),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
