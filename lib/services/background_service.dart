import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Periodic heartbeat for background hardware & location monitoring
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'PanicButton Protection Active',
          content: 'Monitoring ESP32 & Anti-Snatch in background',
        );
      }
    }
    service.invoke('heartbeat', {'time': DateTime.now().toIso8601String()});
  });
}

class BackgroundMonitorService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open PanicButton',
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      linux: linuxInit,
    );
    await _notifications.initialize(settings: initSettings);

    if (!Platform.isAndroid && !Platform.isIOS) return;

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'panic_button_bg',
        initialNotificationTitle: 'PanicButton Protection Active',
        initialNotificationContent: 'Monitoring ESP32 & Anti-Snatch',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static Future<void> showAlertNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'panic_alerts',
      'Emergency Alerts',
      channelDescription: 'Critical SOS and Anti-Snatch notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
