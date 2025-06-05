# Interactive PDF Viewer

A Flutter plugin that provides interactive PDF viewing capabilities for iOS devices using PDFKit. This plugin allows you to view PDFs, extract text content, and interact with the document through various gestures.

## Features

- Open PDF files from multiple sources:
  - Local storage
  - URLs (with download progress tracking)
  - Flutter assets
- Interactive text selection:
  - Tap to select sentences
  - Double-tap to clear selections
  - Visual highlighting of selected text
  - Save selected sentences
- Page tracking and navigation:
  - Real-time page change events
  - Current page tracking
  - Total pages information
  - Smooth page transitions
- Viewer Control:
  - Programmatic opening and closing
  - Manual close button
  - Error handling and state management
- Text extraction and processing:
  - Extract text content from PDFs
  - Real-time sentence selection
  - Support for sentence-level text selection
  - Automatic sentence tracking
- User Interface:
  - Native PDFKit viewer with full-screen support
  - Custom close button (top left)
  - Save button for selected sentences (top right)
  - Page navigation controls
- iOS 13.0+ support using PDFKit and SF Symbols

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  interactive_pdf_viewer: ^0.2.0  # Use the latest version
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

### Creating a PDF Viewer Instance

Create an instance of `InteractivePdfViewer` with optional callbacks:

```dart
final pdfViewer = InteractivePdfViewer(
  // Called when a sentence is selected
  onSelectedSentencesChanged: (sentence) {
    print('Selected sentence: $sentence');
  },
  // Called when save button is pressed
  onSaveSelectedSentences: () {
    print('Save selected sentences triggered');
    // Handle saving the selected sentences
  },
  // Called when page changes
  onPageChanged: (pageNumber, totalPages) {
    print('Current page: $pageNumber of $totalPages');
    // Handle page change
  },
);
```

### Opening PDFs

#### From Local File
```dart
final success = await pdfViewer.openPDF('/path/to/your/file.pdf', 'Document Title');
```

#### From URL
```dart
await pdfViewer.openPDFFromUrl(
  'https://example.com/sample.pdf',
  'Document Title',
  progressCallback: (progress) {
    print('Download progress: $progress');
  },
);
```

#### From Assets
```dart
await pdfViewer.openPDFAsset('assets/sample.pdf', 'Document Title');
```

### Closing the PDF Viewer

You can close the PDF viewer programmatically using the static `closePDF()` method:

```dart
// Close the PDF viewer programmatically
final success = await InteractivePdfViewer.closePDF();
if (success) {
  print('PDF viewer closed successfully');
} else {
  print('Failed to close PDF viewer');
}
```

This is useful in scenarios such as:
- Navigating away from the current screen
- Implementing a custom close button
- Handling app lifecycle events
- Implementing a timeout feature

### Text Selection and Interaction

The plugin provides several ways to interact with the PDF:

1. **Single Tap**: Select a sentence at the tapped location
2. **Double Tap**: Clear all selections
3. **Save Button**: Trigger saving of selected sentences
4. **Close Button**: Dismiss the PDF viewer
5. **Swipe**: Navigate between pages

To handle selected sentences, page changes, and save actions:

```dart
final pdfViewer = InteractivePdfViewer(
  onSelectedSentencesChanged: (sentence) {
    // Handle selected sentence updates
    print('Selected sentence: $sentence');
  },
  onSaveSelectedSentences: () {
    // Handle saving the selected sentences
    print('Save triggered for current sentence');
  },
  onPageChanged: (pageNumber, totalPages) {
    // Handle page changes
    print('Current page: $pageNumber of $totalPages');
  },
);
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
  String? _selectedSentence;
  int _currentPage = 1;
  int _totalPages = 0;
  late InteractivePdfViewer _pdfViewer;

  @override
  void initState() {
    super.initState();
    _pdfViewer = InteractivePdfViewer(
      onSelectedSentencesChanged: (sentence) {
        setState(() {
          _selectedSentence = sentence;
        });
      },
      onSaveSelectedSentences: () {
        _saveSelectedSentence();
      },
      onPageChanged: (pageNumber, totalPages) {
        setState(() {
          _currentPage = pageNumber;
          _totalPages = totalPages;
        });
      },
    );
  }

  void _saveSelectedSentence() {
    if (_selectedSentence != null) {
      // Implement your save logic here
      print('Saving sentence: $_selectedSentence');
      // For example, save to a file or database
    }
  }

  Future<void> _closePDFViewer() async {
    final success = await InteractivePdfViewer.closePDF();
    if (success) {
      setState(() {
        _status = 'PDF viewer closed';
      });
    } else {
      setState(() {
        _status = 'Failed to close PDF viewer';
      });
    }
  }

  @override
  void dispose() {
    _pdfViewer.dispose();
    super.dispose();
  }

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
      await _pdfViewer.openPDFFromUrl(
        url,
        'Sample Document',
        progressCallback: (progress) {
          setState(() => _status = 'Download progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );
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
      appBar: AppBar(
        title: Text('PDF Viewer'),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
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
                  if (_totalPages > 0)
                    ElevatedButton(
                      onPressed: _closePDFViewer,
                      child: Text('Close PDF'),
                    ),
                ],
              ),
            ),
          ),
          if (_selectedSentence != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Selected Sentence:',
                          style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: Icon(Icons.save),
                        onPressed: _saveSelectedSentence,
                        tooltip: 'Save selected sentence',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(_selectedSentence!),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

## Requirements

- iOS 13.0 or later
- Flutter 2.0.0 or later
- Dart SDK 2.17.0 or later

## Known Limitations

- Currently only supports iOS devices
- Requires iOS 13.0 or later due to PDFKit and SF Symbols dependency
- Text highlighting covers entire lines rather than individual text
- Text position information is approximated
- Native text selection features are not available

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.