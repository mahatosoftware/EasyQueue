import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';
import 'package:easyqueue/ui/features/auth/otp_verification_view.dart';
import 'package:easyqueue/ui/features/home/main_navigation_shell.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _phoneController = TextEditingController(text: '4155552671');
  final _nameController = TextEditingController(text: 'Alex Morgan');
  final String _selectedCountryCode = '+1';

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, AppConstants.bottomNavPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // App Brand
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                AppConstants.appTagline,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Inputs
              Text('Your Name', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Alex Morgan',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              Text('Phone Number', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('🇺🇸 $_selectedCountryCode', style: AppTypography.bodyMedium),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '415 555 2671',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Continue Button
              ElevatedButton(
                onPressed: authVm.isLoading
                    ? null
                    : () async {
                        final phone = _phoneController.text.trim();
                        if (phone.isNotEmpty) {
                          final fullPhone = '$_selectedCountryCode$phone';
                          final sent = await authVm.sendPhoneOtp(fullPhone);
                          if (context.mounted) {
                            if (sent) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OtpVerificationView(
                                    phoneNumber: phone,
                                    countryCode: _selectedCountryCode,
                                    name: _nameController.text.trim(),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authVm.errorMessage ?? 'Failed to send OTP.'),
                                ),
                              );
                            }
                          }
                        }
                      },
                child: authVm.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send Verification Code', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTypography.labelSmall.copyWith(color: AppColors.textMutedLight)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Guest Access Shortcut (UC-004)
              OutlinedButton.icon(
                icon: const Icon(Icons.flash_on_rounded, color: AppColors.warning),
                label: const Text('Continue as Guest (No Account Required)'),
                onPressed: () async {
                  await authVm.loginAsGuest(name: _nameController.text.trim());
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Google Sign In Shortcut
              OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Sign in with Google'),
                onPressed: () async {
                  await authVm.loginWithPhoneOtp(
                    phoneNumber: '4155552671',
                    countryCode: '+1',
                    otp: '123456',
                    name: 'Alex Morgan',
                  );
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 32),

              Text(
                'By signing in, you agree to Easy Queue Terms of Service and Privacy Policy.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
