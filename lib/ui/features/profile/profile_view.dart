import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/view_models/profile_view_model.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';
import 'package:easyqueue/ui/view_models/family_view_model.dart';
import 'package:easyqueue/ui/features/profile/edit_profile_view.dart';
import 'package:easyqueue/ui/features/profile/notification_preferences_view.dart';
import 'package:easyqueue/ui/features/profile/privacy_settings_view.dart';
import 'package:easyqueue/ui/features/family/family_members_screen.dart';
import 'package:easyqueue/ui/features/auth/auth_screen.dart';
import 'package:easyqueue/ui/features/auth/guest_onboarding_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final queueVm = context.watch<QueueViewModel>();
    final familyVm = context.watch<FamilyViewModel>();
    final user = profileVm.user;
    final isGuest = user?.isGuest ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, AppConstants.bottomNavPadding),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    user != null && user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'U',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user?.displayName ?? 'Customer',
                              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isGuest)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'GUEST',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.phoneNumber.isNotEmpty == true
                            ? user!.phoneNumber
                            : 'Guest Access • Phone not linked',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileView()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Upgrade Guest to Account Banner (UC-004)
          if (isGuest) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Full Account',
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Keep tickets synchronized and manage family members.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const GuestOnboardingSheet(),
                      );
                    },
                    child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Menu Options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people_outline, color: AppColors.primary),
                  title: const Text('Family Members'),
                  subtitle: Text('${familyVm.familyMembers.length} members saved'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FamilyMembersScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_none, color: AppColors.primary),
                  title: const Text('Notification Preferences'),
                  subtitle: const Text('Push, SMS, sound & vibrate'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationPreferencesView()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_outlined, color: AppColors.primary),
                  title: const Text('Privacy & Security'),
                  subtitle: const Text('Permissions and account data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacySettingsView()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined, color: AppColors.primary),
                  title: const Text('Language'),
                  trailing: const Text('English (US)'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language selection: English (US)')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Help & About Card
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.secondary),
                  title: const Text('Help & FAQ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.secondary),
                  title: const Text('About Easy Queue'),
                  subtitle: const Text('v1.0.0 • in.mahato.easyqueue'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: '1.0.0',
                      applicationIcon: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      applicationLegalese: '© 2026 Easy Queue Inc. All rights reserved.',
                      children: [
                        const SizedBox(height: 12),
                        const Text(AppConstants.appTagline),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Action (UC-006: checks active tickets before logout)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.borderLight),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            onPressed: () => _confirmSignOut(context, profileVm, queueVm),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmSignOut(
    BuildContext context,
    ProfileViewModel profileVm,
    QueueViewModel queueVm,
  ) {
    final hasActive = queueVm.activeTickets.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: Text(
          hasActive
              ? 'WARNING: You have ${queueVm.activeTickets.length} active queue ticket(s). If you sign out now, queue call push notifications will not reach this device until you sign back in.'
              : 'Are you sure you want to sign out from this device?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await profileVm.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Easy Queue Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How do I join a queue?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('You can join remotely by selecting any business from the Home or Explore tab, or by scanning the physical QR code at the business venue.'),
              SizedBox(height: 12),
              Text('Can I join for my family?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Yes! Add family members under Profile > Family Members, and select them during the Join Queue step.'),
              SizedBox(height: 12),
              Text('What happens when my turn is called?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('You will receive a prominent alert showing your assigned service counter number and location.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
