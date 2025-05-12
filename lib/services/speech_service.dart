// lib/services/speech_service.dart (Completer 완료 보장 강화 버전)
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'dart:async';
import 'tts_service.dart';

class SpeechService {
  final stt.SpeechToText _speech;
  final TTSService _ttsService = TTSService();
  bool _isInitialized = false;
  bool _serviceIsListening = false; // 서비스 내부 리스닝 상태 플래그

  Completer<String>? _speechCompleter; // 현재 listen() 호출에 대한 Completer

  SpeechService() : _speech = stt.SpeechToText() {
    _initialize();
  }

  // 전역 상태 변경 콜백 (initialize에 전달)
  void _onSttStatus(String status) {
    print('STT 전역 상태: $status');
    _serviceIsListening = _speech.isListening; // 플러그인 상태로 업데이트
    // 여기서 Completer를 직접 완료하지 않음 (onResult나 타임아웃 우선)
    if (status == stt.SpeechToText.notListeningStatus || status == stt.SpeechToText.doneStatus) {
      if (_serviceIsListening) _serviceIsListening = false; // 상태 동기화
      // 만약 Completer가 아직 완료되지 않았다면, 타임아웃 메커니즘이 처리하거나
      // onResult가 곧 호출될 수 있으므로 여기서 섣불리 완료하지 않음.
      // (단, 이 상태가 onResult 없이 발생하고 타임아웃도 없다면 문제될 수 있음 -> 타임아웃 필수)
    }
  }

  // 전역 오류 콜백 (initialize에 전달)
  void _onSttError(SpeechRecognitionError errorNotification) {
    print('!!! STT 전역 오류: ${errorNotification.errorMsg}, 영구적: ${errorNotification.permanent}');
    // 오류 발생 시 현재 진행중인 listen()의 Completer를 오류로 완료
    _completeListenSession(error: errorNotification.errorMsg ?? "STT System Error"); // 에러 발생 시 여기서 완료
    if (errorNotification.permanent) {
      _isInitialized = false;
    }
  }

  Future<bool> _initialize() async {
    if (_isInitialized && _speech.isAvailable) return true;
    print("STT 초기화 시도...");
    _isInitialized = await _speech.initialize(
      onError: _onSttError,
      onStatus: _onSttStatus,
    );
    print(_isInitialized ? "STT 초기화 성공" : "STT 초기화 실패");
    return _isInitialized;
  }

  bool get isListening => _serviceIsListening;
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  // Completer 완료 및 상태 정리 (중복 완료 방지)
  void _completeListenSession({String? words, dynamic error}) {
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      if (error != null) {
        print("STT Completer 오류로 완료: $error");
        _speechCompleter!.completeError(error);
      } else {
        print("STT Completer 성공으로 완료: '${words ?? ""}'");
        _speechCompleter!.complete(words ?? "");
      }
    }
    // Completer 완료 여부와 관계 없이 리스닝 상태는 false로 설정
    if (_serviceIsListening) {
      _serviceIsListening = false;
    }
  }

  Future<String> listen({String localeId = "ko_KR", int listenTimeOutInSeconds = 12}) async {
    if (!_isInitialized || !_speech.isAvailable) {
      print("STT 준비 안됨. 초기화 시도...");
      bool success = await _initialize();
      if (!success || !_speech.isAvailable) {
        print("STT 초기화/사용 불가");
        await _ttsService.speak("음성 인식 서비스를 사용할 수 없습니다.");
        return Future.error("STT_UNAVAILABLE");
      }
    }

    if (_serviceIsListening) {
      print("이미 리스닝 중. 이전 세션 취소.");
      // cancelListening은 내부적으로 _completeListenSession(error:...)를 호출하여 이전 Completer를 정리함
      await cancelListening();
    }

    _speechCompleter = Completer<String>();
    _serviceIsListening = true;
    print("STT 리스닝 시작...");

    // 자체 타임아웃 타이머 설정
    final timeoutTimer = Timer(Duration(seconds: listenTimeOutInSeconds), () {
      print("자체 타임아웃 ($listenTimeOutInSeconds초) 발생.");
      if (_speech.isListening) { // 아직도 듣고 있다면
        _speech.stop(); // 플러그인 중지 시도 (이후 onStatus 콜백 기대)
      }
      // 타임아웃 시 여기서 Completer 완료
      _completeListenSession(words: ""); // 타임아웃 시 빈 결과
    });

    try {
      _speech.listen(
        localeId: localeId,
        onResult: (result) {
          print('STT onResult: words="${result.recognizedWords}", final=${result.finalResult}');
          if (result.finalResult) {
            timeoutTimer.cancel(); // 최종 결과 받았으므로 타임아웃 취소
            _completeListenSession(words: result.recognizedWords); // 최종 결과로 완료
          }
        },
        listenFor: Duration(seconds: 10), // 이 시간 동안 활성 리스닝 시도
        pauseFor: Duration(seconds: 3),  // 이 시간 동안 말이 없으면 종료 시도
        onSoundLevelChange: (level) { /* ... */ },
        cancelOnError: true, // 오류 시 자동으로 리스닝 중지 -> _onSttError 호출 기대
      );
    } catch (e, s) {
      print("!!! _speech.listen 호출 중 오류: $e");
      print(s);
      timeoutTimer.cancel(); // 오류 시 타임아웃 취소
      _completeListenSession(error: "_speech.listen_CALL_FAILED: $e"); // 오류로 완료
    }

    // Future가 완료될 때 (성공/오류/타임아웃 등) 타이머 정리 및 상태 확인
    return _speechCompleter!.future.whenComplete(() {
      print("listen() Future 완료됨.");
      if (timeoutTimer.isActive) {
        timeoutTimer.cancel(); // 혹시 아직 활성 상태면 취소
      }
      // _serviceIsListening = false; // _completeListenSession에서 이미 처리됨
    });
  }

  Future<void> stopListening() async {
    print("stopListening 호출됨");
    if (_speech.isListening) {
      _speech.stop(); // stop()은 void 반환
    }
    // 수동 중단 시에도 Completer 완료 보장
    _completeListenSession(words: "");
  }

  Future<void> cancelListening() async {
    print("cancelListening 호출됨");
    if (_speech.isListening) {
      _speech.cancel(); // cancel()은 void 반환
    }
    // 수동 취소 시에도 Completer 완료 보장
    _completeListenSession(error: "사용자에 의해 취소됨");
  }
}