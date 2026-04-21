import 'package:border_player/app_settings.dart';
import 'package:border_player/component/build_index_state_view.dart';
import 'package:border_player/component/settings_tile.dart';
import 'package:border_player/library/audio_library.dart';
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
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(0.46),
            builder: (context) => const AudioLibraryEditorDialog(),
          );
        },
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsGlassDialog(
      title: "管理文件夹",
      width: 650,
      height: 560,
      actions: [
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () async {
            final dirPicker = DirectoryPicker();
            dirPicker.title = "选择文件夹";

            final dir = dirPicker.getDirectory();
            if (dir == null) return;

            setState(() {
              folders.add(dir.path);
            });
          },
          child: const Text("添加"),
        ),
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () => Navigator.pop(context),
          child: const Text("取消"),
        ),
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () {
            setState(() {
              editing = false;
            });
          },
          child: const Text("确定"),
        ),
      ],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
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
                        tooltip: "移除",
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
