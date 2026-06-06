import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinyin/pinyin.dart';

const indexLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#',
];

String getFirstLetter(String text) {
  if (text.isEmpty) return '#';
  final first = text.characters.first;
  if (RegExp(r'[a-zA-Z]').hasMatch(first)) return first.toUpperCase();
  if (ChineseHelper.isChinese(first)) {
    final py = PinyinHelper.getFirstWordPinyin(first);
    if (py.isNotEmpty) return py[0].toUpperCase();
  }
  return '#';
}

Map<String, int> buildLetterIndexMap<T>(
  List<T> sortedList,
  String Function(T item) nameExtractor,
) {
  final map = <String, int>{};
  for (int i = 0; i < sortedList.length; i++) {
    final letter = getFirstLetter(nameExtractor(sortedList[i]));
    map.putIfAbsent(letter, () => i);
  }
  return map;
}

class AlphaIndexBar extends StatefulWidget {
  final Map<String, int> letterIndexMap;
  final void Function(int index) onJumpToIndex;
  final int itemCount;

  const AlphaIndexBar({
    super.key,
    required this.letterIndexMap,
    required this.onJumpToIndex,
    required this.itemCount,
  });

  @override
  State<AlphaIndexBar> createState() => _AlphaIndexBarState();
}

class _AlphaIndexBarState extends State<AlphaIndexBar> {
  String? _activeLetter;
  final GlobalKey _barKey = GlobalKey();

  String? _letterAt(Offset localPos) {
    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final h = box.size.height;
    final i = (localPos.dy / h * indexLetters.length).floor();
    if (i >= 0 && i < indexLetters.length) return indexLetters[i];
    return null;
  }

  void _select(Offset localPos) {
    final letter = _letterAt(localPos);
    if (letter == null || letter == _activeLetter) return;
    HapticFeedback.selectionClick();
    setState(() => _activeLetter = letter);
    final idx = widget.letterIndexMap[letter];
    if (idx != null) widget.onJumpToIndex(idx);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Listener(
      key: _barKey,
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _select(e.localPosition),
      onPointerMove: (e) => _select(e.localPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(indexLetters.length, (i) {
            final letter = indexLetters[i];
            final available = widget.letterIndexMap.containsKey(letter);
            final active = letter == _activeLetter;
            return Expanded(
              child: Center(
                child: Container(
                  width: active ? 26 : 18,
                  height: active ? 26 : 18,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.secondaryContainer
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: active ? 13 : 10,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                      color: active
                          ? scheme.onSecondaryContainer
                          : available
                              ? scheme.onSurface
                              : scheme.onSurface.withOpacity(0.15),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
