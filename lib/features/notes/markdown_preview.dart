import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'note_find.dart';

/// Rendered Markdown. Remote images are never fetched (privacy: opening a
/// note must not contact third-party servers); a placeholder is shown.
///
/// With [find] set, matches in the rendered text are highlighted, the
/// [currentMatch]-th one strongly, and scrolled into view;
/// [onMatchCount] reports how many matches were rendered. Text inside fenced
/// code blocks is not searched in this view.
class MarkdownPreview extends StatefulWidget {
  const MarkdownPreview({
    super.key,
    required this.text,
    this.onTapLink,
    this.shrinkWrap = false,
    this.find = '',
    this.currentMatch = 0,
    this.onMatchCount,
    this.scrollController,
  });

  final bool shrinkWrap;
  final String text;
  final void Function(String text, String? href)? onTapLink;
  final String find;
  final int currentMatch;
  final ValueChanged<int>? onMatchCount;
  final ScrollController? scrollController;

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<MarkdownPreview> {
  final _counter = _MatchCounter();
  final _currentKey = GlobalKey();
  int _reported = -1;
  String? _parseKey;
  String? _parsedText;

  @override
  Widget build(BuildContext context) {
    final find = widget.find;
    // MarkdownBody only re-parses when its key or data changes, so the
    // count from the last parse stays valid across plain rebuilds.
    final parseKey = '${find.toLowerCase()}#${widget.currentMatch}';
    if (parseKey != _parseKey || widget.text != _parsedText) {
      _parseKey = parseKey;
      _parsedText = widget.text;
      _counter.n = 0;
      _counter.doc = null;
    }
    _counter.current = widget.currentMatch;
    _counter.key = _currentKey;
    final body = MarkdownBody(
      // Re-parse when the search changes (MarkdownBody only re-parses on
      // new data).
      key: ValueKey(parseKey),
      data: widget.text,
      onTapLink: (t, href, _) => widget.onTapLink?.call(t, href),
      inlineSyntaxes: [
        if (find.isNotEmpty) ...[
          _FindSyntax(find, _counter),
          _wordStepSyntax(find),
        ],
      ],
      builders: {if (find.isNotEmpty) 'findmatch': _FindBuilder(_counter)},
      imageBuilder: (uri, title, alt) => Chip(
        avatar: const Icon(Icons.image_not_supported_outlined, size: 18),
        label: Text(alt?.isNotEmpty == true ? alt! : 'Image not shown'),
      ),
    );
    if (find.isNotEmpty || _reported != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _afterFrame());
    }
    // SelectionArea instead of `selectable: true`: tappable links are more
    // reliable with plain rich text inside a selection area.
    if (widget.shrinkWrap) {
      return SelectionArea(
        child: Padding(padding: const EdgeInsets.all(12), child: body),
      );
    }
    return SelectionArea(
      child: SingleChildScrollView(
        key: const Key('note-view'),
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: body,
      ),
    );
  }

  void _afterFrame() {
    if (!mounted) return;
    final count = widget.find.isEmpty ? 0 : _counter.n;
    if (count != _reported) {
      _reported = count;
      widget.onMatchCount?.call(count);
    }
    final ctx = _currentKey.currentContext;
    if (widget.find.isNotEmpty && ctx != null && !widget.shrinkWrap) {
      final reduce = MediaQuery.disableAnimationsOf(context);
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _MatchCounter {
  int n = 0;

  /// The document of the parse that produced [n]; a new parse restarts it.
  Object? doc;
  int current = 0;
  GlobalKey? key;
}

/// Lets the parser step through a word one character at a time when a match
/// starts inside it; the default text syntax would skip whole words.
md.InlineSyntax _wordStepSyntax(String query) => md.TextSyntax(
  '[A-Za-z0-9](?=[A-Za-z0-9]*?${RegExp.escape(query)})',
  caseSensitive: false,
);

class _FindSyntax extends md.InlineSyntax {
  _FindSyntax(String query, this.counter)
    : super(RegExp.escape(query), caseSensitive: false);

  final _MatchCounter counter;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    if (!identical(parser.document, counter.doc)) {
      counter.doc = parser.document;
      counter.n = 0;
    }
    final el = md.Element.text('findmatch', match[0]!);
    el.attributes['i'] = '${counter.n++}';
    parser.addNode(el);
    return true;
  }
}

class _FindBuilder extends MarkdownElementBuilder {
  _FindBuilder(this.counter);
  final _MatchCounter counter;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final i = int.tryParse(element.attributes['i'] ?? '') ?? -1;
    final isCurrent = i == counter.current;
    final style = (parentStyle ?? const TextStyle()).copyWith(
      backgroundColor: isCurrent ? FindColors.current : FindColors.match,
      color: isCurrent ? FindColors.onCurrent : null,
    );
    return Text.rich(
      TextSpan(
        children: [
          if (isCurrent)
            WidgetSpan(child: SizedBox(key: counter.key, width: 0, height: 0)),
          TextSpan(text: element.textContent, style: style),
        ],
      ),
    );
  }
}
