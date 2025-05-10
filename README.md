# PDF Highlighter

A Flutter package for highlighting text in PDFs with text-to-speech functionality.

## Features

- Display PDF documents from file or URL
- Tap to select and highlight sentences
- Text-to-speech functionality to read selected text
- Automatic navigation through sentences and pages
- Customizable highlight colors

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

\`\`\`yaml
dependencies:
  pdf_highlighter: ^0.1.0
\`\`\`

### Usage

```dart
import 'package:flutter/material.dart';
import 'package:pdf_highlighter/pdf_highlighter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PDFHighlighterDemo(),
    );
  }
}

class PDFHighlighterDemo extends StatefulWidget {
  @override
  _PDFHighlighterDemoState createState() => _PDFHighlighterDemoState();
}

class _PDFHighlighterDemoState extends State<PDFHighlighterDemo> {
  late PDFController pdfController;
  late TtsController ttsController;
  
  @override
  void initState() {
    super.initState();
    pdfController = PDFController(
      url: 'https://example.com/sample.pdf',
      // Or use a local file:
      // filePath: '/path/to/your/file.pdf',
    );
    
    ttsController = TtsController();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Highlighter')),
      body: PDFHighlighterView(
        pdfController: pdfController,
        ttsController: ttsController,
        highlightColor: Colors.blue,
        onTextSelected: (text) {
          print('Selected text: $text');
        },
      ),
    );
  }
  
  @override
  void dispose() {
    pdfController.dispose();
    ttsController.dispose();
    super.dispose();
  }
}
