import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';

class GuestOnboardingSheet extends StatefulWidget {
  const GuestOnboardingSheet({super.key});

  @override
  State<GuestOnboardingSheet> createState() => _GuestOnboardingSheetState();
}

class _GuestOnboardingSheetState extends State<GuestOnboardingSheet> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController(text: '123456');
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Claim & Save Your Ticket',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Link your active queue tokens to your phone number so you never lose your spot and receive push call notifications.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),

          if (!_otpSent) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g. Alex Morgan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Phone Number',
                hintText: '+1 415-555-2671',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_phoneController.text.trim().isNotEmpty) {
                  setState(() => _otpSent = true);
                }
              },
              child: const Text('Send Verification Code'),
            ),
          ] else ...[
            Text(
              'Enter the 6-digit code sent to ${_phoneController.text.trim()}',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(letterSpacing: 6),
              decoration: const InputDecoration(hintText: '123456'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: authVm.isLoading
                  ? null
                  : () async {
                      final success = await authVm.claimGuestTicket(
                        phoneNumber: _phoneController.text.trim(),
                        otp: _otpController.text.trim(),
                        targetName: _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : 'Alex Morgan',
                      );
                      if (context.mounted && success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket claimed and account verified successfully!')),
                        );
                      }
                    },
              child: const Text('Confirm & Save Ticket'),
            ),
          ],
        ],
      ),
    );
  }
}
