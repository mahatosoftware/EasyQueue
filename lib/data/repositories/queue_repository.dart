import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../models/queue_entry_model.dart';
import '../models/review_model.dart';
import '../models/notification_model.dart';
import '../services/functions_service.dart';

class QueueRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final FunctionsService _functionsService;

  String? _currentUserId;
  bool _isGuest = false;

  final List<QueueEntryModel> _tickets = [];
  final List<ReviewModel> _reviews = [];
  final List<AppNotificationModel> _notifications = [];

  final _ticketsController = StreamController<List<QueueEntryModel>>.broadcast();
  final _activeTicketController = StreamController<QueueEntryModel?>.broadcast();
  final _notificationController = StreamController<List<AppNotificationModel>>.broadcast();

  StreamSubscription? _ticketsSubscription;
  StreamSubscription? _notificationsSubscription;
  Timer? _countdownTimer;

  QueueRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FunctionsService? functionsService,
    String? initialUserId,
    this._isGuest = false,
    bool enableAutoCountdown = true,
  })  : _firestore = firestore ?? _resolveFirestore(),
        _auth = auth ?? _resolveAuth(),
        _functionsService = functionsService ?? FunctionsService(),
        _currentUserId = initialUserId {
    _initUser();
    if (enableAutoCountdown) {
      _startAutoCountdown();
    }
  }

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAuth? _resolveAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  void _initUser() {
    final uid = _currentUserId ?? _auth?.currentUser?.uid;
    if (uid != null) {
      updateUser(uid, isGuest: _auth?.currentUser?.isAnonymous ?? _isGuest);
    }
  }

  void updateUser(String? userId, {bool isGuest = false}) {
    if (_currentUserId == userId && _isGuest == isGuest && _ticketsSubscription != null) {
      return;
    }
    _currentUserId = userId;
    _isGuest = isGuest;

    _ticketsSubscription?.cancel();
    _notificationsSubscription?.cancel();

    if (_firestore != null && userId != null && userId.isNotEmpty) {
      _listenToFirestoreTickets(userId);
      _listenToFirestoreNotifications(userId);
    }
  }

  void _listenToFirestoreTickets(String userId) {
    if (_firestore == null) return;

    try {
      // Listen to tickets owned by customer
      _ticketsSubscription = _firestore
          .collection('queueEntries')
          .where('customer.id', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        final List<QueueEntryModel> parsed = [];
        for (final doc in snapshot.docs) {
          try {
            parsed.add(QueueEntryModel.fromMap(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Error parsing queue entry ${doc.id}: $e');
          }
        }

        // Sort by joinedAt descending
        parsed.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));

        // Check for state changes to trigger notifications
        _detectStateTransitions(parsed);

        _tickets.clear();
        _tickets.addAll(parsed);
        _notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore queue entries listener notice: $e');
      });
    } catch (e) {
      debugPrint('Error setting up queue entries listener: $e');
    }
  }

  void _listenToFirestoreNotifications(String userId) {
    if (_firestore == null) return;

    try {
      _notificationsSubscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final List<AppNotificationModel> parsed = [];
        for (final doc in snapshot.docs) {
          try {
            parsed.add(AppNotificationModel.fromMap(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Error parsing notification ${doc.id}: $e');
          }
        }
        _notifications.clear();
        _notifications.addAll(parsed);
        _notificationController.add(List.unmodifiable(_notifications));
      }, onError: (e) {
        debugPrint('Firestore notifications listener notice: $e');
      });
    } catch (e) {
      debugPrint('Error setting up notifications listener: $e');
    }
  }

  void _detectStateTransitions(List<QueueEntryModel> newTickets) {
    for (final newTicket in newTickets) {
      final prevIndex = _tickets.indexWhere((t) => t.id == newTicket.id);
      if (prevIndex != -1) {
        final prev = _tickets[prevIndex];
        if (prev.status != newTicket.status) {
          if (newTicket.status == QueueStatus.called) {
            _addNotification(
              title: 'Now Serving: ${newTicket.tokenNumber}!',
              message: 'Please proceed immediately to ${newTicket.assignedCounterNumber ?? "Counter"}!',
              type: 'called',
              entryId: newTicket.id,
              businessId: newTicket.businessId,
            );
          } else if (newTicket.status == QueueStatus.approaching) {
            _addNotification(
              title: 'Approaching Turn • ${newTicket.tokenNumber}',
              message: 'You are next in line! Please make your way toward the counter area.',
              type: 'approaching_turn',
              entryId: newTicket.id,
              businessId: newTicket.businessId,
            );
          } else if (newTicket.status == QueueStatus.completed) {
            _addNotification(
              title: 'Service Completed',
              message: 'Thank you for visiting ${newTicket.businessName}. Please share your feedback!',
              type: 'completed',
              entryId: newTicket.id,
              businessId: newTicket.businessId,
            );
          }
        }
      }
    }
  }

  Stream<List<QueueEntryModel>> get ticketsStream => _ticketsController.stream;
  Stream<QueueEntryModel?> get activeTicketStream => _activeTicketController.stream;
  Stream<List<AppNotificationModel>> get notificationsStream => _notificationController.stream;

  List<QueueEntryModel> get allTickets => List.unmodifiable(_tickets);
  List<QueueEntryModel> get activeTickets =>
      _tickets.where((t) => t.isActive).toList();
  List<QueueEntryModel> get pastTickets =>
      _tickets.where((t) => !t.isActive).toList();
  QueueEntryModel? get primaryActiveTicket {
    final active = activeTickets;
    return active.isNotEmpty ? active.first : null;
  }

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);

  void _notifyListeners() {
    _ticketsController.add(List.unmodifiable(_tickets));
    _activeTicketController.add(primaryActiveTicket);
    _notificationController.add(List.unmodifiable(_notifications));
  }

  void _startAutoCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      bool changed = false;
      for (int i = 0; i < _tickets.length; i++) {
        final ticket = _tickets[i];
        if (ticket.isActive && ticket.estimatedWaitSeconds > 15) {
          _tickets[i] = ticket.copyWith(
            estimatedWaitSeconds: ticket.estimatedWaitSeconds - 15,
          );
          changed = true;
        }
      }
      if (changed) {
        _notifyListeners();
      }
    });
  }

  /// UC-025: Check for duplicate active entry in the same service queue
  bool hasActiveTicketForService(String serviceId, {String? beneficiaryId}) {
    return _tickets.any((t) =>
        t.isActive &&
        t.serviceId == serviceId &&
        t.beneficiaryId == beneficiaryId);
  }

  /// UC-015, UC-016, UC-021, UC-022, UC-023: Join Queue
  Future<QueueEntryModel> joinQueue({
    required String businessId,
    required String businessName,
    String? businessLogo,
    required String branchId,
    required String branchName,
    required String branchAddress,
    required String serviceId,
    required String serviceName,
    required String createdByUserId,
    String? customerId,
    int groupSize = 1,
    String? beneficiaryId,
    String? beneficiaryName,
    PriorityType priority = PriorityType.standard,
    QueueSource source = QueueSource.mobileApp,
    int baseWaitSeconds = 600,
  }) async {
    // Check duplicate
    if (hasActiveTicketForService(serviceId, beneficiaryId: beneficiaryId)) {
      final existing = _tickets.firstWhere((t) =>
          t.isActive &&
          t.serviceId == serviceId &&
          t.beneficiaryId == beneficiaryId);
      return existing;
    }

    final effectiveCustomerId = customerId ?? _currentUserId ?? createdByUserId;
    final customerDisplayName = beneficiaryName ?? 'Customer';

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
        break;
    }

    // 1. Try Cloud Function joinQueue first
    final fnResult = await _functionsService.joinQueue(
      businessId: businessId,
      branchId: branchId,
      serviceId: serviceId,
      customerName: customerDisplayName,
      numberOfPeople: groupSize,
      priorityCategory: priorityCat,
      source: 'MOBILE_APP',
    );

    if (fnResult != null && fnResult['entryId'] != null) {
      final entryId = fnResult['entryId'] as String;
      final tokenNumber = fnResult['tokenNumber'] as String? ?? 'A001';
      final pos = (fnResult['positionInQueue'] as num?)?.toInt() ?? 1;
      final estMins = (fnResult['estimatedWaitMinutes'] as num?)?.toInt() ?? 10;

      final entry = QueueEntryModel(
        id: entryId,
        customerId: effectiveCustomerId,
        businessId: businessId,
        businessName: businessName,
        businessLogo: businessLogo,
        branchId: branchId,
        branchName: branchName,
        branchAddress: branchAddress,
        serviceId: serviceId,
        serviceName: serviceName,
        queueId: serviceId,
        tokenNumber: tokenNumber,
        tokenPrefix: tokenNumber.isNotEmpty ? tokenNumber[0] : 'A',
        tokenSequence: pos,
        status: QueueStatus.waiting,
        priority: priority,
        source: source,
        groupSize: groupSize,
        beneficiaryId: beneficiaryId,
        beneficiaryName: beneficiaryName,
        createdByUserId: createdByUserId,
        joinedAt: DateTime.now(),
        estimatedWaitSeconds: estMins * 60,
        customersAhead: pos > 0 ? pos - 1 : 0,
        verificationQrCode: 'EQ-$tokenNumber',
      );

      _insertTicketLocally(entry);
      _addNotification(
        title: 'Queue Joined Successfully',
        message: 'Your token $tokenNumber for $serviceName is confirmed. Estimated wait: ~$estMins mins.',
        type: 'token_confirmed',
        entryId: entryId,
        businessId: businessId,
      );
      return entry;
    }

    // 2. Direct Firestore Transaction / Creation Fallback
    final entryId = 'entry_${const Uuid().v4().substring(0, 8)}';
    final tokenLetter = serviceName.isNotEmpty ? serviceName[0].toUpperCase() : 'A';
    int tokenSeq = 1;
    int currentWaiting = 0;

    if (_firestore != null) {
      try {
        final queueRef = _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('branches')
            .doc(branchId)
            .collection('queues')
            .doc(serviceId);

        final entryRef = _firestore.collection('queueEntries').doc(entryId);

        await _firestore.runTransaction((transaction) async {
          final queueSnap = await transaction.get(queueRef);
          if (queueSnap.exists) {
            final data = queueSnap.data() as Map<String, dynamic>;
            tokenSeq = ((data['lastTokenNumber'] ?? 0) as num).toInt() + 1;
            currentWaiting = ((data['waitingCount'] ?? 0) as num).toInt();
          } else {
            tokenSeq = 1;
            currentWaiting = 0;
          }

          final tokenNumber = '$tokenLetter${tokenSeq.toString().padLeft(3, '0')}';
          final estWaitSecs = (currentWaiting + 1) * 300;

          final newEntryMap = <String, dynamic>{
            'id': entryId,
            'businessId': businessId,
            'branchId': branchId,
            'serviceId': serviceId,
            'tokenNumber': tokenNumber,
            'status': 'WAITING',
            'customer': <String, dynamic>{
              if (effectiveCustomerId.isNotEmpty)
                'id': effectiveCustomerId,
              'name': customerDisplayName.isNotEmpty ? customerDisplayName : 'Customer',
              'numberOfPeople': groupSize,
            },
            'priorityCategory': priorityCat,
            'priorityWeight': priority == PriorityType.emergency ? 10 : 1,
            'joinedAt': FieldValue.serverTimestamp(),
            'estimatedWaitMinutes': (estWaitSecs / 60).round().clamp(1, 999),
            'recallCount': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          transaction.set(entryRef, newEntryMap);
          transaction.set(
            queueRef,
            {
              'id': serviceId,
              'businessId': businessId,
              'branchId': branchId,
              'serviceId': serviceId,
              'tokenPrefix': tokenLetter,
              'lastTokenNumber': tokenSeq,
              'waitingCount': FieldValue.increment(1),
              'status': 'OPEN',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        });

        final createdTokenNumber = '$tokenLetter${tokenSeq.toString().padLeft(3, '0')}';
        final localEntry = QueueEntryModel(
          id: entryId,
          customerId: effectiveCustomerId,
          businessId: businessId,
          businessName: businessName,
          businessLogo: businessLogo,
          branchId: branchId,
          branchName: branchName,
          branchAddress: branchAddress,
          serviceId: serviceId,
          serviceName: serviceName,
          queueId: serviceId,
          tokenNumber: createdTokenNumber,
          tokenPrefix: tokenLetter,
          tokenSequence: tokenSeq,
          status: QueueStatus.waiting,
          priority: priority,
          source: source,
          groupSize: groupSize,
          beneficiaryId: beneficiaryId,
          beneficiaryName: beneficiaryName,
          createdByUserId: createdByUserId,
          joinedAt: DateTime.now(),
          estimatedWaitSeconds: (currentWaiting + 1) * 300,
          customersAhead: currentWaiting,
          verificationQrCode: 'EQ-$createdTokenNumber',
        );

        _insertTicketLocally(localEntry);
        _addNotification(
          title: 'Queue Joined Successfully',
          message: 'Your token $createdTokenNumber for $serviceName is confirmed.',
          type: 'token_confirmed',
          entryId: entryId,
          businessId: businessId,
        );
        return localEntry;
      } catch (e) {
        debugPrint('Firestore joinQueue transaction error: $e');
      }
    }

    // 3. Offline In-memory Fallback
    final tokenSeqFallback = 20 + _tickets.length + 1;
    final tokenNumberFallback = '$tokenLetter${tokenSeqFallback.toString().padLeft(3, '0')}';
    final fallbackEntry = QueueEntryModel(
      id: entryId,
      customerId: effectiveCustomerId,
      businessId: businessId,
      businessName: businessName,
      businessLogo: businessLogo,
      branchId: branchId,
      branchName: branchName,
      branchAddress: branchAddress,
      serviceId: serviceId,
      serviceName: serviceName,
      queueId: serviceId,
      tokenNumber: tokenNumberFallback,
      tokenPrefix: tokenLetter,
      tokenSequence: tokenSeqFallback,
      status: QueueStatus.waiting,
      priority: priority,
      source: source,
      groupSize: groupSize,
      beneficiaryId: beneficiaryId,
      beneficiaryName: beneficiaryName,
      createdByUserId: createdByUserId,
      joinedAt: DateTime.now(),
      estimatedWaitSeconds: 300,
      customersAhead: 1,
      verificationQrCode: 'EQ-$tokenNumberFallback',
    );

    _insertTicketLocally(fallbackEntry);
    _addNotification(
      title: 'Queue Joined',
      message: 'Token $tokenNumberFallback for $serviceName has been generated.',
      type: 'token_confirmed',
      entryId: entryId,
      businessId: businessId,
    );
    return fallbackEntry;
  }

  void _insertTicketLocally(QueueEntryModel entry) {
    final idx = _tickets.indexWhere((t) => t.id == entry.id);
    if (idx != -1) {
      _tickets[idx] = entry;
    } else {
      _tickets.insert(0, entry);
    }
    _notifyListeners();
  }

  /// UC-038: Cancel ticket by customer
  Future<bool> cancelTicket(String entryId, {String? reason}) async {
    final index = _tickets.indexWhere((t) => t.id == entryId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(
        status: QueueStatus.cancelled,
        cancellationReason: reason ?? 'Cancelled by customer',
      );
      _notifyListeners();
    }

    if (_firestore != null) {
      try {
        await _firestore.collection('queueEntries').doc(entryId).update({
          'status': 'CANCELLED',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': reason ?? 'Cancelled by customer',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      } catch (e) {
        debugPrint('Firestore ticket cancellation note: $e');
      }
    }

    return true;
  }

  /// UC-068: Submit Feedback / Review
  Future<void> submitFeedback({
    required String customerId,
    required String customerName,
    required String businessId,
    required String branchId,
    required String serviceId,
    required String entryId,
    required double rating,
    double? waitTimeRating,
    double? staffRating,
    required String comment,
  }) async {
    final reviewId = 'rev_${const Uuid().v4().substring(0, 8)}';
    final review = ReviewModel(
      id: reviewId,
      customerId: customerId,
      customerName: customerName,
      businessId: businessId,
      branchId: branchId,
      serviceId: serviceId,
      entryId: entryId,
      rating: rating,
      waitTimeRating: waitTimeRating,
      staffRating: staffRating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    _reviews.add(review);

    if (_firestore != null) {
      try {
        await _firestore.collection('reviews').doc(reviewId).set({
          'id': reviewId,
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
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore submitFeedback note: $e');
      }
    }
  }

  void _addNotification({
    required String title,
    required String message,
    required String type,
    String? entryId,
    String? businessId,
  }) {
    final notifId = 'notif_${const Uuid().v4().substring(0, 8)}';
    final notif = AppNotificationModel(
      id: notifId,
      title: title,
      message: message,
      type: type,
      entryId: entryId,
      businessId: businessId,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notif);
    _notificationController.add(List.unmodifiable(_notifications));

    if (_firestore != null && _currentUserId != null && _currentUserId!.isNotEmpty) {
      try {
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(notifId)
            .set({
          'id': notifId,
          'title': title,
          'message': message,
          'type': type,
          'entryId': entryId,
          'businessId': businessId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore notification persist note: $e');
      }
    }
  }

  void markNotificationAsRead(String notifId) {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1) {
      final notif = _notifications[index];
      _notifications[index] = AppNotificationModel(
        id: notif.id,
        title: notif.title,
        message: notif.message,
        type: notif.type,
        entryId: notif.entryId,
        businessId: notif.businessId,
        readAt: DateTime.now(),
        createdAt: notif.createdAt,
      );
      _notificationController.add(List.unmodifiable(_notifications));

      if (_firestore != null && _currentUserId != null) {
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(notifId)
            .update({
          'readAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }
    }
  }

  /// Advances the queue state for preview and testing interactions
  void simulateNextQueueEvent(String entryId) {
    final index = _tickets.indexWhere((t) => t.id == entryId);
    if (index == -1) return;

    final current = _tickets[index];
    switch (current.status) {
      case QueueStatus.waiting:
        if (current.customersAhead > 1) {
          _tickets[index] = current.copyWith(
            customersAhead: current.customersAhead - 1,
            estimatedWaitSeconds: (current.customersAhead - 1) * 300,
          );
        } else {
          _tickets[index] = current.copyWith(
            status: QueueStatus.approaching,
            customersAhead: 0,
            estimatedWaitSeconds: 120,
          );
          _addNotification(
            title: 'Approaching Turn • ${current.tokenNumber}',
            message: 'You are next in line! Please make your way toward the counter area.',
            type: 'approaching_turn',
            entryId: entryId,
            businessId: current.businessId,
          );
        }
        break;

      case QueueStatus.approaching:
        _tickets[index] = current.copyWith(
          status: QueueStatus.called,
          assignedCounterId: 'cntr_3',
          assignedCounterNumber: 'Counter 3',
          assignedCounterFloor: '1st Floor, Room 102',
          assignedOperatorName: 'Dr. Sharma',
          calledAt: DateTime.now(),
          estimatedWaitSeconds: 0,
        );
        _addNotification(
          title: 'Now Serving: ${current.tokenNumber}!',
          message: 'Please proceed immediately to Counter 3 (1st Floor, Room 102).',
          type: 'called',
          entryId: entryId,
          businessId: current.businessId,
        );
        break;

      case QueueStatus.called:
        _tickets[index] = current.copyWith(
          status: QueueStatus.serving,
          serviceStartedAt: DateTime.now(),
        );
        break;

      case QueueStatus.serving:
        _tickets[index] = current.copyWith(
          status: QueueStatus.completed,
          completedAt: DateTime.now(),
        );
        _addNotification(
          title: 'Service Completed',
          message: 'Thank you for visiting ${current.businessName}. Please share your feedback!',
          type: 'completed',
          entryId: entryId,
          businessId: current.businessId,
        );
        break;

      default:
        break;
    }

    _notifyListeners();
  }

  void dispose() {
    _countdownTimer?.cancel();
    _ticketsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _ticketsController.close();
    _activeTicketController.close();
    _notificationController.close();
  }
}
