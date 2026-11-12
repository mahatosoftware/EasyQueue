import '../../core/utils/date_formatter.dart';

class ReviewModel {
  final String id;
  final String customerId;
  final String customerName;
  final String businessId;
  final String branchId;
  final String serviceId;
  final String entryId;
  final double rating;
  final double? waitTimeRating;
  final double? staffRating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.businessId,
    required this.branchId,
    required this.serviceId,
    required this.entryId,
    required this.rating,
    this.waitTimeRating,
    this.staffRating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Anonymous',
      businessId: map['businessId'] ?? '',
      branchId: map['branchId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      entryId: map['entryId'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      waitTimeRating: map['waitTimeRating'] != null ? (map['waitTimeRating']).toDouble() : null,
      staffRating: map['staffRating'] != null ? (map['staffRating']).toDouble() : null,
      comment: map['comment'] ?? '',
      createdAt: DateFormatter.parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'businessId': businessId,
      'branchId': branchId,
      'serviceId': serviceId,
      'entryId': entryId,
      'rating': rating,
      'waitTimeRating': waitTimeRating,
      'staffRating': staffRating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
