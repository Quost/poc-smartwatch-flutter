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
  DateTime? _selectedDateTime;
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
      reminder.text.hashCode,
      'Lembrete',
      reminder.text,
      scheduledDate,
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
            final Reminder reminder = reminders[index];
            return ListTile(
              title: Text(reminder.date != null
                  ? '${reminder.text} - ${DateFormat('dd/MM/yyyy HH:mm').format(reminder.date!)}'
                  : reminder.text),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, reminder),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        _showDeleteConfirmation(context, reminder.text),
                  ),
                ],
              ),
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
            await _selectDateTime(context, DateTime.now());

            if (_selectedDateTime != null) {
              _addReminder(
                  Reminder(reminderController.text, _selectedDateTime));
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

  Future<void> _showDeleteConfirmation(
      BuildContext context, String text) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: const Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel delete
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm delete
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      _removeReminder(text);
    }
  }

  Future<void> _showEditDialog(BuildContext context, Reminder reminder) async {
    TextEditingController textController = TextEditingController();
    textController.text = reminder.text;

    DateTime? selectedDateTime = reminder.date;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Lembrete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Lembrete'),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  await _selectDateTime(
                      context, selectedDateTime); // Refresh UI
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _selectedDateTime != null
                        ? DateFormat('dd/MM/yyyy HH:mm')
                            .format(_selectedDateTime!)
                        : 'Data não definida',
                    style: TextStyle(
                      color: _selectedDateTime != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _editReminder(reminder, textController.text, selectedDateTime);
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _editReminder(
    Reminder oldReminder,
    String newText,
    DateTime? newDateTime,
  ) {
    final provider = Provider.of<RemindersProvider>(context, listen: false);

    // Remove o lembrete original
    _removeReminder(oldReminder.text);

    // Adiciona o novo lembrete editado
    final newReminder = Reminder(newText, newDateTime);
    _addReminder(newReminder);
  }

  void _removeReminder(String text) {
    final provider = Provider.of<RemindersProvider>(context, listen: false);
    final reminder = provider.reminders.firstWhere((r) => r.text == text);

    if (reminder.date != null) {
      _cancelNotification(text); // Cancel the scheduled notification
    }

    provider.removeReminder(text); // Remove the reminder
  }

  void _cancelNotification(String text) {
    widget.flutterLocalNotificationsPlugin.cancel(text.hashCode);
  }

  Future<DateTime?> _selectDateTime(
      BuildContext context, DateTime? initialDateTime) async {
    return await showDatePicker(
      context: context,
      initialDate: _getInitialDate(initialDateTime ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) async {
      if (selectedDate != null) {
        return await showTimePicker(
          context: context,
          initialTime:
              TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
        ).then((selectedTime) {
          if (selectedTime != null) {
            setState(() {
              _selectedDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
            });
            return _selectedDateTime;
          }
          return null;
        });
      }
      return null;
    });
  }

  DateTime _getInitialDate(DateTime date) {
    return date.add(const Duration(minutes: 1));
  }
}
