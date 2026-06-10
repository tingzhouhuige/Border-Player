import 'package:border_player/app_settings.dart';
import 'package:border_player/app_motion.dart';
import 'package:border_player/component/build_index_state_view.dart';
import 'package:border_player/component/glass_dock_surface.dart';
import 'package:border_player/component/settings_tile.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/library/play_statistics.dart';
import 'package:border_player/library/playlist.dart';
import 'package:border_player/lyric/lyric_source.dart';
import 'package:border_player/page/settings_page/settings_dialog.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class DefaultLyricSourceControl extends StatefulWidget {
  const DefaultLyricSourceControl({super.key});

  @override
  State<DefaultLyricSourceControl> createState() =>
      _DefaultLyricSourceControlState();
}

class _DefaultLyricSourceControlState extends State<DefaultLyricSourceControl> {
  final settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "首选歌词来源",
      action: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Symbols.cloud_off),
            label: Text("本地"),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Symbols.cloud),
            label: Text("在线"),
          ),
        ],
        selected: {settings.localLyricFirst},
        onSelectionChanged: (newSelection) async {
          if (newSelection.first == settings.localLyricFirst) return;

          setState(() {
            settings.localLyricFirst = newSelection.first;
          });
          await settings.saveSettings();
        },
      ),
    );
  }
}

class AudioLibraryEditor extends StatelessWidget {
  const AudioLibraryEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "文件夹管理",
      action: FilledButton.icon(
        icon: const Icon(Symbols.folder),
        label: const Text("文件夹管理"),
        onPressed: () {
          showSettingsGlassDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AudioLibraryEditorDialog(),
          );
        },
      ),
    );
  }
}

class PlayStatisticsControl extends StatelessWidget {
  const PlayStatisticsControl({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "听歌统计",
      action: FilledButton.icon(
        icon: const Icon(Symbols.bar_chart),
        label: const Text("统计"),
        onPressed: () {
          showSettingsGlassDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => const PlayStatisticsDialog(),
          );
        },
      ),
    );
  }
}

class PlayStatisticsDialog extends StatefulWidget {
  const PlayStatisticsDialog({super.key});

  @override
  State<PlayStatisticsDialog> createState() => _PlayStatisticsDialogState();
}

class _PlayStatisticsDialogState extends State<PlayStatisticsDialog> {
  PlayStatRange _range = PlayStatRange.total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsGlassDialog(
      title: "听歌统计",
      width: 720,
      height: 580,
      titleActions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final range in PlayStatRange.values) ...[
              _StatisticRangeButton(
                range: range,
                selected: _range == range,
                onTap: () {
                  setState(() {
                    _range = range;
                  });
                },
              ),
              if (range != PlayStatRange.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
      actions: [
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () => Navigator.pop(context),
          child: const Text("关闭"),
        ),
      ],
      child: FutureBuilder<List<AudioPlayStat>>(
        future: PlayStatistics.instance.allStats(_range),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;
          if (stats.isEmpty) {
            return Center(
              child: Text(
                "暂无听歌记录",
                style: settingsDialogTextStyle(scheme),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: stats.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: scheme.outlineVariant.withOpacity(0.45),
            ),
            itemBuilder: (context, i) {
              final stat = stats[i];
              return SizedBox(
                height: 62,
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        "${i + 1}",
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.audio.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: settingsDialogTextStyle(scheme).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stat.audio.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      "${stat.count} 次",
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatisticRangeButton extends StatelessWidget {
  const _StatisticRangeButton({
    required this.range,
    required this.selected,
    required this.onTap,
  });

  final PlayStatRange range;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useHomeGlass = AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop;

    if (useHomeGlass) {
      return GlassDockSurface(
        borderRadius: BorderRadius.circular(999),
        height: 38,
        width: 38,
        shadowScale: selected ? 0.28 : 0.16,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                range.label,
                style: TextStyle(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 38,
          child: Center(
            child: Text(
              range.label,
              style: TextStyle(
                color: selected
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AudioLibraryEditorDialog extends StatefulWidget {
  const AudioLibraryEditorDialog({super.key});

  @override
  State<AudioLibraryEditorDialog> createState() =>
      _AudioLibraryEditorDialogState();
}

class _AudioLibraryEditorDialogState extends State<AudioLibraryEditorDialog> {
  final folders = List.generate(
    AudioLibrary.instance.folders.length,
    (i) => AudioLibrary.instance.folders[i].path,
  );

  final applicationSupportDirectory = getAppDataDir();

  bool editing = true;

  String? _pickFolder() {
    final dirPicker = DirectoryPicker();
    dirPicker.title = "选择文件夹";

    final dir = dirPicker.getDirectory();
    return dir?.path;
  }

  void _addFolderPath(String path) {
    if (folders.contains(path)) return;
    folders.add(path);
  }

  void _addFolder() {
    final path = _pickFolder();
    if (path == null) return;

    setState(() {
      _addFolderPath(path);
    });
  }

  void _scanPickedFolder() {
    final path = _pickFolder();
    if (path == null) return;

    setState(() {
      _addFolderPath(path);
      editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useHomeGlass = AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop;

    return SettingsGlassDialog(
      title: "管理文件夹",
      width: 650,
      height: 560,
      titleActions: [
        if (editing)
          useHomeGlass
              ? GlassDockSurface(
                  borderRadius: BorderRadius.circular(999),
                  height: 44,
                  shadowScale: 0.24,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: scheme.onSurface,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      fixedSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    onPressed: _scanPickedFolder,
                    icon: const Icon(Symbols.search, size: 20),
                    label: const Text("扫描音乐"),
                  ),
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    fixedSize: const Size.fromHeight(36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  onPressed: _scanPickedFolder,
                  icon: const Icon(Symbols.search, size: 20),
                  label: const Text("扫描音乐"),
                ),
      ],
      actions: [
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: editing ? _addFolder : null,
          child: const Text("添加"),
        ),
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () => Navigator.pop(context),
          child: const Text("取消"),
        ),
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: editing
              ? () {
                  setState(() {
                    editing = false;
                  });
                }
              : null,
          child: const Text("确定"),
        ),
      ],
      child: AnimatedSwitcher(
        duration: AppMotion.switcher,
        reverseDuration: AppMotion.quick,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: AppMotion.switcherTransition,
        child: editing
            ? ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: folders.length,
                itemExtent: 60,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(left: 16, right: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          folders[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: settingsDialogTextStyle(scheme),
                        ),
                      ),
                      IconButton(
                        color: scheme.error,
                        iconSize: 25,
                        onPressed: () {
                          setState(() {
                            folders.removeAt(i);
                          });
                        },
                        icon: const Icon(Symbols.delete),
                      ),
                    ],
                  ),
                ),
              )
            : FutureBuilder(
                future: applicationSupportDirectory,
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Center(
                      child: Text(
                        "Fail to get app data dir.",
                        style: settingsDialogTextStyle(scheme),
                      ),
                    );
                  }

                  return Center(
                    child: BuildIndexStateView(
                      indexPath: snapshot.data!,
                      folders: folders,
                      whenIndexBuilt: () async {
                        await Future.wait([
                          AudioLibrary.initFromIndex(),
                          PlayStatistics.instance.load(),
                          readPlaylists(),
                          readLyricSources(),
                        ]);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
