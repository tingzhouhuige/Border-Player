import 'package:border_player/app_settings.dart';
import 'package:border_player/app_paths.dart' as app_paths;
import 'package:border_player/component/glass_dock_surface.dart';
import 'package:border_player/hotkeys_helper.dart';
import 'package:border_player/library/audio_library.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class UnionSearchResult {
  String query;

  List<Audio> audios = [];
  List<Artist> artists = [];
  List<Album> album = [];

  UnionSearchResult(this.query);

  static UnionSearchResult search(String query) {
    final result = UnionSearchResult(query);

    final queryInLowerCase = query.toLowerCase();
    final library = AudioLibrary.instance;

    for (int i = 0; i < library.audioCollection.length; i++) {
      if (library.audioCollection[i].title
          .toLowerCase()
          .contains(queryInLowerCase)) {
        result.audios.add(library.audioCollection[i]);
      }
    }

    for (Artist item in library.artistCollection.values) {
      if (item.name.toLowerCase().contains(queryInLowerCase)) {
        result.artists.add(item);
      }
    }

    for (Album item in library.albumCollection.values) {
      if (item.name.toLowerCase().contains(queryInLowerCase)) {
        result.album.add(item);
      }
    }
    return result;
  }
}

final searchBarKey = GlobalKey();

InputBorder _searchInputBorder(
  ColorScheme scheme,
  bool useGlassBackdrop, {
  double alpha = 0.0,
  double width = 0.0,
}) {
  if (useGlassBackdrop) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    );
  }

  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(25),
    borderSide: BorderSide(
      color: scheme.primary.withValues(alpha: alpha),
      width: width,
    ),
  );
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useGlassBackdrop = AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop;

    return ColoredBox(
      color: useGlassBackdrop ? Colors.transparent : scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Transform.translate(
          offset: const Offset(0, -82),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "搜索",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 24.0),
              _SearchFieldGlow(
                useGlassBackdrop: useGlassBackdrop,
                child: SizedBox(
                  width: 448,
                  height: 50,
                  child: Focus(
                    onFocusChange: HotkeysHelper.onFocusChanges,
                    child: Hero(
                      tag: searchBarKey,
                      child: TextField(
                        autofocus: true,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: useGlassBackdrop
                              ? Colors.transparent
                              : scheme.surfaceContainer.withValues(alpha: 0.82),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Icon(
                              Symbols.search,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          hintText: "搜索歌曲、艺术家、专辑",
                          hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(24, 14, 12, 14),
                          border: _searchInputBorder(
                            scheme,
                            useGlassBackdrop,
                            alpha: 0.22,
                            width: 0.8,
                          ),
                          enabledBorder: _searchInputBorder(
                            scheme,
                            useGlassBackdrop,
                            alpha: 0.20,
                            width: 0.8,
                          ),
                          focusedBorder: _searchInputBorder(
                            scheme,
                            useGlassBackdrop,
                            alpha: 0.30,
                            width: 0.9,
                          ),
                          disabledBorder:
                              _searchInputBorder(scheme, useGlassBackdrop),
                          errorBorder:
                              _searchInputBorder(scheme, useGlassBackdrop),
                          focusedErrorBorder:
                              _searchInputBorder(scheme, useGlassBackdrop),
                        ),
                        onSubmitted: (String query) {
                          context.push(
                            app_paths.SEARCH_RESULT_PAGE,
                            extra: UnionSearchResult.search(query),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchFieldGlow extends StatelessWidget {
  const _SearchFieldGlow({
    required this.child,
    required this.useGlassBackdrop,
  });

  final Widget child;
  final bool useGlassBackdrop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (useGlassBackdrop) {
      return GlassDockSurface(
        borderRadius: BorderRadius.circular(25),
        shadowScale: 0.34,
        child: child,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.055),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.34),
                blurRadius: 18,
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: child,
          ),
        ),
      ],
    );
  }
}
