import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/business_model.dart';
import 'package:easyqueue/ui/view_models/explore_view_model.dart';
import 'package:easyqueue/ui/features/explore/business_detail_screen.dart';
import 'package:easyqueue/ui/features/queue/join_queue_sheet.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exploreVm = context.watch<ExploreViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explore Businesses',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => exploreVm.search(query: val),
                  decoration: InputDecoration(
                    hintText: 'Search clinic, lab, bank, salon...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: exploreVm.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => exploreVm.search(query: ''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Sort Options & Category Chips
                Row(
                  children: [
                    Text(
                      'Sort by:',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 8),
                    _buildSortPill(context, exploreVm, 'nearest', 'Nearest'),
                    const SizedBox(width: 6),
                    _buildSortPill(context, exploreVm, 'shortest_wait', 'Shortest Wait'),
                    const SizedBox(width: 6),
                    _buildSortPill(context, exploreVm, 'highest_rated', 'Top Rated'),
                  ],
                ),
              ],
            ),
          ),

          // Categories Filter Row
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: BusinessCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = BusinessCategory.values[index];
                final isSelected = exploreVm.selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (_) => exploreVm.updateCategory(cat),
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Results List
          Expanded(
            child: exploreVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : exploreVm.searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'No businesses found matching your criteria.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedLight),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
                        itemCount: exploreVm.searchResults.length,
                        itemBuilder: (context, index) {
                          final biz = exploreVm.searchResults[index];
                          return _buildBusinessItem(context, biz);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortPill(
    BuildContext context,
    ExploreViewModel exploreVm,
    String key,
    String label,
  ) {
    final isSelected = exploreVm.sortBy == key;
    return GestureDetector(
      onTap: () => exploreVm.updateSort(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessItem(BuildContext context, BusinessModel biz) {
    final branch = biz.branches.isNotEmpty ? biz.branches.first : null;
    final service = branch != null && branch.services.isNotEmpty ? branch.services.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: biz)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          biz.name,
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          branch?.address ?? 'Main Branch',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text('${biz.rating}', style: AppTypography.labelSmall),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: AppColors.textMutedLight)),
                            const SizedBox(width: 8),
                            Text('${branch?.distanceKm ?? 1.2} km', style: AppTypography.labelSmall),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: AppColors.textMutedLight)),
                            const SizedBox(width: 8),
                            Text(
                              branch?.isOpen == true ? 'Open Now' : 'Closed',
                              style: AppTypography.labelSmall.copyWith(
                                color: branch?.isOpen == true ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                biz.description,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '~${service?.estimatedWaitMinutes ?? 15} min wait • ${service?.currentWaitingCount ?? 2} in line',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {
                      if (branch != null && service != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => JoinQueueSheet(
                            business: biz,
                            branch: branch,
                            service: service,
                          ),
                        );
                      }
                    },
                    child: const Text('Join Queue', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
