import 'package:border_player/app_preference.dart';
import 'package:border_player/component/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AutoPlayOnStartupControl extends StatefulWidget {
  const AutoPlayOnStartupControl({super.key});

  @override
  State<AutoPlayOnStartupControl> createState() =>
      _AutoPlayOnStartupControlState();
}

class _AutoPlayOnStartupControlState extends State<AutoPlayOnStartupControl> {
  final pref = AppPreference.instance.playbackPref;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "启动时恢复播放",
      action: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Symbols.play_circle),
            label: Text("开启"),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Symbols.pause_circle),
            label: Text("关闭"),
          ),
        ],
        selected: {pref.autoPlayOnStartup},
        onSelectionChanged: (newSelection) {
          setState(() {
            pref.autoPlayOnStartup = newSelection.first;
          });
        },
      ),
    );
  }
}
