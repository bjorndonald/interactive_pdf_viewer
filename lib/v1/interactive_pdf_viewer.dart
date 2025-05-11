import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:http/http.dart' as http;

class InteractivePdfViewer extends StatefulWidget {
  /// The PDF file to display
  final dynamic pdfSource;

  /// Callback when a sentence is tapped
  final Function(String sentence)? onSentenceTap;

  /// Callback when the PDF is loaded
  final Function(int pages)? onPdfLoaded;

  /// Callback when there's an error loading the PDF
  final Function(dynamic error)? onError;

  /// Initial page to display
  final int initialPage;

  /// Whether to fit the PDF to width
  final bool fitToWidth;

  /// Whether to enable text selection
  final bool enableTextSelection;

  /// Color to highlight the selected text
  final Color selectionColor;

  const InteractivePdfViewer({
    Key? key,
    required this.pdfSource,
    this.onSentenceTap,
    this.onPdfLoaded,
    this.onError,
    this.initialPage = 0,
    this.fitToWidth = true,
    this.enableTextSelection = true,
    this.selectionColor = Colors.blue,
  }) : super(key: key);

  @override
  _InteractivePdfViewerState createState() => _InteractivePdfViewerState();
}

class _InteractivePdfViewerState extends State<InteractivePdfViewer> {
  String? _pdfFilePath;
  PDFDoc? _pdfDoc;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  List<PDFPage>? _pdfPages;
  Map<int, List<TextBlock>> _pageTextBlocks = {};
  Set<TextBlock?> _selectedBlocks = {}; // Track multiple selected blocks
  bool _isMultiSelectMode = false; // Track if we're in multi-select mode

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      if (widget.pdfSource is String) {
        if (widget.pdfSource.startsWith('http')) {
          // Load from URL
          final response = await http.get(Uri.parse(widget.pdfSource));
          final bytes = response.bodyBytes;
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/temp.pdf');
          await file.writeAsBytes(bytes);
          _pdfFilePath = file.path;
        } else if (widget.pdfSource.startsWith('/')) {
          // Load from file system
          _pdfFilePath = widget.pdfSource;
        } else {
          // Load from assets
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/temp.pdf');
          final data = await rootBundle.load(widget.pdfSource);
          final bytes = data.buffer.asUint8List();
          await file.writeAsBytes(bytes);
          _pdfFilePath = file.path;
        }
      } else if (widget.pdfSource is File) {
        _pdfFilePath = widget.pdfSource.path;
      } else if (widget.pdfSource is Uint8List) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp.pdf');
        await file.writeAsBytes(widget.pdfSource);
        _pdfFilePath = file.path;
      } else {
        throw Exception('Unsupported PDF source type');
      }

      // Load PDF document for text extraction
      _pdfDoc = await PDFDoc.fromFile(File(_pdfFilePath!));
      _pdfPages = await _pdfDoc?.pages;
      _totalPages = _pdfPages?.length ?? 0;

      // Extract text blocks for each page
      if (_pdfPages != null) {
        for (int i = 0; i < _pdfPages!.length; i++) {
          final page = _pdfPages![i];
          final pageText = await page.text;
          // Process text into blocks with position information
          _pageTextBlocks[i] = await _extractTextBlocks(page);
        }
      }

      if (widget.onPdfLoaded != null) {
        widget.onPdfLoaded!(_totalPages);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!(e);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<TextBlock>> _extractTextBlocks(PDFPage page) async {
    // This is a simplified implementation
    // In a real implementation, you would use the PDF library's capabilities
    // to extract text with position information

    final text = await page.text;
    final sentences = _splitIntoSentences(text);

    // Create text blocks with approximate positions
    // In a real implementation, you would get actual positions from the PDF
    List<TextBlock> blocks = [];
    double yPosition = 0;

    for (String sentence in sentences) {
      if (sentence.trim().isNotEmpty) {
        blocks.add(
          TextBlock(
            text: sentence,
            rect: Rect.fromLTWH(0, yPosition, 595, 20),
          ),
        );
        yPosition += 20;
      }
    }

    return blocks;
  }

  List<String> _splitIntoSentences(String text) {
    // Split on sentence endings and newlines
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+|\n+'));

    // Filter out empty sentences and trim whitespace
    return sentences
        .where((sentence) => sentence.trim().isNotEmpty)
        .map((sentence) => sentence.trim())
        .toList();
  }

  String _getSentenceAtPosition(int page, Offset position) {
    final blocks = _pageTextBlocks[page];
    if (blocks == null) return '';

    // Scale position based on PDF view dimensions
    final scaledPosition = position;

    // Find the block that contains the position
    for (var block in blocks) {
      if (block.rect.contains(scaledPosition)) {
        setState(() {
          if (_isMultiSelectMode) {
            // Toggle selection in multi-select mode
            if (_selectedBlocks.contains(block)) {
              _selectedBlocks.remove(block);
            } else {
              _selectedBlocks.add(block);
            }
          } else {
            // Single select mode - replace selection
            _selectedBlocks.clear();
            _selectedBlocks.add(block);
          }
        });
        return block.text;
      }
    }

    // If no exact match, find the closest block
    TextBlock? closestBlock;
    double minDistance = double.infinity;

    for (var block in blocks) {
      final center = block.rect.center;
      final distance = (center - scaledPosition).distance;

      if (distance < minDistance) {
        minDistance = distance;
        closestBlock = block;
      }
    }

    if (closestBlock != null && minDistance < 50) {
      // Only select if within reasonable distance
      setState(() {
        if (_isMultiSelectMode) {
          // Toggle selection in multi-select mode
          if (_selectedBlocks.contains(closestBlock)) {
            _selectedBlocks.remove(closestBlock);
          } else {
            _selectedBlocks.add(closestBlock);
          }
        } else {
          // Single select mode - replace selection
          _selectedBlocks.clear();
          _selectedBlocks.add(closestBlock);
        }
      });
      return closestBlock.text;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pdfFilePath == null) {
      return const Center(child: Text('Failed to load PDF'));
    }

    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _isMultiSelectMode = !_isMultiSelectMode; // Toggle multi-select mode
          if (!_isMultiSelectMode) {
            _selectedBlocks
                .clear(); // Clear selections when exiting multi-select mode
          }
        });
      },
      onTapDown: widget.enableTextSelection
          ? (TapDownDetails details) {
              final sentence =
                  _getSentenceAtPosition(_currentPage, details.localPosition);
              if (sentence.isNotEmpty && widget.onSentenceTap != null) {
                // Combine all selected sentences
                final selectedText =
                    _selectedBlocks.map((block) => block?.text ?? '').join(' ');
                widget.onSentenceTap!(selectedText);
              }
            }
          : null,
      onTapUp: widget.enableTextSelection
          ? (TapUpDetails details) {
              final sentence =
                  _getSentenceAtPosition(_currentPage, details.localPosition);
              if (sentence.isNotEmpty && widget.onSentenceTap != null) {
                // Combine all selected sentences
                final selectedText =
                    _selectedBlocks.map((block) => block?.text ?? '').join(' ');
                widget.onSentenceTap!(selectedText);
              }
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          PDFView(
            filePath: _pdfFilePath!,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            defaultPage: _currentPage,
            fitPolicy: widget.fitToWidth ? FitPolicy.WIDTH : FitPolicy.BOTH,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
              });
            },
            onError: (error) {
              if (widget.onError != null) {
                widget.onError!(error);
              }
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page!;
                _selectedBlocks.clear(); // Clear selections on page change
                _isMultiSelectMode = false; // Reset multi-select mode
              });
            },
            onViewCreated: (controller) {
              // PDF view controller can be used for additional control
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isMultiSelectMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Multi-select mode: Double tap to exit',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TextBlock {
  final String text;
  final Rect rect;

  TextBlock({required this.text, required this.rect});
}

class MultiTextHighlightPainter extends CustomPainter {
  final List<TextBlock> blocks;
  final Color color;

  MultiTextHighlightPainter({required this.blocks, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var block in blocks) {
      canvas.drawRect(block.rect, paint);
    }
  }

  @override
  bool shouldRepaint(MultiTextHighlightPainter oldDelegate) {
    return oldDelegate.blocks != blocks || oldDelegate.color != color;
  }
}
