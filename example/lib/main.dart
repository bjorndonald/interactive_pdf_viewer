import 'dart:io';
import 'package:flutter/material.dart';
import 'package:interactive_pdf_viewer/interactive_pdf_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive PDF Viewer Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  dynamic _pdfSource;
  String? _selectedSentence;
  int? _totalPages;
  String? _error;

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _pdfSource = File(result.files.single.path!);
          _selectedSentence = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: $e';
      });
    }
  }

  Future<void> _loadSamplePDF() async {
    setState(() {
      _pdfSource = 'assets/sample.pdf';
      _selectedSentence = null;
      _error = null;
    });
  }

  Future<void> _loadRemotePDF() async {
    setState(() {
      _pdfSource =
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
      _selectedSentence = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive PDF Viewer Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () async {
              const url =
                  'https://github.com/bjorndonald/interactive_pdf_viewer';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_selectedSentence != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selected Sentence:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_selectedSentence!),
                ],
              ),
            ),
          if (_totalPages != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Total Pages: $_totalPages'),
            ),
          Expanded(
            child: _pdfSource == null
                ? const Center(
                    child: Text('Select a PDF to view'),
                  )
                : InteractivePdfViewer(
                    pdfSource: _pdfSource,
                    onSentenceTap: (sentence) {
                      setState(() {
                        _selectedSentence = sentence;
                      });
                    },
                    onPdfLoaded: (pages) {
                      setState(() {
                        _totalPages = pages;
                      });
                    },
                    onError: (error) {
                      setState(() {
                        _error = 'Error loading PDF: $error';
                      });
                    },
                    enableTextSelection: true,
                    selectionColor: Colors.yellow.withOpacity(0.3),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pickPDF,
                icon: const Icon(Icons.file_upload),
                label: const Text('Pick PDF'),
              ),
              ElevatedButton.icon(
                onPressed: _loadSamplePDF,
                icon: const Icon(Icons.description),
                label: const Text('Sample PDF'),
              ),
              ElevatedButton.icon(
                onPressed: _loadRemotePDF,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Remote PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
