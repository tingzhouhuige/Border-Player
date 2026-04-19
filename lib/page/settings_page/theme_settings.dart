import 'package:coriander_player/utils.dart';
import 'package:coriander_player/app_settings.dart';
import 'package:coriander_player/component/settings_tile.dart';
import 'package:coriander_player/page/settings_page/theme_picker_dialog.dart';
import 'package:coriander_player/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "修改主题",
      action: FilledButton.icon(
        onPressed: () async {
          final seedColor = await showDialog<Color>(
            context: context,
            builder: (context) => const ThemePickerDialog(),
          );
          if (seedColor == null) return;

          ThemeProvider.instance.applyTheme(seedColor: seedColor);
          AppSettings.instance.defaultTheme = seedColor.value;
          await AppSettings.instance.saveSettings();
        },
        label: const Text("主题选择器"),
        icon: const Icon(Symbols.palette),
      ),
    );
  }
}

class ThemeModeControl extends StatefulWidget {
  const ThemeModeControl({super.key});

  @override
  State<ThemeModeControl> createState() => _ThemeModeControlState();
}

class _ThemeModeControlState extends State<ThemeModeControl> {
  final settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "主题模式",
      action: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<ThemeMode>(
            value: ThemeMode.light,
            icon: Icon(Symbols.light_mode),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.dark,
            icon: Icon(Symbols.dark_mode),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (newSelection) async {
          if (newSelection.first == settings.themeMode) return;

          setState(() {
            settings.themeMode = newSelection.first;
          });
          ThemeProvider.instance.applyThemeMode(settings.themeMode);
          await settings.saveSettings();
        },
      ),
    );
  }
}

class DynamicThemeSwitch extends StatefulWidget {
  const DynamicThemeSwitch({super.key});

  @override
  State<DynamicThemeSwitch> createState() => _DynamicThemeSwitchState();
}

class _DynamicThemeSwitchState extends State<DynamicThemeSwitch> {
  final settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "动态主题",
      action: Switch(
        value: settings.dynamicTheme,
        onChanged: (_) async {
          setState(() {
            settings.dynamicTheme = !settings.dynamicTheme;
          });
          await settings.saveSettings();
        },
      ),
    );
  }
}

class UseSystemThemeSwitch extends StatefulWidget {
  const UseSystemThemeSwitch({super.key});

  @override
  State<UseSystemThemeSwitch> createState() => _UseSystemThemeSwitchState();
}

class _UseSystemThemeSwitchState extends State<UseSystemThemeSwitch> {
  final settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "启动时使用系统主题",
      action: Switch(
        value: settings.useSystemTheme,
        onChanged: (_) async {
          setState(() {
            settings.useSystemTheme = !settings.useSystemTheme;
          });
          await settings.saveSettings();
        },
      ),
    );
  }
}

class UseSystemThemeModeSwitch extends StatefulWidget {
  const UseSystemThemeModeSwitch({super.key});

  @override
  State<UseSystemThemeModeSwitch> createState() =>
      _UseSystemThemeModeSwitchState();
}

class _UseSystemThemeModeSwitchState extends State<UseSystemThemeModeSwitch> {
  final settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "启动时使用系统主题模式",
      action: Switch(
        value: settings.useSystemThemeMode,
        onChanged: (_) async {
          setState(() {
            settings.useSystemThemeMode = !settings.useSystemThemeMode;
          });
          await settings.saveSettings();
        },
      ),
    );
  }
}

class SelectFontCombobox extends StatelessWidget {
  const SelectFontCombobox({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: "字体",
      action: FilledButton.icon(
        onPressed: () async {
          if (context.mounted) {
            final selectedFont = await showDialog<_FontOption>(
              context: context,
              builder: (context) => const _FontSelector(),
            );
            if (selectedFont == null) return;

            try {
              ThemeProvider.instance.changeFontFamily(selectedFont.family);

              final settings = AppSettings.instance;
              settings.fontFamily = selectedFont.family;
              settings.fontPath = null;
              await settings.saveSettings();
            } catch (err) {
              ThemeProvider.instance.changeFontFamily(null);
              LOGGER.e("[select font] $err");
              if (context.mounted) {
                showTextOnSnackBar(err.toString());
              }
            }
          }
        },
        label: const Text("选择字体"),
        icon: const Icon(Symbols.text_fields),
      ),
    );
  }
}

class _FontOption {
  const _FontOption(this.label, this.family);

  final String label;
  final String? family;
}

const _fontOptions = [
  _FontOption("默认字体", null),
  _FontOption("微软雅黑", "Microsoft YaHei"),
  _FontOption("Inter", "Inter"),
  _FontOption("Noto Sans SC", "Noto Sans SC"),
  _FontOption("Times New Roman", "Times New Roman"),
  _FontOption("System Sans", "Segoe UI"),
];

class _FontSelector extends StatelessWidget {
  const _FontSelector();

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26.0),
      ),
      child: SizedBox(
        width: 476.0,
        height: 576,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "选择字体",
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                "当前字体：${_fontOptions.firstWhere(
                      (option) => option.family == theme.fontFamily,
                      orElse: () => _fontOptions.first,
                    ).label}",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18.0),
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView.builder(
                    itemCount: _fontOptions.length,
                    itemExtent: 72,
                    itemBuilder: (context, i) => ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      selected: _fontOptions[i].family == theme.fontFamily,
                      selectedTileColor: scheme.secondaryContainer,
                      title: Text(
                        _fontOptions[i].label,
                        style: TextStyle(
                          fontFamily: _fontOptions[i].family,
                          color: scheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, _fontOptions[i]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("取消"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
