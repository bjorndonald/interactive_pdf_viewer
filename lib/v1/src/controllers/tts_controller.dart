import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/highlight.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsController {
  final FlutterTts flutterTts = FlutterTts();
  final ValueNotifier<TtsState> ttsState =
      ValueNotifier<TtsState>(TtsState.stopped);
  final ValueNotifier<String> currentText = ValueNotifier<String>('');
  final ValueNotifier<int> currentSentenceIndex = ValueNotifier<int>(0);

  List<String> sentences = [];
  Function(String)? onSentenceComplete;
  Function(int)? onSentenceIndexChanged;
  Function()? onComplete;

  TtsController() {
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      if (currentSentenceIndex.value < sentences.length - 1) {
        currentSentenceIndex.value++;
        if (onSentenceIndexChanged != null) {
          onSentenceIndexChanged!(currentSentenceIndex.value);
        }
        _speakCurrentSentence();
      } else {
        stop();
        if (onComplete != null) {
          onComplete!();
        }
      }
    });
  }

  void setSentences(List<String> sentenceList) {
    sentences = sentenceList;
    currentSentenceIndex.value = 0;
  }

  Future<void> speak(String text) async {
    // Split text into sentences
    sentences = _splitIntoSentences(text);
    currentSentenceIndex.value = 0;

    if (sentences.isNotEmpty) {
      await _speakCurrentSentence();
    }
  }

  Future<void> speakSentence(String sentence, {int index = 0}) async {
    currentSentenceIndex.value = index;
    currentText.value = sentence;
    await flutterTts.speak(sentence);
    ttsState.value = TtsState.playing;
  }

  Future<void> _speakCurrentSentence() async {
    if (currentSentenceIndex.value < sentences.length) {
      final sentence = sentences[currentSentenceIndex.value];
      currentText.value = sentence;
      await flutterTts.speak(sentence);
      ttsState.value = TtsState.playing;
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
    ttsState.value = TtsState.stopped;
  }

  Future<void> pause() async {
    await flutterTts.pause();
    ttsState.value = TtsState.paused;
  }

  Future<void> resume() async {
    if (ttsState.value == TtsState.paused) {
      await flutterTts.speak(currentText.value); // Resume with current text
      ttsState.value = TtsState.continued;
    }
  }

  List<String> _splitIntoSentences(String text) {
    // Simple sentence splitting by punctuation
    final sentenceList = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return sentenceList;
  }

  void dispose() {
    flutterTts.stop();
    ttsState.dispose();
    currentText.dispose();
    currentSentenceIndex.dispose();
  }
}
