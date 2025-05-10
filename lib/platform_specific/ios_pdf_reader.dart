import 'package:flutter/services.dart';

class IosPdfReader {
  static const MethodChannel _channel = MethodChannel('com.example.pdf_reader/ios');

  // Method to highlight text in PDF using native iOS PDFKit
  static Future<bool> highlightText({
    required String pdfPath,
    required int pageIndex,
    required String text,
    required double x,
    required double y,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('highlightText', {
        'pdfPath': pdfPath,
        'pageIndex': pageIndex,
        'text': text,
        'x': x,
        'y': y,
      });
      return result;
    } on PlatformException catch (e) {
      print('Failed to highlight text: ${e.message}');
      return false;
    }
  }

  // Method to use AVSpeechUtterance directly
  static Future<bool> speakWithAVSpeech({
    required String text,
    double rate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
    String language = "en-US",
  }) async {
    try {
      final bool result = await _channel.invokeMethod('speakWithAVSpeech', {
        'text': text,
        'rate': rate,
        'pitch': pitch,
        'volume': volume,
        'language': language,
      });
      return result;
    } on PlatformException catch (e) {
      print('Failed to speak with AVSpeech: ${e.message}');
      return false;
    }
  }
}
