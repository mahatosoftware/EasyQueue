import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/user_model.dart';
import 'package:easyqueue/ui/view_models/profile_view_model.dart';

class NotificationPreferencesView extends StatefulWidget {
  const NotificationPreferencesView({super.key});

  @override
  State<NotificationPreferencesView> createState() => _NotificationPreferencesViewState();
}

class _NotificationPreferencesViewState extends State<NotificationPreferencesView> {
  late bool _push;
  late bool _sms;
  late bool _whatsapp;
  late bool _sound;
  late bool _vibrate;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileViewModel>().user;
    final prefs = user?.notificationPreferences ?? const NotificationPreferences();
    _push = prefs.pushEnabled;
    _sms = prefs.smsEnabled;
    _whatsapp = prefs.whatsappEnabled;
    _sound = prefs.soundAlerts;
    _vibrate = prefs.vibrateOnCall;
  }

  void _save(ProfileViewModel profileVm) {
    profileVm.updateNotificationPreferences(
      NotificationPreferences(
        pushEnabled: _push,
        smsEnabled: _sms,
        whatsappEnabled: _whatsapp,
        soundAlerts: _sound,
        vibrateOnCall: _vibrate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
        children: [
          Text(
            'Channels',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Real-time alerts when your token is approaching or called'),
            value: _push,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _push = v);
              _save(profileVm);
            },
          ),
          SwitchListTile(
            title: const Text('SMS Text Messages'),
            subtitle: const Text('Backup notifications delivered to your verified phone'),
            value: _sms,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _sms = v);
              _save(profileVm);
            },
          ),
          SwitchListTile(
            title: const Text('WhatsApp Messages'),
            subtitle: const Text('Receive live queue tracking link via WhatsApp'),
            value: _whatsapp,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _whatsapp = v);
              _save(profileVm);
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Alert Behavior',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Sound Alerts on Call'),
            subtitle: const Text('Play chime when your counter is assigned'),
            value: _sound,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _sound = v);
              _save(profileVm);
            },
          ),
          SwitchListTile(
            title: const Text('Vibrate on Call'),
            subtitle: const Text('Vibrate device when token is announced'),
            value: _vibrate,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _vibrate = v);
              _save(profileVm);
            },
          ),
        ],
      ),
    );
  }
}
