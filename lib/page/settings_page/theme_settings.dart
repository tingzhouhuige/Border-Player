import 'package:border_player/app_settings.dart';
import 'package:border_player/component/settings_tile.dart';
import 'package:border_player/page/settings_page/settings_dialog.dart';
import 'package:border_player/page/settings_page/theme_picker_dialog.dart';
import 'package:border_player/theme_provider.dart';
import 'package:border_player/utils.dart';
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
              barrierColor: Colors.black.withOpacity(0.46),
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
    final currentFont = _fontOptions.firstWhere(
      (option) => option.family == theme.fontFamily,
      orElse: () => _fontOptions.first,
    );

    return SettingsGlassDialog(
      title: "选择字体",
      width: 560,
      height: 560,
      actions: [
        TextButton(
          style: settingsDialogActionStyle(scheme),
          onPressed: () => Navigator.pop(context),
          child: const Text("取消"),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "当前字体：${currentFont.label}",
            style: settingsDialogTextStyle(scheme).copyWith(
              color: scheme.onSurface.withOpacity(0.72),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _fontOptions.length,
                itemExtent: 58,
                itemBuilder: (context, i) {
                  final option = _fontOptions[i];
                  final selected = option.family == theme.fontFamily;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context, option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primaryContainer.withOpacity(0.38)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: settingsDialogTextStyle(scheme).copyWith(
                          fontFamily: option.family,
                          fontSize: 18,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
