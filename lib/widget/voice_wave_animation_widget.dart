// lib/widget/voice_wave_animation_widget.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math.dart' show Vector2; // vector_math 패키지 추가

class VoiceWaveAnimationWidget extends StatefulWidget {
  @override
  _VoiceWaveAnimationWidgetState createState() => _VoiceWaveAnimationWidgetState();
}

class _VoiceWaveAnimationWidgetState extends State<VoiceWaveAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000), // 애니메이션 속도 조절
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VoiceWavePainter(animation: _controller),
      size: Size(200, 200), // 위젯 크기 조절
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  final Animation<double> animation;

  _VoiceWavePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // 1. 배경 그라데이션
    final backgroundPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Color(0xFFE0E0E0), // 밝은 회색
          Color(0xFF90CAF9), // 밝은 파랑
          Color(0xFFF48FB1), // 밝은 분홍
          Color(0xFFE0E0E0),
        ],
        stops: [0.0, 0.25, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, backgroundPaint);

    // 2. 원 일그러뜨리기
    final points = <Vector2>[];
    final noiseStrength = 10 + 10 * sin(animation.value * 2 * pi); // 노이즈 강도 변화
    for (int i = 0; i < 12; i++) { // 꼭짓점 개수 증가
      final angle = 2 * pi / 12 * i;
      final offset = Vector2(
        cos(angle) * (radius + noiseStrength * cos(angle * 5 + animation.value * 2 * pi)),
        sin(angle) * (radius + noiseStrength * sin(angle * 5 + animation.value * 2 * pi)),
      );
      points.add(offset + Vector2(center.dx, center.dy));
    }

    // 곡선으로 연결
    final path = Path();
    path.moveTo(points[0].x, points[0].y);
    for (int i = 0; i < points.length; i++) {
      final nextIndex = (i + 1) % points.length;
      path.quadraticBezierTo(
        (points[i].x + points[nextIndex].x) / 2,
        (points[i].y + points[nextIndex].y) / 2,
        points[nextIndex].x,
        points[nextIndex].y,
      );
    }
    path.close();

    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5) // 외곽선 색상 및 투명도
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, outlinePaint);

    // 3. 내부 색상 변화 (선택 사항)
    // 필요에 따라 추가 구현
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}