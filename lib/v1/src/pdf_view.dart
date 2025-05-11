import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:synchronized/synchronized.dart';
import 'controllers/pdf_controller.dart';
import 'controllers/tts_controller.dart';
import 'models/highlight.dart';
import 'utils/text_extractor.dart';

class PDFHighlighterView extends StatefulWidget {
  final PDFController pdfController;
  final TtsController? ttsController;
  final Color highlightColor;
  final bool enableTextSelection;
  final bool enableTts;
  final Function(String)? onTextSelected;

  const PDFHighlighterView({
    Key? key,
    required this.pdfController,
    this.ttsController,
    this.highlightColor = Colors.blue,
    this.enableTextSelection = true,
    this.enableTts = true,
    this.onTextSelected,
  }) : super(key: key);

  @override
  State<PDFHighlighterView> createState() => _PDFHighlighterViewState();
}

class _PDFHighlighterViewState extends State<PDFHighlighterView> {
  String? _documentPath;
  final Lock _lock = Lock();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    final path = await widget.pdfController.getDocumentPath();
    if (path != null) {
      setState(() {
        _documentPath = path;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pdfController.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isInitialized || _documentPath == null) {
      return const Center(child: Text('Unable to load PDF document'));
    }

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: widget.enableTextSelection
                  ? (details) {
                      _handleTap(details.localPosition, constraints.maxWidth,
                          constraints.maxHeight);
                    }
                  : null,
              child: PDFView(
                filePath: _documentPath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                defaultPage: widget.pdfController.currentPage.value,
                fitPolicy: FitPolicy.BOTH,
                preventLinkNavigation: false,
                onViewCreated: (PDFViewController controller) {
                  widget.pdfController.pdfViewController = controller;
                },
                onPageChanged: (int? page, int? total) {
                  if (page != null) {
                    widget.pdfController.setCurrentPage(page);
                  }
                },
              ),
            );
          },
        ),
        ValueListenableBuilder<List<SentenceHighlight>>(
          valueListenable: widget.pdfController.highlights,
          builder: (context, highlights, _) {
            return ValueListenableBuilder<int>(
              valueListenable: widget.pdfController.currentPage,
              builder: (context, currentPage, _) {
                final pageHighlights = highlights
                    .where((h) => h.pageIndex == currentPage)
                    .toList();

                return Stack(
                  children: pageHighlights.expand((sentenceHighlight) {
                    return sentenceHighlight.lineHighlights
                        .map((lineHighlight) {
                      return Positioned(
                        left: lineHighlight.bounds.left,
                        top: lineHighlight.bounds.top,
                        width: lineHighlight.bounds.width,
                        height: lineHighlight.bounds.height,
                        child: Container(
                          decoration: BoxDecoration(
                            color: lineHighlight.color.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }).toList();
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleTap(
      Offset position, double pageWidth, double pageHeight) async {
    await _lock.synchronized(() async {
      final pageIndex = widget.pdfController.currentPage.value;

      try {
        // This would be implemented in the TextExtractor class
        final sentenceInfo = await TextExtractor.extractSentenceAt(
            _documentPath!, position, pageIndex, pageWidth, pageHeight);

        if (sentenceInfo != null) {
          final sentenceText = sentenceInfo.text;
          final lineRects = sentenceInfo.lineRects;

          final lineHighlights = lineRects
              .map((rect) => Highlight(
                    bounds: rect,
                    text: sentenceText,
                    color: widget.highlightColor,
                    pageIndex: pageIndex,
                  ))
              .toList();

          final sentenceHighlight = SentenceHighlight(
            lineHighlights: lineHighlights,
            fullText: sentenceText,
            pageIndex: pageIndex,
          );

          widget.pdfController.addHighlight(sentenceHighlight);

          if (widget.onTextSelected != null) {
            widget.onTextSelected!(sentenceText);
          }

          if (widget.enableTts && widget.ttsController != null) {
            await widget.ttsController!.speak(sentenceText);
          }
        }
      } catch (e) {
        debugPrint('Error handling tap: $e');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
