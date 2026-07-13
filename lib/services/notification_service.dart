import '../config/platform_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  int _notificationId = 0;

  Future<void> init() async {
    if (_initialized) return;
    if (PlatformHelper.isWeb) {
      _initialized = true;
      return;
    }
    await _initMobile();
    _initialized = true;
  }

  Future<void> _initMobile() async {
    // Mobile-only initialization will be handled by platform-specific code
    // For now, we just skip on web
  }

  Future<void> showReminderAbsen() async {
    if (PlatformHelper.isWeb) return;
    // Mobile notification logic
  }

  Future<void> showReminderAbsenPulang() async {
    if (PlatformHelper.isWeb) return;
    // Mobile notification logic
  }

  Future<void> showNotifikasiGaji({
    required String employeeName,
    required String periode,
    required String gajiBersih,
  }) async {
    if (PlatformHelper.isWeb) return;
    // Mobile notification logic
  }

  Future<void> showNotifikasiIzin(Map<String, dynamic> info) async {
    if (PlatformHelper.isWeb) return;
    // Mobile notification logic
  }

  Future<void> showNotification(
    int id,
    String title,
    String body,
  ) async {
    if (PlatformHelper.isWeb) return;
    // Mobile notification logic
  }

  Future<void> cancelNotification(int id) async {
    if (PlatformHelper.isWeb) return;
    // Mobile notification logic
  }

  Future<void> cancelAllNotifications() async {
    if (PlatformHelper.isWeb) return;
    // Mobile notification logic
  }
}
