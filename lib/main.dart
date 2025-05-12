import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() => runApp(TalkTalkCarApp());

class TalkTalkCarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '톡톡카',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}