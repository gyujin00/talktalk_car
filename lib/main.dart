
//lib/main.dart
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





/*
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://172.31.89.176:8000/ws'), // IP는 Python 서버가 켜진 컴퓨터의 IP로 바꿔줘
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '차량 제어 테스트',
      home: Scaffold(
        appBar: AppBar(title: Text('차량 제어')),
        body: Column(
          children: [
            StreamBuilder(
              stream: channel.stream,
              builder: (context, snapshot) {
                return Text(snapshot.hasData ? '${snapshot.data}' : '대기 중...');
              },
            ),
            TextField(
              onSubmitted: (text) {
                channel.sink.add(text); // 예: "engine_on"
              },
              decoration: InputDecoration(labelText: '명령어 입력'),
            ),
          ],
        ),
      ),
    );
  }
}

*/

