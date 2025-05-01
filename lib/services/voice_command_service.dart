// lib/services/voice_command_service.dart
//음성 인식 처리 로직 (Google STT 등)
import 'dart:async';

class VoiceCommandService {
  /// 음성 인식을 시작하고 인식된 명령을 반환 (현재는 모의 구현)
  Future<String> startListening() async {
    await Future.delayed(Duration(seconds: 2)); // 실제 인식 시간 대체
    return "에어컨 켜줘"; // 모의 인식 결과
  }

  /// 명령을 처리하는 중이라는 표시 (예: 안내 멘트용)
  Future<void> processCommand(String command) async {
    await Future.delayed(Duration(seconds: 2)); // 처리 시간 시뮬레이션
  }
}