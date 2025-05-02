import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/voice_command_service.dart';
import '../services/tts_service.dart';
import '../widget/voice_wave_animation_widget.dart';
import 'dart:async';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  final TTSService _ttsService = TTSService();
  String _state = 'listening';
  String _recognizedText = '';
  bool _isListening = false;
  Timer? _listeningTimer;
  int _remainingSeconds = 10;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTTS();
    _startListeningTimer();
  }

  Future<void> _initTTS() async {
    await _ttsService.speak("음성 명령 화면입니다. 명령을 말씀해주세요.");
  }

  @override
  void dispose() {
    _ttsService.stop();
    _cancelListeningTimer();
    _textController.dispose();
    super.dispose();
  }

  void _cancelListeningTimer() {
    _listeningTimer?.cancel();
    _listeningTimer = null;
    setState(() {
      _remainingSeconds = 10;
    });
  }

  void _startVoiceCommandFlow() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      await _ttsService.speak("명령어를 입력해주세요.");
      return;
    }

    setState(() {
      _state = 'processing';
      _isListening = true;
      _remainingSeconds = 10;
    });

    _cancelListeningTimer();
    await _ttsService.speak("명령을 처리합니다.");

    _recognizedText = text;

    setState(() {
      _state = 'recognized';
      _isListening = false;
    });

    await _ttsService.speak("인식 결과는 $_recognizedText 입니다.");
    await Future.delayed(Duration(seconds: 2));
    await _voiceService.processCommand(_recognizedText);
    await _ttsService.speak("명령을 처리했습니다.");

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _startListeningTimer() {
    _isListening = true;
    _listeningTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (mounted && _textController.text.trim().isEmpty) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('음성 명령 처리 중'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: _buildStatusBox()),
            SizedBox(height: 24),
            _buildMicButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox() {
    Widget content;
    switch (_state) {
      case 'listening':
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VoiceWaveAnimationWidget(),
            SizedBox(height: 20),
            Text('명령어를 입력하세요...', style: _statusTextStyle()),
            SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(hintText: '엔터를 눌러 전송'),
              onSubmitted: (text) {
                _cancelListeningTimer();
                _startVoiceCommandFlow();
              },
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.white),
          ],
        );
        break;
      case 'recognized':
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hearing, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              '인식 결과: $_recognizedText',
              textAlign: TextAlign.center,
              style: _statusTextStyle(),
            ),
          ],
        );
        break;
      case 'processing':
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('$_recognizedText 중입니다...', style: _statusTextStyle()),
          ],
        );
        break;
      default:
        content = SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: () {
        if (_isListening) {
          _cancelListeningTimer();
          Navigator.pop(context);
        } else {
          _startVoiceCommandFlow();
        }
      },
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isListening ? '음성 명령 취소 🎤' : '음성 명령 입력... 🎤',
                style: GoogleFonts.roboto(fontSize: 26),
              ),
              if (_isListening) ...[
                SizedBox(height: 10),
                Text(
                  '$_remainingSeconds초 남음',
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _statusTextStyle() => GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}