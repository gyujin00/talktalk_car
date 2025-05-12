// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/websocket_service.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../services/voice_command_service.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MockWebSocketService _webSocketService = MockWebSocketService();
  final TTSService _ttsService = TTSService();
  final SpeechService _speechService = SpeechService();
  final VoiceCommandService _commandService = VoiceCommandService();

  String _status = '연결 안됨';
  String _speed = '0 km/h';
  String _battery = '100%';
  String _mode = '대기 중';
  bool _isListening = false;
  int _currentSpeed = 0;
  bool _engineOn = false;

  @override
  void initState() {
    super.initState();
    _connectToMockWebSocket();
    _initTTS();
    _startStatusUpdater();
  }

  Future<void> _initTTS() async {
    await _ttsService.speak("톡톡카에 오신 것을 환영합니다. 버튼을 눌러 음성 명령을 시작하세요.");
  }

  void _startStatusUpdater() {
    Timer.periodic(Duration(seconds: 3), (timer) async {
      final status = await _commandService.getStatus();
      if (status != null && mounted) {
        setState(() {
          _battery = '${status['voltage']}V';
          _speed = '${status['speed']} km/h';
          _mode = status['engine_on'] ? '켜짐' : '꺼짐';
        });
      }
    });
  }

  Future<void> _handleVoiceCommand() async {
    if (_isListening) return;
    setState(() => _isListening = true);

    await _ttsService.speak("명령을 말씀해주세요.");
    final command = await _speechService.listen();

    if (command.isNotEmpty) {
      await _ttsService.speak("명령을 인식했습니다: $command");
      await _commandService.processCommand(command);

      if (command.contains("시동 켜")) {
        setState(() {
          _engineOn = true;
          _mode = "켜짐";
        });
      } else if (command.contains("시동 꺼")) {
        setState(() {
          _engineOn = false;
          _mode = "꺼짐";
          _currentSpeed = 0;
          _speed = '0 km/h';
        });
      } else if (command.contains("주행 시작")) {
        setState(() {
          _currentSpeed = 40;
          _speed = '40 km/h';
        });
      } else if (command.contains("천천히")) {
        setState(() {
          _currentSpeed = (_currentSpeed - 10).clamp(0, 120);
          _speed = '$_currentSpeed km/h';
        });
      } else if (command.contains("빨리")) {
        setState(() {
          _currentSpeed = (_currentSpeed + 10).clamp(0, 120);
          _speed = '$_currentSpeed km/h';
        });
      } else if (command.contains("연료") || command.contains("전압")) {
        await _commandService.sendCommand("C");
        await Future.delayed(Duration(milliseconds: 800));
        final status = await _commandService.getStatus();
        if (status != null) {
          setState(() {
            _battery = '${status['voltage']}V';
          });
          await _ttsService.speak("현재 연료 전압은 ${status['voltage']} 볼트입니다.");
        }
      } else if (command.contains("탈거야")) {
        await _commandService.sendCommand("B");
        await _ttsService.speak("앞문을 열었습니다. 위치를 알리는 소리가 울립니다.");
      } else if (command.contains("탔어")) {
        await _commandService.sendCommand("b");
        await _ttsService.speak("탑승이 확인되었습니다. 문을 닫습니다.");
      } else if (command.contains("도와줘")) {
        await _ttsService.speak("긴급 상황이 감지되었습니다. 구조 요청을 시작합니다.");
      } else if (command.contains("경로 알려")) {
        await _ttsService.speak("현재 목적지까지 5킬로미터 남았습니다. 약 10분 소요됩니다.");
      }

      await _ttsService.speak("명령을 처리했습니다.");
    } else {
      await _ttsService.speak("명령을 인식하지 못했습니다.");
    }

    setState(() => _isListening = false);
  }

  void _connectToMockWebSocket() {
    _webSocketService.connect();
    _webSocketService.stream.listen((message) {
      try {
        Map<String, dynamic> data = jsonDecode(message);
        setState(() {
          _status = '연결됨';
        });
      } catch (_) {
        setState(() {
          _status = '데이터 수신 오류';
          _speed = '- km/h';
          _battery = '- %';
          _mode = '-';
        });
      }
    }, onError: (_) {
      setState(() {
        _status = '연결 실패';
      });
    });
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
              onTap: _handleVoiceCommand,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isListening
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.red),
                      SizedBox(height: 12),
                      Text("명령 인식 중...", style: GoogleFonts.roboto(fontSize: 22)),
                    ],
                  )
                      : Text(
                    '🎤 음성 명령 실행하기',
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