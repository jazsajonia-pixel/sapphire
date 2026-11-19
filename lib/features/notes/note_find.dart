import 'package:flutter/material.dart';

/// Case-insensitive start offsets of [query] in [text] (non-overlapping).
List<int> findMatches(String text, String query) {
  if (query.isEmpty) return const [];
  var hay = text.toLowerCase();
  var needle = query.toLowerCase();
  // Some characters change length when lower-cased; offsets must stay valid.
  if (hay.length != text.length || needle.length != query.length) {
    hay = text;
    needle = query;
  }
  final out = <int>[];
  var i = hay.indexOf(needle);
  while (i >= 0) {
    out.add(i);
    i = hay.indexOf(needle, i + needle.length);
  }
  return out;
}

/// Colors for find-in-note highlights (shared by the editor and the viewer).
abstract final class FindColors {
  static const Color match = Color(0x665E95FF);
  static const Color current = Color(0xFFF5C451);
  static const Color onCurrent = Color(0xFF1A1300);
}

/// Text controller that paints find-in-note matches in the editor.
class HighlightingTextController extends TextEditingController {
  String _query = '';
  int _current = -1;

  String get query => _query;

  /// Highlights [query]; [current] is the index of the focused match.
  void setFind(String query, int current) {
    if (query == _query && current == _current) return;
    _query = query;
    _current = current;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final matches = findMatches(text, _query);
    if (matches.isEmpty || (withComposing && value.composing.isValid)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final len = _query.length;
    final spans = <TextSpan>[];
    var pos = 0;
    for (var k = 0; k < matches.length; k++) {
      final m = matches[k];
      if (m > pos) spans.add(TextSpan(text: text.substring(pos, m)));
      final isCurrent = k == _current;
      spans.add(
        TextSpan(
          text: text.substring(m, m + len),
          style: TextStyle(
            backgroundColor: isCurrent ? FindColors.current : FindColors.match,
            color: isCurrent ? FindColors.onCurrent : null,
          ),
        ),
      );
      pos = m + len;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return TextSpan(style: style, children: spans);
  }
}

/// The find bar shown in the app bar while searching inside a note.
class FindBar extends StatelessWidget {
  const FindBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.current,
    required this.total,
    required this.onNext,
    required this.onPrevious,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int current;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasQuery = controller.text.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('note-find-field'),
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              onNext();
              focusNode.requestFocus();
            },
            decoration: const InputDecoration(
              hintText: 'Find in note',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
            ),
          ),
        ),
        if (hasQuery)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              total == 0 ? 'No matches' : '${current + 1} of $total',
              key: const Key('note-find-count'),
              style: TextStyle(
                color: total == 0 ? scheme.error : scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        IconButton(
          tooltip: 'Previous match',
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          onPressed: total > 0 ? onPrevious : null,
        ),
        IconButton(
          tooltip: 'Next match',
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: total > 0 ? onNext : null,
        ),
      ],
    );
  }
}
