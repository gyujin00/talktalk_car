// lib/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  FlutterTts flutterTts = FlutterTts();

  TTSService() {
    _init();
  }

  Future<void> _init() async {
    await flutterTts.setLanguage("ko-KR"); // 한국어 설정
    await flutterTts.setPitch(1.0); // 음성 높낮이 설정
    await flutterTts.setSpeechRate(0.5); // 음성 속도 설정
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }
}