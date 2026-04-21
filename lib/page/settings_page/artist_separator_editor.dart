import 'package:border_player/app_settings.dart';
import 'package:border_player/component/settings_tile.dart';
import 'package:border_player/hotkeys_helper.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/page/settings_page/settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ArtistSeparatorEditor extends StatelessWidget {
  const ArtistSeparatorEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "自定义艺术家分隔符",
      action: FilledButton.icon(
        icon: const Icon(Symbols.edit),
        label: const Text("管理艺术家分隔符"),
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.46),
            builder: (context) => const _ArtistSeparatorEditDialog(),
          );
        },
      ),
    );
  }
}
class _ArtistSeparatorEditDialog extends StatefulWidget {
  const _ArtistSeparatorEditDialog();

  @override
  State<_ArtistSeparatorEditDialog> createState() =>
      __ArtistSeparatorEditDialogState();
}

class __ArtistSeparatorEditDialogState
    extends State<_ArtistSeparatorEditDialog> {
  final appSettings = AppSettings.instance;
  final currEditController = TextEditingController();
  late List<String> separators = List.from(appSettings.artistSeparator);
  bool editing = false;

  @override
  void dispose() {
    currEditController.dispose();
    super.dispose();
  }

  void _addArtistSeparator() {
    final value = currEditController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      if (!separators.contains(value)) {
        separators.add(value);
      }
      currEditController.clear();
      editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsGlassDialog(
      title: "管理艺术家分隔符",
      width: 560,
      height: 500,
      actions: [
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () {
            setState(() {
              editing = true;
            });
          },
          child: const Text("新增"),
        ),
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () => Navigator.pop(context),
          child: const Text("取消"),
        ),
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: editing
              ? null
              : () async {
                  appSettings.artistSeparator = separators;
                  appSettings.artistSplitPattern =
                      appSettings.artistSeparator.join("|");
                  await appSettings.saveSettings();
                  await AudioLibrary.initFromIndex();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
          child: const Text("确定"),
        ),
      ],
      child: Material(
        type: MaterialType.transparency,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (editing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 28, 10),
                child: Focus(
                  onFocusChange: HotkeysHelper.onFocusChanges,
                  child: TextField(
                    controller: currEditController,
                    autofocus: true,
                    style: settingsDialogTextStyle(scheme),
                    decoration: InputDecoration(
                      hintText: "输入新的分隔符",
                      hintStyle: settingsDialogTextStyle(scheme).copyWith(
                        color: scheme.onSurface.withOpacity(0.36),
                      ),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        onPressed: _addArtistSeparator,
                        icon: const Icon(Symbols.done),
                      ),
                    ),
                    onSubmitted: (_) => _addArtistSeparator(),
                  ),
                ),
              ),
            for (final item in separators)
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item,
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
                            separators.remove(item);
                          });
                        },
                        icon: const Icon(Symbols.delete),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
