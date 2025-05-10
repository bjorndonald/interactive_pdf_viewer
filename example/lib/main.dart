import 'dart:io';
import 'package:flutter/material.dart';
import 'package:interactive_pdf_viewer/interactive_pdf_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:interactive_pdf_viewer/pdf_highlighter.dart';
import 'package:interactive_pdf_viewer/pdf_reader.dart';
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
      home: const PDFHighlighterDemo(),
    );
  }
}

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   dynamic _pdfSource;
//   String? _selectedSentence;
//   int? _totalPages;
//   String? _error;

//   Future<void> _pickPDF() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//       );

//       if (result != null) {
//         setState(() {
//           _pdfSource = File(result.files.single.path!);
//           _selectedSentence = null;
//           _error = null;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Error picking file: $e';
//       });
//     }
//   }

//   Future<void> _loadSamplePDF() async {
//     setState(() {
//       _pdfSource = 'assets/sample.pdf';
//       _selectedSentence = null;
//       _error = null;
//     });
//   }

//   Future<void> _loadRemotePDF() async {
//     setState(() {
//       _pdfSource =
//           'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
//       _selectedSentence = null;
//       _error = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Interactive PDF Viewer Example'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info),
//             onPressed: () async {
//               const url =
//                   'https://github.com/bjorndonald/interactive_pdf_viewer';
//               if (await canLaunchUrl(Uri.parse(url))) {
//                 await launchUrl(Uri.parse(url));
//               }
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (_error != null)
//             Container(
//               padding: const EdgeInsets.all(16),
//               color: Colors.red.shade100,
//               child: Text(_error!, style: const TextStyle(color: Colors.red)),
//             ),
//           if (_selectedSentence != null)
//             Container(
//               padding: const EdgeInsets.all(16),
//               color: Colors.blue.shade100,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('Selected Sentence:',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   Text(_selectedSentence!),
//                 ],
//               ),
//             ),
//           if (_totalPages != null)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text('Total Pages: $_totalPages'),
//             ),
//           Expanded(
//             child: _pdfSource == null
//                 ? const Center(
//                     child: Text('Select a PDF to view'),
//                   )
//                 : PDFHighlighterView(
//                     pdfController: pdfController,
//                     ttsController: ttsController,
//                     highlightColor: Colors.blue,
//                     onTextSelected: (text) {
//                       setState(() {
//                         selectedText = text;
//                       });
//                     },
//                   ),
//                 // PDFReaderWithTTS(
//                 //     pdfAssetPath: _pdfSource,
//                 //     onSentenceTap: (sentence) {
//                 //       setState(() {
//                 //         _selectedSentence = sentence;
//                 //       });
//                 //     },
//                 //     onPdfLoaded: (pages) {
//                 //       setState(() {
//                 //         _totalPages = pages;
//                 //       });
//                 //     },
//                 //     // onError: (error) {
//                 //     //   setState(() {
//                 //     //     _error = 'Error loading PDF: $error';
//                 //     //   });
//                 //     // },
//                 //     // enableTextSelection: true,
//                 //     selectionColor: Colors.yellow.withOpacity(0.3),
//                 //   ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomAppBar(
//         height: 200,
//         child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _pickPDF,
//                   icon: const Icon(Icons.file_upload),
//                   label: const Text('Pick PDF'),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: _loadSamplePDF,
//                       icon: const Icon(Icons.description),
//                       label: const Text('Sample PDF'),
//                     ),
//                     const SizedBox(width: 16),
//                     ElevatedButton.icon(
//                       onPressed: _loadRemotePDF,
//                       icon: const Icon(Icons.cloud_download),
//                       label: const Text('Remote PDF'),
//                     ),
//                   ],
//                 ),
//               ],
//             )),
//       ),
//     );
//   }
// }

class PDFHighlighterDemo extends StatefulWidget {
  const PDFHighlighterDemo({Key? key}) : super(key: key);

  @override
  State<PDFHighlighterDemo> createState() => _PDFHighlighterDemoState();
}

class _PDFHighlighterDemoState extends State<PDFHighlighterDemo> {
  late PDFController pdfController;
  late TtsController ttsController;
  String selectedText = '';
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Initialize with a sample PDF URL
    pdfController = PDFController(
      url:
          'https://cdn.penguin.co.uk/dam-assets/books/9781847943750/9781847943750-sample.pdf',
    );

    ttsController = TtsController();
    ttsController.ttsState.addListener(_updatePlayingState);
  }

  void _updatePlayingState() {
    setState(() {
      isPlaying = ttsController.ttsState.value == TtsState.playing ||
          ttsController.ttsState.value == TtsState.continued;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Highlighter Demo'),
        actions: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (isPlaying) {
                ttsController.pause();
              } else {
                if (ttsController.ttsState.value == TtsState.paused) {
                  ttsController.resume();
                } else if (selectedText.isNotEmpty) {
                  ttsController.speak(selectedText);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              ttsController.stop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PDFHighlighterView(
              pdfController: pdfController,
              ttsController: ttsController,
              highlightColor: Colors.blue,
              onTextSelected: (text) {
                setState(() {
                  selectedText = text;
                });
              },
            ),
          ),
          if (selectedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(
                selectedText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
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
