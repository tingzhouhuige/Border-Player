import 'package:border_player/library/audio_library.dart';
import 'package:border_player/library/favorites.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.audio});
  final Audio? audio;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Favorites.instance,
        builder: (context, _) {
          final selected = audio != null && Favorites.instance.contains(audio!);
          return IconButton(
            tooltip: selected ? '取消喜爱' : '喜爱歌曲',
            isSelected: selected,
            onPressed: audio == null
                ? null
                : () async {
                    try {
                      await Favorites.instance.toggle(audio!);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('收藏保存失败，请检查用户数据目录的读写权限。原收藏数据已保留。')),
                      );
                    }
                  },
            icon: Icon(Symbols.favorite,
                fill: selected ? 1 : 0,
                color: selected ? Theme.of(context).colorScheme.primary : null),
          );
        },
      );
}
