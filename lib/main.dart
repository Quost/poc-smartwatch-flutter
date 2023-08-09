import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartwatch_poc/models/reminders_provider.dart';
import 'package:smartwatch_poc/screens/reminders_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  runApp(
    ChangeNotifierProvider(
      create: (context) => RemindersProvider(),
      child: const RemindersApp(),
    ),
  );

  await initializeNotifications();
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
          'app_icon'); // Substitua 'app_icon' pelo nome do seu ícone
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
}

class RemindersApp extends StatelessWidget {
  const RemindersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lembretes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RemindersScreen(
          flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin),
    );
  }
}
