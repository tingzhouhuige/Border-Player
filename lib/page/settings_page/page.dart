import 'package:coriander_player/page/page_scaffold.dart';
import 'package:coriander_player/page/settings_page/artist_separator_editor.dart';
import 'package:coriander_player/page/settings_page/other_settings.dart';
import 'package:coriander_player/page/settings_page/theme_settings.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: "设置",
      actions: const [],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96.0),
        children: const [
          AudioLibraryEditor(),
          DefaultLyricSourceControl(),
          ThemeModeControl(),
          SelectFontCombobox(),
          ArtistSeparatorEditor(),
        ],
      ),
    );
  }
}
