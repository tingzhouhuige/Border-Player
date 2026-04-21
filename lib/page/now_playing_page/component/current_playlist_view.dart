import 'package:border_player/play_service/play_service.dart';
import 'package:flutter/material.dart';

class CurrentPlaylistView extends StatefulWidget {
  const CurrentPlaylistView({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  State<CurrentPlaylistView> createState() => _CurrentPlaylistViewState();
}

class _CurrentPlaylistViewState extends State<CurrentPlaylistView> {
  final playbackService = PlayService.instance.playbackService;
  late final ScrollController scrollController;

  void _toNowPlaying() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        playbackService.playlistIndex * 80.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(
      initialScrollOffset: playbackService.playlistIndex * 80.0,
    );
    playbackService.addListener(_toNowPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Text(
                "播放列表",
                style: TextStyle(
                  color: scheme.onSecondaryContainer,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: playbackService.shuffle,
              builder: (context, _) {
                return ListView.builder(
                  controller: scrollController,
                  itemCount: playbackService.playlist.value.length,
                  itemExtent: 80.0,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    return _PlaylistViewItem(index: index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    playbackService.removeListener(_toNowPlaying);
    scrollController.dispose();
    super.dispose();
  }
}

class _PlaylistViewItem extends StatelessWidget {
  const _PlaylistViewItem({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final playbackService = PlayService.instance.playbackService;
    final item = playbackService.playlist.value[index];
    final scheme = Theme.of(context).colorScheme;
    final selected = playbackService.playlistIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(20.0),
      onTap: () {
        playbackService.playIndexOfPlaylist(index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withOpacity(0.36)
                : scheme.surfaceContainerHighest.withOpacity(0.16),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: DefaultTextStyle(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${item.artist} - ${item.album}",
                  style: TextStyle(
                    color: scheme.onSecondaryContainer.withOpacity(0.70),
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
