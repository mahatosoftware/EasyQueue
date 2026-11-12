import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/view_models/family_view_model.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  const AddFamilyMemberDialog({super.key});

  @override
  State<AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  final _nameController = TextEditingController();
  final _accessibilityController = TextEditingController();
  String _selectedRelationship = 'Child';

  final List<String> _relationships = ['Child', 'Parent', 'Spouse', 'Sibling', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _accessibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyVm = context.watch<FamilyViewModel>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.person_add_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Add Family Member', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. Maya Morgan'),
            ),
            const SizedBox(height: 12),

            Text('Relationship', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRelationship,
                  isExpanded: true,
                  items: _relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRelationship = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text('Accessibility / Medical Needs (Optional)', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            TextField(
              controller: _accessibilityController,
              decoration: const InputDecoration(hintText: 'e.g. Wheelchair assistance, pediatric care'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(90, 40),
          ),
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              await familyVm.addFamilyMember(
                name: name,
                relationship: _selectedRelationship,
                accessibilityRequirements: _accessibilityController.text.trim().isNotEmpty
                    ? _accessibilityController.text.trim()
                    : null,
              );
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Add Member'),
        ),
      ],
    );
  }
}
