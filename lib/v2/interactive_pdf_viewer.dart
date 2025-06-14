// lib/flutter_ios_pdfkit.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Represents a quote in the PDF
class PDFQuote {
  /// The text content of the quote
  final String text;

  /// The page number where the quote appears (1-based)
  final int pageNumber;

  /// Optional location information for the quote
  final Map<String, dynamic>? location;

  PDFQuote({
    required this.text,
    required this.pageNumber,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'pageNumber': pageNumber,
      if (location != null) 'location': location,
    };
  }
}

class InteractivePdfViewer {
  final Function(String, int, Map<String, dynamic>)? onQuote;
  final Function()? onClearAllQuotes;
  final Function(String text, int pageNumber)? onQuoteRemoved;
  final Function()? onInfoButton;
  final Function()? onShareButton;
  final Function(int pageNumber, int totalPages)? onPageChanged;
  final bool shouldHighlightQuotes;
  final String highlightColor;

  /// Method channel for communication with native code
  static const MethodChannel _channel = MethodChannel('interactive_pdf_viewer');

  /// Creates a new instance of [InteractivePdfViewer]
  ///
  /// [onQuote] Optional callback for when text is quoted
  /// [onClearAllQuotes] Optional callback for when all quotes are cleared
  /// [onQuoteRemoved] Optional callback for when a specific quote is removed
  /// [onInfoButton] Optional callback for when info button is pressed
  /// [onShareButton] Optional callback for when share button is pressed
  /// [onPageChanged] Optional callback for when the page changes, provides current page number and total pages
  /// [shouldHighlightQuotes] Optional boolean to determine if quoted text should be highlighted (defaults to true)
  /// [highlightColor] Optional color for the highlight in hex format (defaults to '#FFEB3B')
  InteractivePdfViewer({
    this.onQuote,
    this.onClearAllQuotes,
    this.onQuoteRemoved,
    this.onInfoButton,
    this.onShareButton,
    this.onPageChanged,
    this.shouldHighlightQuotes = true,
    this.highlightColor = '#FFEB3B',
  }) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'quote':
        onQuote?.call(call.arguments['text'], call.arguments['pageNumber'], {
          "x": call.arguments['location']["x"],
          "y": call.arguments['location']["y"],
        });
        break;
      case 'clearAllQuotes':
        onClearAllQuotes?.call();
        break;
      case 'quoteRemoved':
        onQuoteRemoved?.call(
          call.arguments['text'],
          call.arguments['pageNumber'],
        );
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
  /// [filePath] The path to the PDF file to open
  /// [title] The title to display in the viewer
  /// [initialPage] Optional parameter to specify which page to open first (defaults to 1)
  /// [existingQuotes] Optional list of quotes to highlight when opening the PDF
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws a [PlatformException] if there was an error.
  static Future<bool> openPDF(
    String filePath,
    String title, {
    int initialPage = 1,
    List<PDFQuote> existingQuotes = const [],
  }) async {
    final Map<String, dynamic> params = {
      'filePath': filePath,
      'title': title,
      'initialPage': initialPage,
      'existingQuotes': existingQuotes.map((q) => q.toMap()).toList(),
    };

    return await _channel.invokeMethod('openPDF', params);
  }

  /// Opens a PDF file from a given file path with highlighting options
  ///
  /// [filePath] The path to the PDF file to open
  /// [title] The title to display in the viewer
  /// [initialPage] Optional parameter to specify which page to open first (defaults to 1)
  /// [existingQuotes] Optional list of quotes to highlight when opening the PDF
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws a [PlatformException] if there was an error.
  Future<bool> openPDFWithOptions(
    String filePath,
    String title, {
    int initialPage = 1,
    List<PDFQuote> existingQuotes = const [],
  }) async {
    final Map<String, dynamic> params = {
      'filePath': filePath,
      'title': title,
      'shouldHighlightQuotes': shouldHighlightQuotes,
      'highlightColor': highlightColor,
      'initialPage': initialPage,
      'existingQuotes': existingQuotes.map((q) => q.toMap()).toList(),
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
  /// [initialPage] Optional parameter to specify which page to open first (defaults to 1)
  /// [existingQuotes] Optional list of quotes to highlight when opening the PDF
  /// [headers] Optional HTTP headers to use when downloading the PDF
  /// [progressCallback] Optional callback to track download progress
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws an exception if there was an error.
  Future<bool> openPDFFromUrl(
    String url,
    String title, {
    int initialPage = 1,
    List<PDFQuote> existingQuotes = const [],
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
        return await openPDFWithOptions(
          filePath,
          title,
          initialPage: initialPage,
          existingQuotes: existingQuotes,
        );
      }

      // Download the PDF file
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return await openPDFWithOptions(
          filePath,
          title,
          initialPage: initialPage,
          existingQuotes: existingQuotes,
        );
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
  /// [initialPage] Optional parameter to specify which page to open first (defaults to 1)
  /// [existingQuotes] Optional list of quotes to highlight when opening the PDF
  ///
  /// Returns a [Future] that completes with `true` if the PDF was opened successfully
  /// or throws an exception if there was an error.
  Future<bool> openPDFAsset(
    String assetPath,
    String title, {
    int initialPage = 1,
    List<PDFQuote> existingQuotes = const [],
  }) async {
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

      return await openPDFWithOptions(
        filePath,
        title,
        initialPage: initialPage,
        existingQuotes: existingQuotes,
      );
    } catch (e) {
      throw Exception('Error opening PDF asset: $e');
    }
  }

  /// Returns whether the current platform is iOS
  ///
  /// This is useful to check before calling iOS-specific methods, as this plugin
  /// only provides PDF viewing functionality on iOS.
  static bool get isIOS => Platform.isIOS;

  /// Removes a specific quote from the PDF
  ///
  /// [text] The exact text of the quote to remove
  /// [pageNumber] The page number where the quote is located (1-based)
  ///
  /// Returns a [Future] that completes with `true` if the quote was successfully removed
  /// or throws a [PlatformException] if:
  /// - The PDF viewer is not open
  /// - The page number is invalid
  /// - The quote could not be found
  /// - There was an error removing the quote
  Future<bool> removeQuote(String text, int pageNumber) async {
    try {
      final Map<String, dynamic> params = {
        'text': text,
        'pageNumber': pageNumber,
      };

      return await _channel.invokeMethod('removeQuote', params);
    } on PlatformException catch (e) {
      print('Error removing quote: ${e.message}');
      rethrow;
    }
  }
}
