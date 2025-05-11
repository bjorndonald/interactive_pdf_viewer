# Interactive PDF Viewer

A Flutter plugin that provides interactive PDF viewing capabilities for iOS devices using PDFKit. This plugin allows you to view PDFs and extract text content from them.

## Features

- Open PDF files from local storage
- Download and open PDFs from URLs
- Open PDFs from Flutter assets
- Extract text content from PDFs
- iOS 11.0+ support using PDFKit

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  interactive_pdf_viewer: ^0.1.1  # Use the latest version
```

Then run:
```bash
flutter pub get
```

## Usage

### Basic Setup

First, ensure Flutter bindings are initialized:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
```

### Opening PDFs

#### From Local File
```dart
final success = await InteractivePdfViewer.openPDF('/path/to/your/file.pdf');
```

#### From URL
```dart
await InteractivePdfViewer.openPDFFromUrl(
  'https://example.com/sample.pdf',
  progressCallback: (progress) {
    print('Download progress: $progress');
  },
);
```

#### From Assets
```dart
await InteractivePdfViewer.openPDFAsset('assets/sample.pdf');
```

### Extracting Text Content

To extract text content from the currently open PDF:

```dart
// Get sentences periodically
Timer.periodic(const Duration(seconds: 1), (timer) async {
  try {
    final sentences = await InteractivePdfViewer.getSentences();
    print('Extracted sentences: ${sentences.join(' ')}');
  } catch (e) {
    print('Error fetching sentences: $e');
  }
});
```

### Platform Support

The plugin currently only supports iOS devices. You can check platform support using:

```dart
if (InteractivePdfViewer.isIOS) {
  // iOS-specific code
} else {
  // Handle unsupported platform
}
```

## Example

Here's a complete example of how to use the plugin:

```dart
import 'package:flutter/material.dart';
import 'package:interactive_pdf_viewer/v2/interactive_pdf_viewer.dart';

class PDFViewerScreen extends StatefulWidget {
  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String _status = 'Idle';
  bool _isLoading = false;

  Future<void> _openPDFFromUrl(String url) async {
    if (!InteractivePdfViewer.isIOS) {
      setState(() => _status = 'This feature is only available on iOS devices');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Downloading and opening PDF...';
    });

    try {
      await InteractivePdfViewer.openPDFFromUrl(url);
      setState(() => _status = 'PDF opened successfully');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              CircularProgressIndicator()
            else
              Icon(Icons.picture_as_pdf, size: 100),
            Text('Status: $_status'),
            ElevatedButton(
              onPressed: () => _openPDFFromUrl('https://example.com/sample.pdf'),
              child: Text('Open Sample PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Requirements

- iOS 11.0 or later
- Flutter 2.0.0 or later

## Limitations

- Currently only supports iOS devices
- Requires iOS 11.0 or later due to PDFKit dependency
- Text extraction is limited to the currently visible content

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.