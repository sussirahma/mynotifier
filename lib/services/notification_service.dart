import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('mynotifier/notification');

  static const EventChannel _eventChannel =
      EventChannel('mynotifier/notification_stream');

  static Future<bool> isNotificationListenerEnabled() async {
    final result = await _channel.invokeMethod<bool>(
      'isNotificationListenerEnabled',
    );

    return result ?? false;
  }

  static Future<void> openNotificationSettings() async {
    await _channel.invokeMethod(
      'openNotificationSettings',
    );
  }

  // Stream untuk menerima notifikasi dari Android
  static Stream<Map<dynamic, dynamic>> get notificationStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map(
          (event) => Map<dynamic, dynamic>.from(event),
        );
  }
}