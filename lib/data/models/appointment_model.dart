import '../../core/utils/date_formatter.dart';

class AppointmentModel {
  final String id;
  final String customerId;
  final String businessId;
  final String businessName;
  final String? businessLogo;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final String serviceId;
  final String serviceName;
  final String slotId;
  final String? beneficiaryId;
  final String? beneficiaryName;
  final DateTime appointmentTime;
  final String status; // confirmed, checked_in, completed, cancelled
  final DateTime? checkedInAt;
  final String? associatedQueueEntryId;
  final String? preparationNotes;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.businessId,
    required this.businessName,
    this.businessLogo,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
    required this.serviceId,
    required this.serviceName,
    required this.slotId,
    this.beneficiaryId,
    this.beneficiaryName,
    required this.appointmentTime,
    this.status = 'confirmed',
    this.checkedInAt,
    this.associatedQueueEntryId,
    this.preparationNotes,
    required this.createdAt,
  });

  bool get isUpcoming =>
      (status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'scheduled') &&
      appointmentTime.isAfter(DateTime.now());

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    final rawStatus = (map['status'] ?? 'confirmed').toString().toLowerCase();
    String normalizedStatus = 'confirmed';
    if (rawStatus == 'scheduled' || rawStatus == 'confirmed') {
      normalizedStatus = 'confirmed';
    } else if (rawStatus == 'checked_in' || rawStatus == 'checkedin') {
      normalizedStatus = 'checked_in';
    } else if (rawStatus == 'cancelled') {
      normalizedStatus = 'cancelled';
    } else if (rawStatus == 'completed') {
      normalizedStatus = 'completed';
    }

    final rawTime = map['appointmentTime'] ?? map['scheduledTime'];

    return AppointmentModel(
      id: id,
      customerId: map['customerId'] ?? '',
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      businessLogo: map['businessLogo'],
      branchId: map['branchId'] ?? '',
      branchName: map['branchName'] ?? '',
      branchAddress: map['branchAddress'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? 'Service',
      slotId: map['slotId'] ?? 'slot_$id',
      beneficiaryId: map['beneficiaryId'],
      beneficiaryName: map['beneficiaryName'] ?? map['customerName'],
      appointmentTime: DateFormatter.parseDateTime(rawTime),
      status: normalizedStatus,
      checkedInAt: DateFormatter.parseNullableDateTime(map['checkedInAt']),
      associatedQueueEntryId: map['associatedQueueEntryId'],
      preparationNotes: map['preparationNotes'] ?? map['notes'],
      createdAt: DateFormatter.parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': beneficiaryName ?? 'Customer',
      'businessId': businessId,
      'businessName': businessName,
      'businessLogo': businessLogo,
      'branchId': branchId,
      'branchName': branchName,
      'branchAddress': branchAddress,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'slotId': slotId,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'appointmentTime': appointmentTime.toIso8601String(),
      'scheduledTime': appointmentTime.toIso8601String(),
      'status': status.toUpperCase(),
      'checkedInAt': checkedInAt?.toIso8601String(),
      'associatedQueueEntryId': associatedQueueEntryId,
      'preparationNotes': preparationNotes,
      'notes': preparationNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }


  AppointmentModel copyWith({
    String? status,
    DateTime? checkedInAt,
    String? associatedQueueEntryId,
    DateTime? appointmentTime,
  }) {
    return AppointmentModel(
      id: id,
      customerId: customerId,
      businessId: businessId,
      businessName: businessName,
      businessLogo: businessLogo,
      branchId: branchId,
      branchName: branchName,
      branchAddress: branchAddress,
      serviceId: serviceId,
      serviceName: serviceName,
      slotId: slotId,
      beneficiaryId: beneficiaryId,
      beneficiaryName: beneficiaryName,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      associatedQueueEntryId:
          associatedQueueEntryId ?? this.associatedQueueEntryId,
      preparationNotes: preparationNotes,
      createdAt: createdAt,
    );
  }
}
