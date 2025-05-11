import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PDFReaderWithTTS extends StatefulWidget {
  final String? pdfAssetPath;
  final String? pdfUrl;
  final Color selectionColor;
  final Function(String sentence)? onSentenceTap;
  final Function(int pages)? onPdfLoaded;

  const PDFReaderWithTTS({
    Key? key,
    this.pdfAssetPath,
    this.pdfUrl,
    this.selectionColor = Colors.blue,
    this.onSentenceTap,
    this.onPdfLoaded,
  }) : super(key: key);

  @override
  State<PDFReaderWithTTS> createState() => _PDFReaderWithTTSState();
}

class _PDFReaderWithTTSState extends State<PDFReaderWithTTS> {
  FlutterTts flutterTts = FlutterTts();
  PDFViewController? pdfViewController;
  String? localPdfPath;
  bool isPdfReady = false;
  bool isSpeaking = false;
  bool isPaused = true;
  int currentPage = 0;
  int? totalPages;
  List<String> pageTexts = [];
  List<String> lineTexts = [];
  int currentLineIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeTts();
    loadPdf();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> initializeTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
        isPaused = false;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
        isPaused = true;
        // Move to next line when current one completes
        if (currentLineIndex < lineTexts.length - 1) {
          currentLineIndex++;
          speakCurrentLine();
        }
      });
    });

    flutterTts.setProgressHandler(
        (String text, int startOffset, int endOffset, String word) {
      print("Progress: $text, $startOffset, $endOffset, $word");
    });
  }

  Future<void> loadPdf() async {
    try {
      if (widget.pdfAssetPath != null) {
        // Load from assets
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/sample.pdf');

        final data = await rootBundle.load(widget.pdfAssetPath!);
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes);

        setState(() {
          localPdfPath = file.path;
          isPdfReady = true;
        });
      } else if (widget.pdfUrl != null) {
        // TODO: Implement loading from URL
        // This would require using a package like http to download the file
      } else {
        // Use a sample PDF for demo purposes
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/sample.pdf');

        // For demo, we'd need to include a sample PDF in assets
        final data = await rootBundle.load('assets/sample.pdf');
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes);

        setState(() {
          localPdfPath = file.path;
          isPdfReady = true;
        });
      }
    } catch (e) {
      print('Error loading PDF: $e');
    }
  }

  Future<void> extractTextFromCurrentPage() async {
    // In a real implementation, you would use a PDF text extraction plugin
    // For this example, we'll simulate with placeholder text
    lineTexts = [
      "This is the first line of text on page $currentPage.",
      "This is the second line of text on page $currentPage.",
      "This is the third line of text on page $currentPage.",
      "This is the fourth line of text on page $currentPage.",
    ];
    currentLineIndex = 0;
  }

  Future<void> speakCurrentLine() async {
    if (currentLineIndex < lineTexts.length) {
      await flutterTts.speak(lineTexts[currentLineIndex]);
    }
  }

  void toggleSpeech() async {
    if (isSpeaking) {
      if (isPaused) {
        await flutterTts.speak(lineTexts[currentLineIndex]);
        setState(() {
          isPaused = false;
        });
      } else {
        await flutterTts.pause();
        setState(() {
          isPaused = true;
        });
      }
    } else {
      await extractTextFromCurrentPage();
      speakCurrentLine();
    }
  }

  void stopSpeech() async {
    await flutterTts.stop();
    setState(() {
      isSpeaking = false;
      isPaused = true;
    });
  }

  void nextLine() async {
    if (currentLineIndex < lineTexts.length - 1) {
      stopSpeech();
      setState(() {
        currentLineIndex++;
      });
      speakCurrentLine();
    }
  }

  void previousLine() async {
    if (currentLineIndex > 0) {
      stopSpeech();
      setState(() {
        currentLineIndex--;
      });
      speakCurrentLine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Reader with TTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isPdfReady
                ? GestureDetector(
                    onTap: () {
                      toggleSpeech();
                    },
                    child: PDFView(
                      filePath: localPdfPath,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: false,
                      pageFling: false,
                      pageSnap: true,
                      defaultPage: currentPage,
                      fitPolicy: FitPolicy.BOTH,
                      preventLinkNavigation: false,
                      onRender: (_pages) {
                        setState(() {
                          totalPages = _pages;
                        });
                      },
                      onError: (error) {
                        print(error.toString());
                      },
                      onPageError: (page, error) {
                        print('$page: ${error.toString()}');
                      },
                      onViewCreated: (PDFViewController pdfViewCtrl) {
                        setState(() {
                          pdfViewController = pdfViewCtrl;
                        });
                      },
                      onPageChanged: (int? page, int? total) {
                        if (page != null) {
                          setState(() {
                            currentPage = page;
                          });
                          stopSpeech();
                          extractTextFromCurrentPage();
                        }
                      },
                    ))
                : const Center(child: CircularProgressIndicator()),
          ),
          // Highlighted text indicator
          if (lineTexts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.yellow.withOpacity(0.3),
              child: Text(
                lineTexts[currentLineIndex],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          // Control bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: previousLine,
                ),
                IconButton(
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: toggleSpeech,
                  iconSize: 36,
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: nextLine,
                ),
                PopupMenuButton<double>(
                  icon: const Icon(Icons.speed),
                  tooltip: 'Speech Rate',
                  onSelected: (double rate) async {
                    await flutterTts.setSpeechRate(rate);
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<double>>[
                    const PopupMenuItem<double>(
                      value: 0.25,
                      child: Text('0.25x'),
                    ),
                    const PopupMenuItem<double>(
                      value: 0.5,
                      child: Text('0.5x'),
                    ),
                    const PopupMenuItem<double>(
                      value: 0.75,
                      child: Text('0.75x'),
                    ),
                    const PopupMenuItem<double>(
                      value: 1.0,
                      child: Text('1.0x'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
