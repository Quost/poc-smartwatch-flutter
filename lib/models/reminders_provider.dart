import 'package:flutter/material.dart';
import 'reminder.dart';

class RemindersProvider extends ChangeNotifier {
  final List<Reminder> _reminders = [];

  List<Reminder> get reminders => _reminders;

  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
    notifyListeners();
  }
}
