// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';

class MockWebSocketService {
  final StreamController<String> _controller = StreamController<String>.broadcast();
  bool _isConnected = false;

  // WebSocket 연결 시뮬레이션
  void connect() {
    _isConnected = true;
    print("Mock WebSocket 연결됨");
    // 주기적으로 데이터를 전송하여 테스트
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      // 가상 데이터 생성
      final mockData = {
        "speed": (20 + timer.tick % 40).toString(),
        "battery": (100 - timer.tick % 30).toString(),
        "mode": "운행 중"
      };
      _controller.add(jsonEncode(mockData));
    });
  }

  // 데이터 스트림 반환
  Stream<String> get stream => _controller.stream;

  // 연결 상태 확인
  bool get isConnected => _isConnected;

  // 연결 해제
  void disconnect() {
    _isConnected = false;
    _controller.close();
    print("Mock WebSocket 연결 해제됨");
  }
}