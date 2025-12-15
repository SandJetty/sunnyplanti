import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunnyplanti/screens/main_garden_screen.dart';
import 'package:sunnyplanti/services/notification_service.dart';
import 'package:sunnyplanti/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 세로모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 알림 초기화
  await NotificationService().init();
  await DatabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunny Planti',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F9F5), // 연한 연두색 배경
        useMaterial3: true,
      ),
      home: const MainGardenScreen(), // 홈 화면으로 시작!
    );
  }
}
