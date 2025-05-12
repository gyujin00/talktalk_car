// lib/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  FlutterTts flutterTts = FlutterTts();

  TTSService() {
    _init();
  }

  Future<void> _init() async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.awaitSpeakCompletion(true);

    // 웹 환경에서 음성 설정 명시적으로 지정
    try {
      List<dynamic> voices = await flutterTts.getVoices;
      if (voices.isNotEmpty) {
        var koreanVoice = voices.firstWhere(
              (v) => v['locale'] == "ko-KR",
          orElse: () => voices.first,
        );
        await flutterTts.setVoice({
          "name": koreanVoice['name'],
          "locale": koreanVoice['locale']
        });
        print("🔊 음성 설정 완료: ${koreanVoice['name']}");
      }
    } catch (e) {
      print("⚠️ TTS 음성 설정 실패: \$e");
    }
  }

  Future<void> speak(String text) async {
    try {
      print("🔊 말하기: \$text");
      await flutterTts.speak(text);
    } catch (e) {
      print("❌ TTS 오류: \$e");
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }
}