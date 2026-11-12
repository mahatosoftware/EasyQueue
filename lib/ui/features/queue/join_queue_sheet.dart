import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/business_model.dart';
import 'package:easyqueue/data/models/branch_model.dart';
import 'package:easyqueue/data/models/service_model.dart';
import 'package:easyqueue/data/models/family_member_model.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';
import 'package:easyqueue/ui/view_models/family_view_model.dart';
import 'package:easyqueue/ui/features/queue/digital_ticket_screen.dart';
import 'package:easyqueue/ui/features/family/add_family_member_dialog.dart';

class JoinQueueSheet extends StatefulWidget {
  final BusinessModel business;
  final BranchModel branch;
  final ServiceModel service;

  const JoinQueueSheet({
    super.key,
    required this.business,
    required this.branch,
    required this.service,
  });

  @override
  State<JoinQueueSheet> createState() => _JoinQueueSheetState();
}

class _JoinQueueSheetState extends State<JoinQueueSheet> {
  int _groupSize = 1;
  PriorityType _selectedPriority = PriorityType.standard;
  FamilyMemberModel? _selectedBeneficiary; // null = For Self
  bool _acceptedTerms = true;

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final queueVm = context.watch<QueueViewModel>();
    final familyVm = context.watch<FamilyViewModel>();
    final user = authVm.currentUser;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Queue',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.business.name} • ${widget.branch.name}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.service.name,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.service.priceText ?? 'Free',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Est. wait: ~${widget.service.estimatedWaitMinutes} mins',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.people_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.service.currentWaitingCount} people ahead',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Who is receiving the service? (Self vs Family Member)
            Text(
              'Who is this ticket for?',
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Myself (${user?.displayName.split(' ').first ?? 'Self'})'),
                    selected: _selectedBeneficiary == null,
                    onSelected: (_) => setState(() => _selectedBeneficiary = null),
                  ),
                  const SizedBox(width: 8),
                  ...familyVm.familyMembers.map((fam) {
                    final isSel = _selectedBeneficiary?.id == fam.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${fam.name} (${fam.relationship})'),
                        selected: isSel,
                        onSelected: (_) => setState(() => _selectedBeneficiary = fam),
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Add Member'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddFamilyMemberDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Group Size
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Size (Party)',
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Number of persons joining together',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedLight),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: _groupSize > 1 ? () => setState(() => _groupSize--) : null,
                      ),
                      Text(
                        '$_groupSize',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: _groupSize < widget.service.maxGroupSize
                            ? () => setState(() => _groupSize++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Priority Assistance Category
            Text(
              'Priority / Special Assistance',
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PriorityType>(
                  value: _selectedPriority,
                  isExpanded: true,
                  items: PriorityType.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName, style: AppTypography.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPriority = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Requirements / Preparation Notice if any
            if (widget.service.requiredDocuments.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          'Required Documents to Bring',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.brown,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...widget.service.requiredDocuments.map((doc) => Padding(
                          padding: const EdgeInsets.only(left: 22, top: 2),
                          child: Text('• $doc', style: AppTypography.bodySmall),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Terms Checkbox
            Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                ),
                Expanded(
                  child: Text(
                    'I understand estimated wait time is an estimate and agree to business queue rules.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
              onPressed: (_acceptedTerms && user != null && !queueVm.isLoading)
                  ? () async {
                      final ticket = await queueVm.joinQueue(
                        businessId: widget.business.id,
                        businessName: widget.business.name,
                        businessLogo: widget.business.logoUrl,
                        branchId: widget.branch.id,
                        branchName: widget.branch.name,
                        branchAddress: widget.branch.address,
                        serviceId: widget.service.id,
                        serviceName: widget.service.name,
                        currentUser: user,
                        groupSize: _groupSize,
                        beneficiary: _selectedBeneficiary,
                        priority: _selectedPriority,
                      );

                      if (!context.mounted || ticket == null) return;
                      Navigator.pop(context); // Close sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DigitalTicketScreen(entryId: ticket.id),
                        ),
                      );
                    }
                  : null,
              child: queueVm.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirm & Get Digital Token',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
