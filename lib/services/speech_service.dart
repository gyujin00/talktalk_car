// lib/services/speech_service.dart

import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<String> listen() async {
    print("🎤 음성 인식 시작 준비...");

    bool available = await _speech.initialize(
      onStatus: (status) => print('🎙 상태: $status'),
      onError: (error) => print('❌ 오류: $error'),
    );

    if (!available) {
      print("❌ 음성 인식 초기화 실패 (SpeechToText)");
      return "";
    }

    String recognizedText = "";

    print("✅ 음성 인식 초기화 성공, 리스닝 시작");

    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
        print('🗣 인식된 텍스트: $recognizedText');
      },
      localeId: 'ko_KR',
      listenMode: ListenMode.confirmation,
      listenFor: Duration(seconds: 10),   // 늘려줌
      pauseFor: Duration(seconds: 3),     // 일시 멈춤 시간
      partialResults: true,             // 부분 결과도 허용
    );

    await Future.delayed(Duration(seconds: 6));
    await _speech.stop();

    return recognizedText;
  }
}