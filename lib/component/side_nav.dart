// ignore_for_file: camel_case_types

import 'package:coriander_player/app_preference.dart';
import 'package:coriander_player/component/responsive_builder.dart';
import 'package:coriander_player/app_paths.dart' as app_paths;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class DestinationDesc {
  final IconData icon;
  final String label;
  final String desPath;
  DestinationDesc(this.icon, this.label, this.desPath);
}

final destinations = <DestinationDesc>[
  DestinationDesc(Symbols.library_music, "音乐", app_paths.AUDIOS_PAGE),
  DestinationDesc(Symbols.artist, "艺术家", app_paths.ARTISTS_PAGE),
  DestinationDesc(Symbols.album, "专辑", app_paths.ALBUMS_PAGE),
  DestinationDesc(Symbols.folder, "文件夹", app_paths.FOLDERS_PAGE),
  DestinationDesc(Symbols.list, "歌单", app_paths.PLAYLISTS_PAGE),
  DestinationDesc(Symbols.search, "搜索", app_paths.SEARCH_PAGE),
  DestinationDesc(Symbols.settings, "设置", app_paths.SETTINGS_PAGE),
];

class SideNav extends StatelessWidget {
  const SideNav({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();
    int selected = destinations.indexWhere(
      (desc) => location.startsWith(desc.desPath),
    );

    void onDestinationSelected(int value) {
      if (value == selected) return;

      final index = app_paths.START_PAGES.indexOf(destinations[value].desPath);
      if (index != -1) AppPreference.instance.startPage = index;

      context.push(destinations[value].desPath);

      var scaffold = Scaffold.of(context);
      if (scaffold.hasDrawer) scaffold.closeDrawer();
    }

    return ResponsiveBuilder(
      builder: (context, screenType) {
        switch (screenType) {
          case ScreenType.small:
            return Drawer(
              backgroundColor: scheme.surfaceContainer,
              shape: const RoundedRectangleBorder(),
              child: _LargeSideNavContent(
                selected: selected,
                onDestinationSelected: onDestinationSelected,
              ),
            );
          case ScreenType.large:
            return SizedBox(
              width: 244,
              child: _LargeSideNavContent(
                selected: selected,
                onDestinationSelected: onDestinationSelected,
              ),
            );
          case ScreenType.medium:
            return NavigationRail(
              backgroundColor: scheme.surfaceContainer,
              selectedIndex: selected,
              onDestinationSelected: onDestinationSelected,
              destinations: List.generate(
                destinations.length,
                (i) => NavigationRailDestination(
                  icon: Icon(destinations[i].icon),
                  label: Text(destinations[i].label),
                ),
              ),
            );
        }
      },
    );
  }
}

class _LargeSideNavContent extends StatelessWidget {
  const _LargeSideNavContent({
    required this.selected,
    required this.onDestinationSelected,
  });

  final int selected;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HomePill(colorScheme: scheme),
            const SizedBox(height: 28),
            for (var i = 0; i < destinations.length; i++) ...[
              _SideNavItem(
                icon: destinations[i].icon,
                label: destinations[i].label,
                selected: selected == i,
                onTap: () => onDestinationSelected(i),
              ),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Border Player",
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _HomePill extends StatelessWidget {
  const _HomePill({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withOpacity(0.25),
            child: Icon(Symbols.music_note, color: colorScheme.onSurface),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Border Player",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Desktop Music",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 22, color: scheme.onSurface),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 18),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
