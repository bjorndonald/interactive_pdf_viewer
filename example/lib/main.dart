import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:interactive_pdf_viewer/v2/interactive_pdf_viewer.dart';

void main() {
  // Ensure Flutter bindings are initialized for platform channels
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Idle';
  bool _isLoading = false;
  Timer? _sentenceTimer;
  int _initialPage = 5;
  late final InteractivePdfViewer _interactivePdfViewer;
  List<PDFQuote> _existingQuotes = [];

  void _onSelectedSentencesChanged(String sentence) {
    setState(() {
      print('Selected sentence: $sentence');
    });
  }

  void _onQuote(String sentence, int pageNumber, dynamic location) {
    print('Quote: $sentence, Page: $pageNumber, Location: $location');
    setState(() {
      _existingQuotes.add(PDFQuote(text: sentence, pageNumber: pageNumber));
    });
  }

  void _onClearAllQuotes() {
    print('Clearing all quotes');
    setState(() {
      _existingQuotes = [];
    });
  }

  void _onInfoButton() {
    print('Info button pressed');
  }

  void _onShareButton() {
    print('Share button pressed');
  }

  void _onPageChanged(int pageNumber, int totalPages) {
    print('Page changed: $pageNumber/$totalPages');
    setState(() {
      _initialPage = pageNumber;
    });
  }

  @override
  void initState() {
    super.initState();
    _interactivePdfViewer = InteractivePdfViewer(
      onQuote: _onQuote,
      onClearAllQuotes: _onClearAllQuotes,
      onInfoButton: _onInfoButton,
      onShareButton: _onShareButton,
      onPageChanged: _onPageChanged,
      shouldHighlightQuotes: true,
      highlightColor: '#FFEB3B',
    );
  }

  @override
  void dispose() {
    _sentenceTimer?.cancel();
    _sentenceTimer = null;
    super.dispose();
  }

  Future<void> closePDF() async {
    try {
      final success = await InteractivePdfViewer.closePDF();
      print('PDF closed: $success');
    } catch (e) {
      print('Error closing PDF: $e');
    }
  }

  // List of sample PDFs to demonstrate
  final List<Map<String, String>> pdfSamples = [
    {
      'name': 'W3C Sample PDF',
      'url':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
    {
      'name': 'Sample PDF Document',
      'url': 'https://www.africau.edu/images/default/sample.pdf',
    },
    {
      'name': 'PDF Specification',
      'url':
          'https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf',
    },
  ];

  // Open PDF from a URL
  Future<void> _openPDFFromUrl(String url, String title) async {
    if (!InteractivePdfViewer.isIOS) {
      setState(() {
        _status = 'This feature is only available on iOS devices';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Downloading and opening PDF...';
    });

    try {
      await _interactivePdfViewer.openPDFFromUrl(url, title,
          initialPage: _initialPage, existingQuotes: _existingQuotes);
      setState(() {
        _status = 'PDF opened successfully';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter iOS PDFKit Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                )
              else
                const Icon(
                  Icons.picture_as_pdf,
                  size: 100,
                  color: Colors.blue,
                ),
              const SizedBox(height: 20),
              Text(
                'Status: $_status',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => print('Open PDF'),
                child: const Text('Open PDF'),
              ),
              const SizedBox(height: 40),
              const Text(
                'Sample PDFs:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: pdfSamples.length,
                  itemBuilder: (context, index) {
                    final pdf = pdfSamples[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(pdf['name']!),
                        subtitle: Text(
                          pdf['url']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _openPDFFromUrl(pdf['url']!, pdf['name']!),
                      ),
                    );
                  },
                ),
              ),
              if (!InteractivePdfViewer.isIOS)
                Container(
                  color: Colors.amber.shade100,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(16),
                  child: const Text(
                    'Note: This plugin only works on iOS 11.0+',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
