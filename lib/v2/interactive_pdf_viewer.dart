// lib/flutter_ios_pdfkit.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class InteractivePdfViewer {
  List<String> selectedSentences = [];
  Timer? _sentenceTimer;

  /// Method channel for communication with native code
  static const MethodChannel _channel = MethodChannel('interactive_pdf_viewer');

  /// Opens a PDF file from a given file path
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws a [PlatformException] if there was an error.
  static Future<bool> openPDF(String filePath) async {
    final Map<String, dynamic> params = {
      'filePath': filePath,
    };

    return await _channel.invokeMethod('openPDF', params);
  }

  /// Stops the sentence fetching timer
  void dispose() {
    _sentenceTimer?.cancel();
    _sentenceTimer = null;
  }

  static Future<List<String>> getSentences() async {
    final result = await _channel.invokeMethod('getSentences');
    if (result is List) {
      return result.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }

  /// Downloads a PDF from a URL and opens it using PDFKit on iOS
  ///
  /// [url] The URL of the PDF to download and open
  /// [headers] Optional HTTP headers to use when downloading the PDF
  /// [progressCallback] Optional callback to track download progress
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws an exception if there was an error.
  static Future<bool> openPDFFromUrl(
    String url, {
    Map<String, String>? headers,
    Function(double progress)? progressCallback,
  }) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();

      // Create a unique filename from the URL
      final filename = url.split('/').last;
      final filePath = '${directory.path}/$filename';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        return await openPDF(filePath);
      }

      // Download the PDF file
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return await openPDF(filePath);
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error opening PDF from URL: $e');
    }
  }

  /// Opens a PDF asset bundled with the application
  ///
  /// [assetPath] The path to the asset in the Flutter assets bundle
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws an exception if there was an error.
  static Future<bool> openPDFAsset(String assetPath) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();

      // Create a unique filename from the asset path
      final filename = assetPath.split('/').last;
      final filePath = '${directory.path}/$filename';

      // Create file
      final file = File(filePath);

      // Copy asset to temporary directory
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes);

      return await openPDF(filePath);
    } catch (e) {
      throw Exception('Error opening PDF asset: $e');
    }
  }

  /// Returns whether the current platform is iOS
  ///
  /// This is useful to check before calling iOS-specific methods, as this plugin
  /// only provides PDF viewing functionality on iOS.
  static bool get isIOS => Platform.isIOS;
}
