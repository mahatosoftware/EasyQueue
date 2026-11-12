import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/core/utils/date_formatter.dart';
import 'package:easyqueue/data/models/queue_entry_model.dart';
import 'queue_status_badge.dart';

class DigitalTokenCard extends StatelessWidget {
  final QueueEntryModel ticket;
  final bool showQr;
  final VoidCallback? onTap;

  const DigitalTokenCard({
    super.key,
    required this.ticket,
    this.showQr = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: AppColors.backgroundLight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.business_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.businessName,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ticket.branchName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    QueueStatusBadge(status: ticket.status),
                  ],
                ),
              ),

              // Main Token Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    if (ticket.beneficiaryName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Patient: ${ticket.beneficiaryName}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Text(
                      ticket.serviceName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Big Bold Token
                    Text(
                      ticket.tokenNumber,
                      style: AppTypography.tokenNumber.copyWith(
                        color: ticket.status == QueueStatus.called
                            ? AppColors.statusCalled
                            : AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (ticket.assignedCounterNumber != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Assigned: ${ticket.assignedCounterNumber}',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Queue Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildMetricCol(
                            title: 'Ahead',
                            value: ticket.status == QueueStatus.called
                                ? 'Now'
                                : '${ticket.customersAhead}',
                            icon: Icons.people_outline,
                          ),
                        ),
                        Container(height: 30, width: 1, color: AppColors.borderLight),
                        Expanded(
                          child: _buildMetricCol(
                            title: 'Est. Wait',
                            value: ticket.status == QueueStatus.called
                                ? '0 min'
                                : DateFormatter.formatEstimatedWait(ticket.estimatedWaitSeconds),
                            icon: Icons.access_time,
                          ),
                        ),
                        Container(height: 30, width: 1, color: AppColors.borderLight),
                        Expanded(
                          child: _buildMetricCol(
                            title: 'Joined',
                            value: DateFormatter.formatTime(ticket.joinedAt),
                            icon: Icons.history,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Perforation Divider
              _buildPerforatedDivider(),

              // QR Code Section
              if (showQr) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: QrImageView(
                          data: ticket.verificationQrCode,
                          version: QrVersions.auto,
                          size: 64.0,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Verification Code',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ticket.verificationQrCode,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondaryLight,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Show this code or scan at arrival kiosk',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMutedLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMutedLight),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPerforatedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Dashed Line
            Row(
              children: List.generate(
                (constraints.maxWidth / 10).floor(),
                (index) => Expanded(
                  child: Container(
                    height: 1.5,
                    color: index.isEven ? AppColors.borderLight : Colors.transparent,
                  ),
                ),
              ),
            ),
            // Left Notch
            Positioned(
              left: -12,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Right Notch
            Positioned(
              right: -12,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
