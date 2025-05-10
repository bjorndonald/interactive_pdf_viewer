import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/highlight.dart';

class PDFController {
  final String? filePath;
  final String? url;
  final ValueNotifier<int> currentPage = ValueNotifier<int>(0);
  final ValueNotifier<List<SentenceHighlight>> highlights =
      ValueNotifier<List<SentenceHighlight>>([]);
  final ValueNotifier<SentenceHighlight?> currentHighlight =
      ValueNotifier<SentenceHighlight?>(null);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  PDFViewController? pdfViewController;

  PDFController({this.filePath, this.url});

  Future<String?> getDocumentPath() async {
    if (filePath != null) {
      return filePath;
    } else if (url != null) {
      try {
        isLoading.value = true;
        final response = await http.get(Uri.parse(url!));
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/document.pdf');
        await file.writeAsBytes(bytes);
        isLoading.value = false;
        return file.path;
      } catch (e) {
        isLoading.value = false;
        debugPrint('Error loading PDF from URL: $e');
        return null;
      }
    }
    return null;
  }

  void setCurrentPage(int page) {
    currentPage.value = page;
  }

  void addHighlight(SentenceHighlight highlight) {
    final currentHighlights = List<SentenceHighlight>.from(highlights.value);

    // Remove any existing highlights for the same sentence on the same page
    currentHighlights.removeWhere((h) =>
        h.fullText == highlight.fullText && h.pageIndex == highlight.pageIndex);

    currentHighlights.add(highlight);
    highlights.value = currentHighlights;
    currentHighlight.value = highlight;
  }

  void clearHighlights() {
    highlights.value = [];
    currentHighlight.value = null;
  }

  void jumpToPage(int page) {
    pdfViewController?.setPage(page);
  }

  void dispose() {
    currentPage.dispose();
    highlights.dispose();
    currentHighlight.dispose();
    isLoading.dispose();
  }
}
