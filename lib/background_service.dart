import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:telephony/telephony.dart';

void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final telephony = Telephony.instance;
  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) {
      _showNotification(flutterLocalNotificationsPlugin, message);
    },
    listenInBackground: true,
    onBackgroundMessage: backgroundMessageHandler,
  );
}

void _showNotification(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin, SmsMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'sms_channel_id',
    'SMS Notifications',
    channelDescription: 'Channel for SMS notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0,
    'New SMS from ${message.address}',
    message.body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}

Future<void> backgroundMessageHandler(SmsMessage message) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  _showNotification(flutterLocalNotificationsPlugin, message);
}
