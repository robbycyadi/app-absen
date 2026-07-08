import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _notificationId = 0;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    tz_data.initializeTimeZones();
    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {}

  Future<void> showReminderAbsen() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
      45,
    );

    if (now.isAfter(scheduleDate)) {
      return;
    }

    await scheduleNotification(
      _notificationId++,
      'App-Absen',
      'Jangan lupa absen masuk hari ini!',
      scheduleDate,
    );
  }

  Future<void> showReminderAbsenPulang() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      16,
      0,
    );

    if (now.isAfter(scheduleDate)) {
      return;
    }

    await scheduleNotification(
      _notificationId++,
      'App-Absen',
      'Jangan lupa absen pulang!',
      scheduleDate,
    );
  }

  Future<void> showNotifikasiGaji({
    required String employeeName,
    required String periode,
    required String gajiBersih,
  }) async {
    await showNotification(
      _notificationId++,
      'Slip Gaji Tersedia',
      'Gaji $employeeName periode $periode: Rp $gajiBersih',
    );
  }

  Future<void> showNotifikasiIzin(Map<String, dynamic> info) async {
    final status = info['status'] as String? ?? 'approved';
    final title = status == 'approved'
        ? 'Izin Disetujui'
        : status == 'rejected'
            ? 'Izin Ditolak'
            : 'Pengajuan Izin';

    final body = info['message'] as String? ??
        'Status pengajuan izin: ${status.toUpperCase()}';

    await showNotification(_notificationId++, title, body);
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
  ) async {
    try {
      final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      final location = tz.getLocation(timeZoneName);
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, location);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'app_absen_channel',
            'App-Absen Notifications',
            channelDescription: 'Notifications for App-Absen attendance app',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      throw Exception('Failed to schedule notification: $e');
    }
  }

  Future<void> showNotification(
    int id,
    String title,
    String body,
  ) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'app_absen_channel',
            'App-Absen Notifications',
            channelDescription: 'Notifications for App-Absen attendance app',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      throw Exception('Failed to show notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
