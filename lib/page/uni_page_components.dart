import 'package:border_player/app_settings.dart';
import 'package:border_player/component/glass_dock_surface.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:border_player/library/playlist.dart';
import 'package:border_player/page/uni_page.dart';
import 'package:border_player/play_service/play_service.dart';
import 'package:border_player/utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

ButtonStyle _selectIconButtonStyle(ColorScheme scheme) => IconButton.styleFrom(
      fixedSize: const Size(40, 40),
      backgroundColor:
          _useHomeGlassAccent() ? Colors.transparent : _accentFill(scheme),
      foregroundColor: scheme.onSecondaryContainer,
      hoverColor: scheme.onSecondaryContainer.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      padding: EdgeInsets.zero,
    );

bool _useHomeGlassAccent() {
  final settings = AppSettings.instance;
  return settings.dynamicTheme && settings.homeCoverBackdrop;
}

Color _accentFill(ColorScheme scheme) {
  return _useHomeGlassAccent()
      ? Color.alphaBlend(
          scheme.primaryContainer.withValues(alpha: 0.22),
          scheme.surface.withValues(alpha: 0.34),
        )
      : scheme.secondaryContainer;
}

const _pageActionTextStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  height: 1.0,
);

const _pageActionButtonStyle = ButtonStyle(
  fixedSize: WidgetStatePropertyAll(Size.fromHeight(40)),
  textStyle: WidgetStatePropertyAll(_pageActionTextStyle),
);

ButtonStyle _pageActionButtonStyleFor(bool useGlass) {
  return _pageActionButtonStyle.copyWith(
    backgroundColor:
        useGlass ? const WidgetStatePropertyAll(Colors.transparent) : null,
    side: useGlass ? const WidgetStatePropertyAll(BorderSide.none) : null,
  );
}

Widget _dockAccent({
  required Widget child,
  required BorderRadius borderRadius,
  double shadowScale = 0.34,
}) {
  if (!_useHomeGlassAccent()) return child;
  return GlassDockSurface(
    borderRadius: borderRadius,
    shadowScale: shadowScale,
    child: child,
  );
}

Widget pageActionContent({
  required IconData icon,
  required String label,
  Color? color,
}) {
  return Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Transform.translate(
          offset: const Offset(0, 1),
          child: Text(
            label,
            style: _pageActionTextStyle.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class ShufflePlay<T> extends StatelessWidget {
  final List<T> contentList;
  const ShufflePlay({super.key, required this.contentList});

  @override
  Widget build(BuildContext context) {
    final useGlass = _useHomeGlassAccent();
    return _dockAccent(
      borderRadius: BorderRadius.circular(20),
      child: FilledButton(
        onPressed: () => PlayService.instance.playbackService.shuffleAndPlay(
          contentList as List<Audio>,
        ),
        style: _pageActionButtonStyleFor(useGlass),
        child: pageActionContent(icon: Symbols.shuffle, label: "随机播放"),
      ),
    );
  }
}

class PageActionButton extends StatelessWidget {
  const PageActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final useGlass = _useHomeGlassAccent();
    return _dockAccent(
      borderRadius: BorderRadius.circular(20),
      child: FilledButton(
        onPressed: onPressed,
        style: _pageActionButtonStyleFor(useGlass),
        child: pageActionContent(icon: icon, label: label),
      ),
    );
  }
}

class SortMethodComboBox<T> extends StatelessWidget {
  final List<T> contentList;
  final List<SortMethodDesc<T>> sortMethods;
  final SortMethodDesc<T> currSortMethod;
  final void Function(SortMethodDesc<T> sortMethod) setSortMethod;
  const SortMethodComboBox({
    super.key,
    required this.sortMethods,
    required this.contentList,
    required this.currSortMethod,
    required this.setSortMethod,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      menuChildren: List.generate(
        sortMethods.length,
        (i) => MenuItemButton(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.all(12)),
          ),
          leadingIcon: Icon(sortMethods[i].icon),
          child: Text(sortMethods[i].name),
          onPressed: () => setSortMethod(sortMethods[i]),
        ),
      ),
      builder: (context, menuController, _) {
        final borderRadius = BorderRadius.circular(20.0);

        final button = SizedBox(
          height: 40.0,
          child: Material(
            color: _useHomeGlassAccent()
                ? Colors.transparent
                : _accentFill(scheme),
            shape: const StadiumBorder(),
            child: InkWell(
              hoverColor: scheme.onSecondaryContainer.withValues(alpha: 0.08),
              borderRadius: borderRadius,
              onTap: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pageActionContent(
                      icon: Symbols.sort,
                      label: currSortMethod.name,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4.0),
                    Icon(
                      Symbols.arrow_drop_down,
                      size: 20,
                      color: scheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        if (_useHomeGlassAccent()) {
          return GlassDockSurface(
            borderRadius: BorderRadius.circular(20),
            child: button,
          );
        }
        return button;
      },
    );
  }
}

class SortOrderSwitch<T> extends StatelessWidget {
  final SortOrder sortOrder;
  final void Function(SortOrder order) setSortOrder;
  const SortOrderSwitch(
      {super.key, required this.sortOrder, required this.setSortOrder});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var isAscending = sortOrder == SortOrder.ascending;
    return _dockAccent(
      borderRadius: BorderRadius.circular(20),
      shadowScale: 0.24,
      child: IconButton.filledTonal(
        style: _selectIconButtonStyle(scheme),
        onPressed: () => setSortOrder(
          isAscending ? SortOrder.decending : SortOrder.ascending,
        ),
        icon: Icon(isAscending ? Symbols.arrow_upward : Symbols.arrow_downward),
      ),
    );
  }
}

class ContentViewSwitch<T> extends StatelessWidget {
  final ContentView contentView;
  final void Function(ContentView contentView) setContentView;
  const ContentViewSwitch(
      {super.key, required this.contentView, required this.setContentView});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var isListView = contentView == ContentView.list;
    return _dockAccent(
      borderRadius: BorderRadius.circular(20),
      shadowScale: 0.24,
      child: IconButton.filledTonal(
        style: _selectIconButtonStyle(scheme),
        onPressed: () => setContentView(
          isListView ? ContentView.table : ContentView.list,
        ),
        icon: Icon(isListView ? Symbols.list : Symbols.table),
      ),
    );
  }
}

class AddAllToPlaylist extends StatelessWidget {
  const AddAllToPlaylist({super.key, required this.multiSelectController});

  final MultiSelectController<Audio> multiSelectController;

  @override
  Widget build(BuildContext context) {
    final useGlass = _useHomeGlassAccent();
    return MenuAnchor(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      menuChildren: List.generate(
        PLAYLISTS.length,
        (i) => MenuItemButton(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
          onPressed: () {
            for (var item in multiSelectController.selected) {
              if (!PLAYLISTS[i].audios.containsKey(item.path)) {
                PLAYLISTS[i].audios[item.path] = item;
              }
            }
            showTextOnSnackBar(
              "成功将 ${multiSelectController.selected.length} 首添加到歌单 ${PLAYLISTS[i].name}",
            );
          },
          child: Text(PLAYLISTS[i].name),
        ),
      ),
      builder: (context, controller, _) => _dockAccent(
        borderRadius: BorderRadius.circular(20),
        child: FilledButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          style: _pageActionButtonStyleFor(useGlass),
          child: pageActionContent(icon: Symbols.add, label: "添加到歌单"),
        ),
      ),
    );
  }
}

class MultiSelectSelectOrClearAll<T> extends StatelessWidget {
  final MultiSelectController<T> multiSelectController;
  final List<T> contentList;

  const MultiSelectSelectOrClearAll(
      {super.key,
      required this.multiSelectController,
      required this.contentList});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: multiSelectController,
      builder: (context, _) => _dockAccent(
        borderRadius: BorderRadius.circular(20),
        shadowScale: 0.24,
        child: IconButton.filledTonal(
          style: _selectIconButtonStyle(scheme),
          onPressed: () {
            if (multiSelectController.selected.isEmpty) {
              multiSelectController.selectAll(contentList);
            } else {
              multiSelectController.clear();
            }
          },
          icon: Icon(
            multiSelectController.selected.isEmpty
                ? Symbols.select_all
                : Symbols.clear_all,
          ),
        ),
      ),
    );
  }
}

class MultiSelectExit<T> extends StatelessWidget {
  final MultiSelectController<T> multiSelectController;

  const MultiSelectExit({super.key, required this.multiSelectController});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _dockAccent(
      borderRadius: BorderRadius.circular(20),
      shadowScale: 0.24,
      child: IconButton.filledTonal(
        style: _selectIconButtonStyle(scheme),
        onPressed: () {
          multiSelectController.useMultiSelectView(false);
          multiSelectController.clear();
        },
        icon: const Icon(Symbols.cancel),
      ),
    );
  }
}
