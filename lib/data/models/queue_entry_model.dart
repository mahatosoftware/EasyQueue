import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';

class QueueEntryModel {
  final String id;
  final String? customerId;
  final String? guestReferenceHash;
  final String businessId;
  final String businessName;
  final String? businessLogo;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final String serviceId;
  final String serviceName;
  final String queueId;
  final String tokenNumber;
  final String tokenPrefix;
  final int tokenSequence;
  final QueueStatus status;
  final PriorityType priority;
  final QueueSource source;
  final int groupSize;
  final String? beneficiaryId;
  final String? beneficiaryName;
  final String createdByUserId;
  final String? assignedCounterId;
  final String? assignedCounterNumber;
  final String? assignedCounterFloor;
  final String? assignedOperatorName;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final DateTime? serviceStartedAt;
  final DateTime? completedAt;
  final int estimatedWaitSeconds;
  final int customersAhead;
  final String verificationQrCode;
  final String? cancellationReason;
  final bool isDelayNotified;

  QueueEntryModel({
    required this.id,
    this.customerId,
    this.guestReferenceHash,
    required this.businessId,
    required this.businessName,
    this.businessLogo,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
    required this.serviceId,
    required this.serviceName,
    required this.queueId,
    required this.tokenNumber,
    required this.tokenPrefix,
    required this.tokenSequence,
    required this.status,
    this.priority = PriorityType.standard,
    this.source = QueueSource.mobileApp,
    this.groupSize = 1,
    this.beneficiaryId,
    this.beneficiaryName,
    required this.createdByUserId,
    this.assignedCounterId,
    this.assignedCounterNumber,
    this.assignedCounterFloor,
    this.assignedOperatorName,
    required this.joinedAt,
    this.calledAt,
    this.serviceStartedAt,
    this.completedAt,
    required this.estimatedWaitSeconds,
    required this.customersAhead,
    required this.verificationQrCode,
    this.cancellationReason,
    this.isDelayNotified = false,
  });

  bool get isActive => status.isActive;

  factory QueueEntryModel.fromMap(Map<String, dynamic> map, String id) {
    final customerMap = map['customer'] is Map<String, dynamic>
        ? map['customer'] as Map<String, dynamic>
        : (map['customer'] is Map ? Map<String, dynamic>.from(map['customer'] as Map) : null);

    final resolvedCustId = map['customerId'] ?? customerMap?['id'];
    final resolvedCustName = map['beneficiaryName'] ?? customerMap?['name'];

    final rawStatus = (map['status'] ?? '').toString().toUpperCase();
    QueueStatus parsedStatus = QueueStatus.waiting;
    switch (rawStatus) {
      case 'JOINED':
        parsedStatus = QueueStatus.joined;
        break;
      case 'WAITING':
      case 'PENDING':
        parsedStatus = QueueStatus.waiting;
        break;
      case 'APPROACHING':
        parsedStatus = QueueStatus.approaching;
        break;
      case 'CALLED':
        parsedStatus = QueueStatus.called;
        break;
      case 'SERVING':
      case 'IN_SERVICE':
        parsedStatus = QueueStatus.serving;
        break;
      case 'COMPLETED':
        parsedStatus = QueueStatus.completed;
        break;
      case 'CANCELLED':
        parsedStatus = QueueStatus.cancelled;
        break;
      case 'SKIPPED':
      case 'NO_SHOW':
      case 'MISSED':
        parsedStatus = QueueStatus.missed;
        break;
      case 'WAITLISTED':
        parsedStatus = QueueStatus.waitlisted;
        break;
      case 'EXPIRED':
        parsedStatus = QueueStatus.expired;
        break;
      default:
        parsedStatus = QueueStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == rawStatus.toLowerCase(),
          orElse: () => QueueStatus.waiting,
        );
    }

    final rawPriority = (map['priorityCategory'] ?? map['priority'] ?? '').toString().toUpperCase();
    PriorityType parsedPriority = PriorityType.standard;
    if (rawPriority.contains('SENIOR')) {
      parsedPriority = PriorityType.senior;
    } else if (rawPriority.contains('DISABILITY') || rawPriority.contains('PREGNANT') || rawPriority.contains('ACCESSIBILITY')) {
      parsedPriority = PriorityType.accessibility;
    } else if (rawPriority.contains('EMERGENCY') || rawPriority.contains('URGENT')) {
      parsedPriority = PriorityType.emergency;
    }

    final rawSource = (map['source'] ?? '').toString().toUpperCase();
    QueueSource parsedSource = QueueSource.mobileApp;
    if (rawSource.contains('QR')) {
      parsedSource = QueueSource.qrCode;
    } else if (rawSource.contains('WEB')) {
      parsedSource = QueueSource.website;
    } else if (rawSource.contains('KIOSK')) {
      parsedSource = QueueSource.kiosk;
    } else if (rawSource.contains('RECEPTION') || rawSource.contains('WALK_IN')) {
      parsedSource = QueueSource.receptionist;
    }

    final waitSecs = map['estimatedWaitSeconds'] ??
        ((map['estimatedWaitMinutes'] is num ? (map['estimatedWaitMinutes'] as num).toInt() : 5) * 60);

    final token = map['tokenNumber'] ?? 'A001';
    final tokenLetter = (map['tokenPrefix'] != null && map['tokenPrefix'].toString().isNotEmpty)
        ? map['tokenPrefix'].toString()
        : (token.isNotEmpty ? token[0] : 'A');

    return QueueEntryModel(
      id: id,
      customerId: resolvedCustId,
      guestReferenceHash: map['guestReferenceHash'],
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? 'Business Service',
      businessLogo: map['businessLogo'],
      branchId: map['branchId'] ?? '',
      branchName: map['branchName'] ?? 'Main Branch',
      branchAddress: map['branchAddress'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? 'Queue Service',
      queueId: map['queueId'] ?? map['serviceId'] ?? '',
      tokenNumber: token,
      tokenPrefix: tokenLetter,
      tokenSequence: (map['tokenSequence'] is num) ? (map['tokenSequence'] as num).toInt() : 1,
      status: parsedStatus,
      priority: parsedPriority,
      source: parsedSource,
      groupSize: (customerMap?['numberOfPeople'] ?? map['groupSize'] ?? 1) as int,
      beneficiaryId: map['beneficiaryId'],
      beneficiaryName: resolvedCustName,
      createdByUserId: map['createdByUserId'] ?? (resolvedCustId ?? ''),
      assignedCounterId: map['assignedCounterId'],
      assignedCounterNumber: map['counterName'] ?? map['assignedCounterNumber'],
      assignedCounterFloor: map['assignedCounterFloor'],
      assignedOperatorName: map['operatorName'] ?? map['assignedOperatorName'],
      joinedAt: DateFormatter.parseDateTime(map['joinedAt']),
      calledAt: DateFormatter.parseNullableDateTime(map['calledAt']),
      serviceStartedAt: DateFormatter.parseNullableDateTime(map['serviceStartedAt']),
      completedAt: DateFormatter.parseNullableDateTime(map['completedAt']),
      estimatedWaitSeconds: (waitSecs is num) ? waitSecs.toInt() : 300,
      customersAhead: (map['customersAhead'] is num) ? (map['customersAhead'] as num).toInt() : 0,
      verificationQrCode: map['verificationQrCode'] ?? 'EQ-$id',
      cancellationReason: map['cancellationReason'],
      isDelayNotified: map['isDelayNotified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    String apiStatus = 'WAITING';
    switch (status) {
      case QueueStatus.joined:
      case QueueStatus.waiting:
      case QueueStatus.approaching:
        apiStatus = 'WAITING';
        break;
      case QueueStatus.called:
        apiStatus = 'CALLED';
        break;
      case QueueStatus.serving:
        apiStatus = 'SERVING';
        break;
      case QueueStatus.completed:
        apiStatus = 'COMPLETED';
        break;
      case QueueStatus.cancelled:
        apiStatus = 'CANCELLED';
        break;
      case QueueStatus.missed:
        apiStatus = 'SKIPPED';
        break;
      case QueueStatus.waitlisted:
        apiStatus = 'WAITLISTED';
        break;
      case QueueStatus.expired:
        apiStatus = 'EXPIRED';
        break;
    }

    String priorityCat = 'NORMAL';
    switch (priority) {
      case PriorityType.senior:
        priorityCat = 'SENIOR_CITIZEN';
        break;
      case PriorityType.accessibility:
        priorityCat = 'DISABILITY';
        break;
      case PriorityType.emergency:
        priorityCat = 'EMERGENCY';
        break;
      case PriorityType.standard:
        priorityCat = 'NORMAL';
    }

    return {
      'id': id,
      'customerId': customerId,
      'guestReferenceHash': guestReferenceHash,
      'businessId': businessId,
      'businessName': businessName,
      'businessLogo': businessLogo,
      'branchId': branchId,
      'branchName': branchName,
      'branchAddress': branchAddress,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'queueId': queueId,
      'tokenNumber': tokenNumber,
      'tokenPrefix': tokenPrefix,
      'tokenSequence': tokenSequence,
      'status': apiStatus,
      'priority': priority.name,
      'priorityCategory': priorityCat,
      'priorityWeight': priority == PriorityType.emergency ? 10 : 1,
      'source': source.name,
      'groupSize': groupSize,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'createdByUserId': createdByUserId,
      'customer': {
        if (customerId != null) 'id': customerId,
        'name': beneficiaryName ?? 'Customer',
        'numberOfPeople': groupSize,
      },
      'assignedCounterId': assignedCounterId,
      'assignedCounterNumber': assignedCounterNumber,
      'counterName': assignedCounterNumber,
      'assignedCounterFloor': assignedCounterFloor,
      'assignedOperatorName': assignedOperatorName,
      'operatorName': assignedOperatorName,
      'joinedAt': joinedAt.toIso8601String(),
      'calledAt': calledAt?.toIso8601String(),
      'serviceStartedAt': serviceStartedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'estimatedWaitSeconds': estimatedWaitSeconds,
      'estimatedWaitMinutes': (estimatedWaitSeconds / 60).round(),
      'customersAhead': customersAhead,
      'verificationQrCode': verificationQrCode,
      'cancellationReason': cancellationReason,
      'isDelayNotified': isDelayNotified,
    };
  }

  QueueEntryModel copyWith({
    QueueStatus? status,
    String? assignedCounterId,
    String? assignedCounterNumber,
    String? assignedCounterFloor,
    String? assignedOperatorName,
    DateTime? calledAt,
    DateTime? serviceStartedAt,
    DateTime? completedAt,
    int? estimatedWaitSeconds,
    int? customersAhead,
    String? cancellationReason,
    bool? isDelayNotified,
    String? customerId,
  }) {
    return QueueEntryModel(
      id: id,
      customerId: customerId ?? this.customerId,
      guestReferenceHash: guestReferenceHash,
      businessId: businessId,
      businessName: businessName,
      businessLogo: businessLogo,
      branchId: branchId,
      branchName: branchName,
      branchAddress: branchAddress,
      serviceId: serviceId,
      serviceName: serviceName,
      queueId: queueId,
      tokenNumber: tokenNumber,
      tokenPrefix: tokenPrefix,
      tokenSequence: tokenSequence,
      status: status ?? this.status,
      priority: priority,
      source: source,
      groupSize: groupSize,
      beneficiaryId: beneficiaryId,
      beneficiaryName: beneficiaryName,
      createdByUserId: createdByUserId,
      assignedCounterId: assignedCounterId ?? this.assignedCounterId,
      assignedCounterNumber: assignedCounterNumber ?? this.assignedCounterNumber,
      assignedCounterFloor: assignedCounterFloor ?? this.assignedCounterFloor,
      assignedOperatorName: assignedOperatorName ?? this.assignedOperatorName,
      joinedAt: joinedAt,
      calledAt: calledAt ?? this.calledAt,
      serviceStartedAt: serviceStartedAt ?? this.serviceStartedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedWaitSeconds: estimatedWaitSeconds ?? this.estimatedWaitSeconds,
      customersAhead: customersAhead ?? this.customersAhead,
      verificationQrCode: verificationQrCode,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      isDelayNotified: isDelayNotified ?? this.isDelayNotified,
    );
  }
}
