import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<String>.broadcast();
  bool _isConnected = false;

  final String _url = 'ws://172.31.89.176:8000/ws?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyIiwiZXhwIjoxNzQ3MTM4NzQ2fQ.s3aJ4ZPnbAwUBpQ54ohwipgDEHG4L887D2g14RQt4Bw'; // ✅ 실제 FastAPI WebSocket 주소

  /// WebSocket 연결
  void connect() {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      _isConnected = true;
      print("✅ WebSocket 연결됨: $_url");

      _channel!.stream.listen(
            (message) {
          print("📥 수신된 메시지: $message");
          _controller.add(message);
        },
        onError: (error) {
          print("❌ WebSocket 오류: $error");
          _isConnected = false;
          _controller.addError(error);
        },
        onDone: () {
          print("🛑 WebSocket 연결 종료됨");
          _isConnected = false;
          _controller.close();
        },
      );
    } catch (e) {
      print("🚫 WebSocket 연결 실패: $e");
    }
  }

  /// 메시지 전송
  void send(String message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
      print("📤 전송한 명령: $message");
    } else {
      print("⚠️ WebSocket 연결 안 됨: 메시지를 전송할 수 없음");
    }
  }

  /// 연결 종료
  void disconnect() {
    if (_isConnected && _channel != null) {
      _channel!.sink.close(status.goingAway);
      _controller.close();
      _isConnected = false;
      print("🔌 WebSocket 연결 해제됨");
    }
  }

  /// 서버에서 수신되는 메시지를 스트림으로 반환
  Stream<String> get stream => _controller.stream;

  /// 연결 상태
  bool get isConnected => _isConnected;
}
