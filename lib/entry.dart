import 'package:border_player/library/audio_library.dart';
import 'package:border_player/app_motion.dart';
import 'package:border_player/app_settings.dart';
import 'package:border_player/component/app_shell.dart';
import 'package:border_player/page/album_detail_page.dart';
import 'package:border_player/page/albums_page.dart';
import 'package:border_player/page/artist_detail_page.dart';
import 'package:border_player/page/artists_page.dart';
import 'package:border_player/page/audio_detail_page.dart';
import 'package:border_player/page/audios_page.dart';
import 'package:border_player/page/folder_detail_page.dart';
import 'package:border_player/page/folders_page.dart';
import 'package:border_player/page/now_playing_page/page.dart';
import 'package:border_player/page/playlist_detail_page.dart';
import 'package:border_player/page/playlists_page.dart';
import 'package:border_player/page/search_page/search_page.dart';
import 'package:border_player/page/search_page/search_result_page.dart';
import 'package:border_player/page/settings_page/page.dart';
import 'package:border_player/page/updating_page.dart';
import 'package:border_player/page/welcoming_page.dart';
import 'package:border_player/library/playlist.dart';
import 'package:border_player/theme_provider.dart';
import 'package:border_player/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:border_player/app_paths.dart' as app_paths;

class SlideTransitionPage<T> extends CustomTransitionPage<T> {
  SlideTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: _transitionsBuilder,
          transitionDuration: AppSettings.instance.dynamicTheme &&
                  AppSettings.instance.homeCoverBackdrop
              ? Duration.zero
              : AppMotion.page,
          reverseTransitionDuration: AppSettings.instance.dynamicTheme &&
                  AppSettings.instance.homeCoverBackdrop
              ? Duration.zero
              : AppMotion.pageReverse,
        );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop) {
      return child;
    }

    return AppMotion.pageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class Entry extends StatelessWidget {
  Entry({super.key, required this.welcome});
  final bool welcome;

  ThemeData fromSchemeAndFontFamily({
    required ColorScheme colorScheme,
    String? fontFamily,
  }) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    // For surfaces that use primary color in light themes and surface color in dark
    final Color primarySurfaceColor =
        isDark ? colorScheme.surface : colorScheme.primary;
    final Color onPrimarySurfaceColor =
        isDark ? colorScheme.onSurface : colorScheme.onPrimary;
    final bool useHomeGlass = AppSettings.instance.dynamicTheme &&
        AppSettings.instance.homeCoverBackdrop;
    final Color selectedControlColor = useHomeGlass
        ? Color.alphaBlend(
            colorScheme.primaryContainer.withValues(alpha: 0.16),
            colorScheme.surface.withValues(alpha: 0.34),
          )
        : colorScheme.secondaryContainer;
    final Color unselectedControlColor = useHomeGlass
        ? colorScheme.surface.withValues(alpha: 0.22)
        : colorScheme.surfaceContainer;

    return ThemeData(
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      primaryColor: primarySurfaceColor,
      canvasColor: colorScheme.surface,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.onSurface.withValues(alpha: 0.12),
      tabBarTheme: TabBarThemeData(indicatorColor: onPrimarySurfaceColor),
      applyElevationOverlayColor: isDark,
      useMaterial3: true,
      dialogTheme: DialogThemeData(backgroundColor: colorScheme.surface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: selectedControlColor,
          foregroundColor: colorScheme.onSecondaryContainer,
          elevation: 0,
          side: useHomeGlass
              ? BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 0.8,
                )
              : BorderSide.none,
          minimumSize: const Size(0, 40),
          fixedSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          backgroundColor:
              WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return selectedControlColor;
            }
            return unselectedControlColor;
          }),
          foregroundColor:
              WidgetStatePropertyAll(colorScheme.onSecondaryContainer),
          side: WidgetStatePropertyAll(
            useHomeGlass
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 0.8,
                  )
                : BorderSide.none,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          visualDensity: VisualDensity.standard,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: const CircleBorder(),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6.0),
        radius: const Radius.circular(3.0),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
          }
          return colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
        }),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        crossAxisMargin: 4.0,
        mainAxisMargin: 4.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ThemeProvider.instance,
      builder: (context, _) {
        final theme = Provider.of<ThemeProvider>(context);
        return MaterialApp.router(
          scaffoldMessengerKey: SCAFFOLD_MESSAGER,
          debugShowCheckedModeBanner: false,
          theme: fromSchemeAndFontFamily(
            fontFamily: theme.fontFamily,
            colorScheme: theme.lightScheme,
          ),
          darkTheme: fromSchemeAndFontFamily(
            fontFamily: theme.fontFamily,
            colorScheme: theme.darkScheme,
          ),
          themeMode: theme.themeMode,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: supportedLocales,
          routerConfig: config,
          builder: (context, child) => _StartupSplash(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  late final GoRouter config = GoRouter(
    navigatorKey: ROUTER_KEY,
    initialLocation:
        welcome ? app_paths.WELCOMING_PAGE : app_paths.UPDATING_DIALOG,
    routes: [
      ShellRoute(
        builder: (context, state, page) => AppShell(page: page),
        routes: [
          /// audios page
          GoRoute(
            path: app_paths.AUDIOS_PAGE,
            pageBuilder: (context, state) {
              if (state.extra != null) {
                return SlideTransitionPage(
                  key: state.pageKey,
                  child: AudiosPage(locateTo: state.extra as Audio),
                );
              }
              return SlideTransitionPage(
                key: state.pageKey,
                child: const AudiosPage(),
              );
            },
            routes: [
              GoRoute(
                path: "detail",
                pageBuilder: (context, state) => SlideTransitionPage(
                  key: state.pageKey,
                  child: AudioDetailPage(audio: state.extra as Audio),
                ),
              ),
            ],
          ),

          /// artists page
          GoRoute(
            path: app_paths.ARTISTS_PAGE,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const ArtistsPage(),
            ),
            routes: [
              GoRoute(
                path: "detail",
                pageBuilder: (context, state) => SlideTransitionPage(
                  key: state.pageKey,
                  child: ArtistDetailPage(artist: state.extra as Artist),
                ),
              ),
            ],
          ),

          /// albums page
          GoRoute(
            path: app_paths.ALBUMS_PAGE,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const AlbumsPage(),
            ),
            routes: [
              GoRoute(
                path: "detail",
                pageBuilder: (context, state) => SlideTransitionPage(
                  key: state.pageKey,
                  child: AlbumDetailPage(album: state.extra as Album),
                ),
              ),
            ],
          ),

          /// folders page
          GoRoute(
            path: app_paths.FOLDERS_PAGE,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const FoldersPage(),
            ),
            routes: [
              /// folder detail page
              GoRoute(
                path: "detail",
                pageBuilder: (context, state) {
                  final folder = state.extra as AudioFolder;
                  return SlideTransitionPage(
                    key: state.pageKey,
                    child: FolderDetailPage(folder: folder),
                  );
                },
              ),
            ],
          ),

          /// playlists page
          GoRoute(
            path: app_paths.PLAYLISTS_PAGE,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const PlaylistsPage(),
            ),
            routes: [
              GoRoute(
                path: "detail",
                pageBuilder: (context, state) {
                  final playlist = state.extra as Playlist;
                  return SlideTransitionPage(
                    key: state.pageKey,
                    child: PlaylistDetailPage(playlist: playlist),
                  );
                },
              ),
            ],
          ),

          /// search page
          GoRoute(
            path: app_paths.SEARCH_PAGE,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const SearchPage(),
            ),
            routes: [
              GoRoute(
                path: "result",
                pageBuilder: (context, state) {
                  final result = state.extra as UnionSearchResult;
                  return SlideTransitionPage(
                    key: state.pageKey,
                    child: SearchResultPage(searchResult: result),
                  );
                },
              ),
            ],
          ),

          /// settings page
          GoRoute(
            path: app_paths.SETTINGS_PAGE,
            pageBuilder: (context, state) => SlideTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
          ),
        ],
      ),

      /// now playing page
      GoRoute(
        path: app_paths.NOW_PLAYING_PAGE,
        pageBuilder: (context, state) => CustomTransitionPage(
          maintainState: true,
          transitionDuration: AppMotion.nowPlayingPage,
          reverseTransitionDuration: AppMotion.nowPlayingPageReverse,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AppMotion.nowPlayingPageTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: const NowPlayingPage(),
        ),
      ),

      /// welcoming page
      GoRoute(
        path: app_paths.WELCOMING_PAGE,
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: const WelcomingPage(),
        ),
      ),

      /// updating dialog
      GoRoute(
        path: app_paths.UPDATING_DIALOG,
        pageBuilder: (context, state) => SlideTransitionPage(
          key: state.pageKey,
          child: const UpdatingPage(),
        ),
      ),
    ],
  );

  final supportedLocales = const [
    Locale.fromSubtags(languageCode: 'zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale.fromSubtags(
        languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
    Locale.fromSubtags(
        languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
    Locale.fromSubtags(
        languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
    Locale("en", "US"),
  ];
}

class _StartupSplash extends StatefulWidget {
  const _StartupSplash({required this.child});

  final Widget child;

  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash> {
  static const _holdDuration = Duration(milliseconds: 850);
  static const _fadeDuration = Duration(milliseconds: 360);

  bool _visible = true;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_holdDuration, () {
      if (!mounted) return;
      setState(() {
        _visible = false;
      });
      Future<void>.delayed(_fadeDuration, () {
        if (!mounted) return;
        setState(() {
          _removed = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: !_visible,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: _fadeDuration,
            curve: AppMotion.enter,
            child: const _StartupSplashView(),
          ),
        ),
      ],
    );
  }
}

class _StartupSplashView extends StatelessWidget {
  const _StartupSplashView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppMotion.page,
          curve: AppMotion.enter,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 10),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("app_icon.ico", width: 54, height: 54),
              const SizedBox(height: 18),
              Text(
                "Border Player",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "软件启动中",
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 118,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor:
                      scheme.secondaryContainer.withValues(alpha: 0.46),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
