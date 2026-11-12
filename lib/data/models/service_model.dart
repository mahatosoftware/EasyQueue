class ServiceModel {
  final String id;
  final String businessId;
  final String branchId;
  final String name;
  final String category;
  final String description;
  final int estimatedMinutesPerCustomer;
  final int currentWaitingCount;
  final bool isQueueOpen;
  final String? priceText;
  final List<String> requiredDocuments;
  final String? preparationInstructions;
  final int maxGroupSize;
  final bool allowsAppointments;

  ServiceModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.name,
    required this.category,
    required this.description,
    required this.estimatedMinutesPerCustomer,
    this.currentWaitingCount = 0,
    this.isQueueOpen = true,
    this.priceText,
    this.requiredDocuments = const [],
    this.preparationInstructions,
    this.maxGroupSize = 5,
    this.allowsAppointments = true,
  });

  int get estimatedWaitMinutes => currentWaitingCount * estimatedMinutesPerCustomer;

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      businessId: map['businessId'] ?? '',
      branchId: map['branchId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      estimatedMinutesPerCustomer: map['estimatedMinutesPerCustomer'] ?? 10,
      currentWaitingCount: map['currentWaitingCount'] ?? 0,
      isQueueOpen: map['isQueueOpen'] ?? true,
      priceText: map['priceText'],
      requiredDocuments: List<String>.from(map['requiredDocuments'] ?? []),
      preparationInstructions: map['preparationInstructions'],
      maxGroupSize: map['maxGroupSize'] ?? 5,
      allowsAppointments: map['allowsAppointments'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'branchId': branchId,
      'name': name,
      'category': category,
      'description': description,
      'estimatedMinutesPerCustomer': estimatedMinutesPerCustomer,
      'currentWaitingCount': currentWaitingCount,
      'isQueueOpen': isQueueOpen,
      'priceText': priceText,
      'requiredDocuments': requiredDocuments,
      'preparationInstructions': preparationInstructions,
      'maxGroupSize': maxGroupSize,
      'allowsAppointments': allowsAppointments,
    };
  }
}
