import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';
import 'package:easyqueue/ui/features/home/main_navigation_shell.dart';

class OtpVerificationView extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String? name;

  const OtpVerificationView({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    this.name,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final TextEditingController _otpController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, AppConstants.bottomNavPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Verification Code',
              style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit OTP code to ${widget.countryCode} ${widget.phoneNumber}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: AppTypography.displayLarge.copyWith(letterSpacing: 10),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '123456',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authVm.isLoading
                  ? null
                  : () async {
                      final success = await authVm.loginWithPhoneOtp(
                        phoneNumber: widget.phoneNumber,
                        countryCode: widget.countryCode,
                        otp: _otpController.text.trim(),
                        name: widget.name,
                      );
                      if (context.mounted && success) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                          (route) => false,
                        );
                      }
                    },
              child: authVm.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification code resent via SMS.')),
                );
              },
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
