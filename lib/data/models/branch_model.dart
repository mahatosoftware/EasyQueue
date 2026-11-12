import 'service_model.dart';

class BranchModel {
  final String id;
  final String businessId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final bool isOpen;
  final String openingHours;
  final String phoneNumber;
  final int activeQueuesCount;
  final int totalCounters;
  final bool supportsAppointments;
  final bool supportsGuestJoin;
  final String? arrivalInstructions;
  final List<ServiceModel> services;

  BranchModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm = 1.2,
    this.isOpen = true,
    required this.openingHours,
    required this.phoneNumber,
    this.activeQueuesCount = 1,
    this.totalCounters = 4,
    this.supportsAppointments = true,
    this.supportsGuestJoin = true,
    this.arrivalInstructions,
    this.services = const [],
  });

  factory BranchModel.fromMap(Map<String, dynamic> map, String id) {
    return BranchModel(
      id: id,
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      distanceKm: (map['distanceKm'] ?? 1.2).toDouble(),
      isOpen: map['isOpen'] ?? true,
      openingHours: map['openingHours'] ?? '9:00 AM - 6:00 PM',
      phoneNumber: map['phoneNumber'] ?? '',
      activeQueuesCount: map['activeQueuesCount'] ?? 1,
      totalCounters: map['totalCounters'] ?? 4,
      supportsAppointments: map['supportsAppointments'] ?? true,
      supportsGuestJoin: map['supportsGuestJoin'] ?? true,
      arrivalInstructions: map['arrivalInstructions'],
      services: (map['services'] as List<dynamic>?)
              ?.map((s) => ServiceModel.fromMap(s as Map<String, dynamic>, s['id'] ?? ''))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'isOpen': isOpen,
      'openingHours': openingHours,
      'phoneNumber': phoneNumber,
      'activeQueuesCount': activeQueuesCount,
      'totalCounters': totalCounters,
      'supportsAppointments': supportsAppointments,
      'supportsGuestJoin': supportsGuestJoin,
      'arrivalInstructions': arrivalInstructions,
    };
  }
}
