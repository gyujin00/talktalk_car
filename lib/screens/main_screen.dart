import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/websocket_service.dart';
import '../services/tts_service.dart';
import 'voice_command_screen.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MockWebSocketService _webSocketService = MockWebSocketService();
  final TTSService _ttsService = TTSService();
  String _status = '연결 안됨';
  String _speed = '0 km/h';
  String _battery = '100%';
  String _mode = '정상';
  @override
  void initState() {
    super.initState();
    _connectToMockWebSocket();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _ttsService.speak("안녕하세요. 톡톡카입니다.");
  }

  void _connectToMockWebSocket() {
    _webSocketService.connect();
    _webSocketService.stream.listen((message) {
      try {
        Map<String, dynamic> data = jsonDecode(message);
        setState(() {
          _status = '연결됨';
          _speed = '${data['speed']} km/h';
          _battery = '${data['battery']}%';
          _mode = '${data['mode']}';
          _speakStatus();
        });
      } catch (_) {
        setState(() {
          _status = '데이터 수신 오류';
          _speed = '- km/h';
          _battery = '- %';
          _mode = '-';
          _speakError();
        });
      }
    }, onError: (_) {
      setState(() {
        _status = '연결 실패';
        _speakDisconnected();
      });
    });
  }

  void _speakStatus() {
    _ttsService.speak(
        "현재 상태는 $_status, 속도는 $_speed, 배터리는 $_battery, 주행 모드는 $_mode 입니다.");
  }

  void _speakError() {
    _ttsService.speak("데이터 수신에 오류가 발생했습니다.");
  }

  void _speakDisconnected() {
    _ttsService.speak("서버와 연결에 실패했습니다.");
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('톡톡카 - 실시간 차량 모니터링'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(_status, style: _statusStyle()),
                  SizedBox(height: 16),
                  Icon(Icons.speed, color: Colors.white, size: 36),
                  Text('속도: $_speed', style: _infoStyle()),
                  SizedBox(height: 16),
                  Icon(Icons.battery_full, color: Colors.white, size: 36),
                  Text('배터리: $_battery', style: _infoStyle()),
                  SizedBox(height: 16),
                  Icon(Icons.directions_car, color: Colors.white, size: 36),
                  Text('주행 모드: $_mode', style: _infoStyle()),
                ],
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VoiceCommandScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '음성 명령 입력... 🎤',
                    style: GoogleFonts.roboto(fontSize: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _statusStyle() => GoogleFonts.roboto(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  TextStyle _infoStyle() => GoogleFonts.roboto(
    color: Colors.white,
    fontSize: 20,
  );
}