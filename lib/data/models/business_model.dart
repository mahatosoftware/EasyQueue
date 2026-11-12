import '../../core/constants/app_constants.dart';
import 'branch_model.dart';

class BusinessModel {
  final String id;
  final String name;
  final String logoUrl;
  final BusinessCategory category;
  final String description;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final List<BranchModel> branches;

  BusinessModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.category,
    required this.description,
    this.rating = 4.8,
    this.reviewCount = 120,
    this.isVerified = true,
    this.branches = const [],
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map, String id) {
    return BusinessModel(
      id: id,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      category: BusinessCategory.values.firstWhere(
        (e) => e.name == (map['category'] ?? ''),
        orElse: () => BusinessCategory.all,
      ),
      description: map['description'] ?? '',
      rating: (map['rating'] ?? 4.8).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isVerified: map['isVerified'] ?? true,
      branches: (map['branches'] as List<dynamic>?)
              ?.map((b) => BranchModel.fromMap(b as Map<String, dynamic>, b['id'] ?? ''))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'category': category.name,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
    };
  }
}
