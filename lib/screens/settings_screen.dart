import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/expiry_reminder_service.dart';
import '../services/google_auth.dart';
import '../services/product_repository.dart';
import '../services/reminder_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;

  static final _timeFmt = DateFormat.Hm('fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await ReminderPreferences.load();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = prefs.enabled;
      _reminderTime = TimeOfDay(hour: prefs.hour, minute: prefs.minute);
      _loading = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _persistAndReschedule();
    }
  }

  Future<void> _onReminderToggle(bool value) async {
    if (value) {
      final ok = await ExpiryReminderService.instance.requestNotificationPermission();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autorisez les notifications pour Perimax dans les reglages du telephone.',
            ),
          ),
        );
      }
    }
    setState(() => _reminderEnabled = value);
    await _persistAndReschedule();
  }

  Future<void> _persistAndReschedule() async {
    setState(() => _saving = true);
    try {
      await ReminderPreferences.save(
        enabled: _reminderEnabled,
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
      final repo = ProductRepository();
      if (_reminderEnabled) {
        final products = await repo.fetchProductsOnce();
        await ExpiryReminderService.instance.rescheduleAllProducts(products);
      } else {
        await ExpiryReminderService.instance.cancelAll();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await signOutGoogle();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Rappels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Rappel le jour de la peremption'),
                  subtitle: const Text(
                    'Notification locale le jour ou la date est atteinte, a l\'heure choisie ci-dessous.',
                  ),
                  value: _reminderEnabled,
                  onChanged: _saving ? null : _onReminderToggle,
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Heure du rappel'),
                  subtitle: Text(_timeFmt.format(
                    DateTime(2000, 1, 1, _reminderTime.hour, _reminderTime.minute),
                  )),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _saving ? null : _pickTime,
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: LinearProgressIndicator()),
                  ),
                const SizedBox(height: 32),
                Text(
                  'Compte',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Deconnexion'),
                ),
              ],
            ),
    );
  }
}
