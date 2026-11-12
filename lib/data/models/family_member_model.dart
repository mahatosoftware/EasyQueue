import '../../core/utils/date_formatter.dart';

class FamilyMemberModel {
  final String id;
  final String name;
  final String relationship; // Child, Parent, Spouse, Other
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? accessibilityRequirements;
  final DateTime createdAt;

  FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    this.phoneNumber,
    this.accessibilityRequirements,
    required this.createdAt,
  });

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map, String id) {
    return FamilyMemberModel(
      id: id,
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? 'Family',
      dateOfBirth: map['dateOfBirth'],
      phoneNumber: map['phoneNumber'],
      accessibilityRequirements: map['accessibilityRequirements'],
      createdAt: DateFormatter.parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'dateOfBirth': dateOfBirth,
      'phoneNumber': phoneNumber,
      'accessibilityRequirements': accessibilityRequirements,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

