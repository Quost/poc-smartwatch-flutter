import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:smartwatch_poc/models/reminder.dart';
import 'package:smartwatch_poc/models/reminders_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class RemindersScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const RemindersScreen({
    Key? key,
    required this.flutterLocalNotificationsPlugin,
  }) : super(key: key);

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  void _addReminder(Reminder reminder) async {
    final provider = Provider.of<RemindersProvider>(context, listen: false);
    provider.addReminder(reminder);

    if (reminder.date != null) {
      await _scheduleNotification(reminder);
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    tzdata.initializeTimeZones();

    final scheduledDate = tz.TZDateTime.from(reminder.date!, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Substitua pelo ID do seu canal de notificação
      'Lembrete Channel', // Substitua pelo nome do seu canal de notificação
      channelDescription:
          'Canal para lembretes', // Substitua pela descrição do seu canal de notificação
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await widget.flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID da notificação (deve ser único)
      'Lembrete', // Título da notificação
      reminder.text, // Corpo da notificação
      scheduledDate, // Data e hora agendadas
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersProvider = Provider.of<RemindersProvider>(context);
    final reminders = remindersProvider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Lembretes'),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (BuildContext context, int index) {
            final reminder = reminders[index];
            return ListTile(
              title: Text(reminder.date != null
                  ? '${reminder.text} - ${DateFormat('dd/MM/yyyy HH:mm').format(reminder.date!)}'
                  : reminder.text),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          TextEditingController reminderController = TextEditingController();
          bool addDate =
              await _showAddReminderDialog(context, reminderController);

          if (addDate) {
            DateTime? selectedDate = await _showDatePicker(context);
            TimeOfDay? selectedTime = await _showTimePicker(context);

            if (selectedTime != null && selectedDate != null) {
              DateTime reminderDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              _addReminder(Reminder(reminderController.text, reminderDateTime));
            }
          } else {
            _addReminder(Reminder(reminderController.text));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _showAddReminderDialog(
      BuildContext context, TextEditingController controller) async {
    bool isReminderWithDate = false;

    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Lembrete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Lembrete'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (bool? value) {
                      isReminderWithDate = value == true;
                      Navigator.of(context).pop(isReminderWithDate);
                    },
                  ),
                  const Text('Adicionar Data'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Não adicionar data
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(isReminderWithDate); // Adicionar data
              },
              child: const Text('Próximo'),
            ),
          ],
        );
      },
    );
  }

  Future<DateTime?> _showDatePicker(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context) async {
    return await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }
}
