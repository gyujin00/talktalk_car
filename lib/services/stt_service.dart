import 'package:speech_to_text/speech_to_text.dart';

typedef STTCallback = void Function(String recognizedText);

class STTService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  /// STT 초기화
  Future<bool> initSTT() async {
    _isInitialized = await _speech.initialize(
      onStatus: (status) => print('STT 상태: $status'),
      onError: (error) => print('STT 오류: $error'),
    );
    return _isInitialized;
  }

  /// 음성 인식 시작
  Future<void> startListening(STTCallback onResult) async {
    if (!_isInitialized) {
      await initSTT();
    }

    if (_isInitialized && !_speech.isListening) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: 'ko_KR',
        listenMode: ListenMode.confirmation,
      );
    }
  }

  /// 음성 인식 중지
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// STT 사용 가능 여부
  bool get isAvailable => _isInitialized;

  /// 현재 STT 활성 여부
  bool get isListening => _speech.isListening;
}
