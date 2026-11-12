import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/view_models/profile_view_model.dart';
import 'package:easyqueue/ui/features/auth/auth_screen.dart';

class PrivacySettingsView extends StatelessWidget {
  const PrivacySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
        children: [
          Text('Data Sharing & Privacy', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.location_off_outlined, color: AppColors.primary),
            title: Text('Location Privacy'),
            subtitle: Text('Location is only accessed on-demand for nearby business discovery and is never stored continuously.'),
          ),
          const ListTile(
            leading: Icon(Icons.visibility_off_outlined, color: AppColors.primary),
            title: Text('Anonymous Display'),
            subtitle: Text('Only your token number (e.g. B025) is displayed on public counter monitors.'),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text('Account & Device Management', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.devices, color: AppColors.secondary),
            title: const Text('Connected Devices'),
            subtitle: const Text('Currently signed in on this mobile device'),
            trailing: const Text('1 active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            title: const Text('Download My Data'),
            subtitle: const Text('Export all queue visits and appointment records'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export archive requested. Check your email.')),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Delete My Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            subtitle: const Text('Permanently erase account profile and family associations'),
            onTap: () => _confirmDeleteAccount(context, profileVm),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, ProfileViewModel profileVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is irreversible. All your profile information and saved preferences will be erased.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await profileVm.deleteAccount();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
