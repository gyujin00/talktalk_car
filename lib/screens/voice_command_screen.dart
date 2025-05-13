import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/voice_command_service.dart';
import '../services/tts_service.dart';
import '../services/speech_service.dart';
import '../widget/voice_wave_animation_widget.dart';
import 'dart:async';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  final TTSService _ttsService = TTSService();
  final SpeechService _speechService = SpeechService();

  String _state = 'listening'; // 'listening', 'recognized', 'executing'
  String _recognizedText = '';
  bool _isListening = false;
  Timer? _listeningTimer;
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _startListeningTimer();
    _startSTT();
  }

  Future<void> _initTTS() async {
    await _ttsService.speak("음성 명령 화면입니다. 명령을 말씀해주세요.");
  }

  Future<void> _startSTT() async {
    final result = await _speechService.listen();
    if (result.isNotEmpty) {
      _recognizedText = result;
      _cancelListeningTimer();
      _startVoiceCommandFlow();
    } else {
      await _ttsService.speak("명령을 인식하지 못했습니다.");
      if (mounted) Navigator.pop(context);
    }
  }

  void _startVoiceCommandFlow() async {
    setState(() {
      _state = 'recognized';
      _isListening = false;
    });

    await _ttsService.speak("인식 결과는 $_recognizedText 입니다.");
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _state = 'executing';
    });

    await _ttsService.speak("$_recognizedText 명령을 수행 중입니다.");
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
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  void _cancelListeningTimer() {
    _listeningTimer?.cancel();
    _listeningTimer = null;
    setState(() {
      _remainingSeconds = 10;
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    _cancelListeningTimer();
    super.dispose();
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatusBox(),
              SizedBox(height: 24),
              _buildMicButton(),
            ],
          ),
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
            SizedBox(
              width: 150,
              height: 150,
              child: VoiceWaveAnimationWidget(),
            ),
            SizedBox(height: 20),
            Text('음성 인식 중...', style: _statusTextStyle()),
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
      case 'executing':
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('$_recognizedText 명령을 수행 중입니다.', style: _statusTextStyle()),
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
                '음성 명령 취소 🎤',
                style: GoogleFonts.roboto(fontSize: 26),
              ),
              SizedBox(height: 10),
              Text(
                '$_remainingSeconds초 남음',
                style: TextStyle(fontSize: 20, color: Colors.red),
              ),
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




