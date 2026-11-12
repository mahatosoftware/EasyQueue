import 'package:flutter/material.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/business_model.dart';
import 'package:easyqueue/data/models/branch_model.dart';
import 'package:easyqueue/data/models/service_model.dart';
import 'package:easyqueue/ui/features/queue/join_queue_sheet.dart';
import 'package:easyqueue/ui/features/appointments/book_appointment_view.dart';

class BusinessDetailScreen extends StatelessWidget {
  final BusinessModel business;

  const BusinessDetailScreen({
    super.key,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    final branch = business.branches.isNotEmpty ? business.branches.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(business.name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
        children: [
          // Business Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 32),
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
                                  business.name,
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (business.isVerified)
                                const Icon(Icons.verified, size: 18, color: AppColors.primary),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            business.category.displayName,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                '${business.rating} (${business.reviewCount} customer reviews)',
                                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  business.description,
                  style: AppTypography.bodyMedium,
                ),
                if (branch != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.dividerLight),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch.address,
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Hours: ${branch.openingHours}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.countertops_outlined, size: 18, color: AppColors.textMutedLight),
                      const SizedBox(width: 8),
                      Text(
                        '${branch.totalCounters} Active Service Counters',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available Services Section
          Text(
            'Available Services & Queues',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          if (branch != null)
            ...branch.services.map((srv) => _buildServiceCard(context, branch, srv)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, BranchModel branch, ServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (service.priceText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    service.priceText!,
                    style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            service.description,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${service.currentWaitingCount} in queue',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Est. ~${service.estimatedWaitMinutes} min wait',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (service.requiredDocuments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.assignment_outlined, size: 14, color: AppColors.textMutedLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Docs required: ${service.requiredDocuments.join(", ")}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedLight,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => JoinQueueSheet(
                        business: business,
                        branch: branch,
                        service: service,
                      ),
                    );
                  },
                  child: const Text('Join Live Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (service.allowsAppointments) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookAppointmentView(
                          business: business,
                          branch: branch,
                          service: service,
                        ),
                      ),
                    );
                  },
                  child: const Text('Book Slot'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
