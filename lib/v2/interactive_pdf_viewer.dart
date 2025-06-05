// lib/flutter_ios_pdfkit.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class InteractivePdfViewer {
  final Function(String, int, Map<String, dynamic>)? onQuote;
  final Function(int)? onMarkChapterAsDone;
  final Function()? onInfoButton;
  final Function()? onShareButton;
  final Function(int pageNumber, int totalPages)? onPageChanged;

  /// Method channel for communication with native code
  static const MethodChannel _channel = MethodChannel('interactive_pdf_viewer');

  /// Creates a new instance of [InteractivePdfViewer]
  ///
  /// [onSelectedChanged] Optional callback for when selected sentences change
  /// [onSaveSelected] Optional callback for when a Flutter action is triggered
  /// [onPageChanged] Optional callback for when the page changes, provides current page number and total pages
  InteractivePdfViewer({
    this.onQuote,
    this.onMarkChapterAsDone,
    this.onInfoButton,
    this.onShareButton,
    this.onPageChanged,
  }) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'quote':
        onQuote?.call(
          call.arguments['text'],
          call.arguments['pageNumber'],
          call.arguments['location'],
        );
        break;
      case 'markChapterAsDone':
        onMarkChapterAsDone?.call(call.arguments['pageNumber']);
        break;
      case 'infoButton':
        onInfoButton?.call();
        break;
      case 'shareButton':
        onShareButton?.call();
        break;
      case 'onPageChanged':
        onPageChanged?.call(
          call.arguments['pageNumber'],
          call.arguments['totalPages'],
        );
        break;
      default:
        throw MissingPluginException('No such method "${call.method}"');
    }
  }

  /// Opens a PDF file from a given file path
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws a [PlatformException] if there was an error.
  static Future<bool> openPDF(String filePath, String title) async {
    final Map<String, dynamic> params = {
      'filePath': filePath,
      'title': title,
    };

    return await _channel.invokeMethod('openPDF', params);
  }

  /// Closes the currently open PDF viewer
  ///
  /// Returns a [Future] that completes with `true` if the viewer was closed successfully,
  /// or throws a [PlatformException] if there was an error or no viewer was open.
  static Future<bool> closePDF() async {
    try {
      return await _channel.invokeMethod('closePDF');
    } on PlatformException catch (e) {
      print('Error closing PDF viewer: ${e.message}');
      return false;
    }
  }

  /// Stops the sentence fetching timer
  void dispose() {
    _channel.setMethodCallHandler(null);
  }

  /// Downloads a PDF from a URL and opens it using PDFKit on iOS
  ///
  /// [url] The URL of the PDF to download and open
  /// [title] The title to display in the viewer
  /// [headers] Optional HTTP headers to use when downloading the PDF
  /// [progressCallback] Optional callback to track download progress
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws an exception if there was an error.
  static Future<bool> openPDFFromUrl(
    String url,
    String title, {
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
        return await openPDF(filePath, title);
      }

      // Download the PDF file
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return await openPDF(filePath, title);
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
  /// [title] The title to display in the viewer
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws an exception if there was an error.
  static Future<bool> openPDFAsset(String assetPath, String title) async {
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

      return await openPDF(filePath, title);
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
