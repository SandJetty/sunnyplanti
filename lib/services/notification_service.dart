import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  // 싱글톤 패턴
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. 초기화
  Future<void> init() async {
    tz.initializeTimeZones();
    await [Permission.notification].request();

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  // 10분 타이머 예약 함수
  Future<void> scheduleQuestCompletion() async {
    await _notificationsPlugin.zonedSchedule(
      0,
      '☀️ 퀘스트 완료!',
      '10분 산책 성공! 앱에 접속해서 보상을 받으세요.',
      // 테스트를 위해 10초 뒤로 설정함 (나중에 minutes: 10으로 변경)
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
