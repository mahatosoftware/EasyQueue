import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/view_models/family_view_model.dart';
import 'package:easyqueue/ui/features/family/add_family_member_dialog.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyVm = context.watch<FamilyViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Family Member',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddFamilyMemberDialog(),
              );
            },
          ),
        ],
      ),
      body: familyVm.familyMembers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 56, color: AppColors.textMutedLight),
                  const SizedBox(height: 12),
                  Text(
                    'No family members added',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add your children, parents, or spouse to join queues on their behalf.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
              itemCount: familyVm.familyMembers.length,
              itemBuilder: (context, index) {
                final member = familyVm.familyMembers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : 'F',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(member.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Relationship: ${member.relationship}', style: AppTypography.bodySmall),
                        if (member.accessibilityRequirements != null)
                          Text('Special: ${member.accessibilityRequirements}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.secondary)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => familyVm.removeFamilyMember(member.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Family Member'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddFamilyMemberDialog(),
          );
        },
      ),
    );
  }
}
