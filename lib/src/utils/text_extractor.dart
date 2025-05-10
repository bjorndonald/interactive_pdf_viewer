import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:path_provider/path_provider.dart';

class SentenceInfo {
  final String text;
  final List<Rect> lineRects;

  SentenceInfo({required this.text, required this.lineRects});
}

class TextExtractor {
  static Future<SentenceInfo?> extractSentenceAt(
      String pdfPath,
      Offset tapPosition,
      int pageIndex,
      double pageWidth,
      double pageHeight) async {
    try {
      // Load the PDF document
      final file = File(pdfPath);
      final document = await PDFDoc.fromFile(file);

      // Get the page
      if (pageIndex >= document.length) {
        return null;
      }

      final page =
          await document.pageAt(pageIndex + 1); // PDF pages are 1-indexed

      // Extract text from the page
      final text = await page.text;

      if (text.isEmpty) {
        return null;
      }

      // This is a simplified approach. In a real implementation, you would need
      // to use a PDF library that provides text position information.
      // For now, we'll simulate finding the sentence at the tap position.

      // Split text into sentences
      final sentences = _splitIntoSentences(text);

      if (sentences.isEmpty) {
        return null;
      }

      // For demonstration, we'll select a sentence based on the vertical position
      // This is an approximation and would need to be replaced with actual text position data

      final relativeY = tapPosition.dy / pageHeight;
      final sentenceIndex =
          (relativeY * sentences.length).floor().clamp(0, sentences.length - 1);

      final selectedSentence = sentences[sentenceIndex];

      // Create simulated line rects for the sentence
      // In a real implementation, these would be calculated based on actual text layout
      final pageWidth = 568;
      final lineHeight = 20.0; // Approximate line height
      final linesCount = (selectedSentence.length / 50)
          .ceil(); // Approximate characters per line

      final lineRects = List.generate(linesCount, (index) {
        final lineY = tapPosition.dy -
            (linesCount / 2 * lineHeight) +
            (index * lineHeight);
        final lineWidth = pageWidth * 0.8; // 80% of page width

        return Rect.fromLTWH(
          pageWidth * 0.1, // 10% margin from left
          lineY.clamp(0, pageHeight - lineHeight),
          lineWidth,
          lineHeight,
        );
      });

      return SentenceInfo(
        text: selectedSentence,
        lineRects: lineRects,
      );
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return null;
    }
  }

  static List<String> _splitIntoSentences(String text) {
    // Simple sentence splitting by punctuation
    final sentenceList = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return sentenceList;
  }
}
