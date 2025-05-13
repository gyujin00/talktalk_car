//lib/models/voice_ui_state.dart
enum VoiceUIState {
  normal,       // 기본 차량 상태 표시
  listening,    // 음성 인식 중
  recognized,   // 인식된 텍스트 출력
  processing    // 명령 실행 중
}