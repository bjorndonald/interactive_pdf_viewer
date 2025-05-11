import 'dart:ui';

class Highlight {
  final Rect bounds;
  final String text;
  final Color color;
  final int pageIndex;

  Highlight({
    required this.bounds,
    required this.text,
    required this.color,
    required this.pageIndex,
  });

  Highlight copyWith({
    Rect? bounds,
    String? text,
    Color? color,
    int? pageIndex,
  }) {
    return Highlight(
      bounds: bounds ?? this.bounds,
      text: text ?? this.text,
      color: color ?? this.color,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}

class SentenceHighlight {
  final List<Highlight> lineHighlights;
  final String fullText;
  final int pageIndex;

  SentenceHighlight({
    required this.lineHighlights,
    required this.fullText,
    required this.pageIndex,
  });
}
