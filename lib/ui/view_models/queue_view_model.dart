import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/data/models/queue_entry_model.dart';
import 'package:easyqueue/data/models/user_model.dart';
import 'package:easyqueue/data/models/family_member_model.dart';
import 'package:easyqueue/data/repositories/queue_repository.dart';

class QueueViewModel extends ChangeNotifier {
  final QueueRepository _queueRepository;

  List<QueueEntryModel> _allTickets = [];
  List<QueueEntryModel> _activeTickets = [];
  List<QueueEntryModel> _pastTickets = [];
  QueueEntryModel? _primaryActiveTicket;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  StreamSubscription? _subscription;

  QueueViewModel({required this._queueRepository}) {
    _refreshTickets();
    _subscription = _queueRepository.ticketsStream.listen((_) {
      _refreshTickets();
    });
  }

  List<QueueEntryModel> get allTickets => _allTickets;
  List<QueueEntryModel> get activeTickets => _activeTickets;
  List<QueueEntryModel> get pastTickets => _pastTickets;
  QueueEntryModel? get primaryActiveTicket => _primaryActiveTicket;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _refreshTickets() {
    if (_disposed) return;
    _allTickets = _queueRepository.allTickets;
    _activeTickets = _queueRepository.activeTickets;
    _pastTickets = _queueRepository.pastTickets;
    _primaryActiveTicket = _queueRepository.primaryActiveTicket;
    notifyListeners();
  }

  QueueEntryModel? getTicketById(String entryId) {
    try {
      return _allTickets.firstWhere((t) => t.id == entryId);
    } catch (_) {
      return null;
    }
  }

  Future<QueueEntryModel?> joinQueue({
    required String businessId,
    required String businessName,
    String? businessLogo,
    required String branchId,
    required String branchName,
    required String branchAddress,
    required String serviceId,
    required String serviceName,
    required UserModel currentUser,
    int groupSize = 1,
    FamilyMemberModel? beneficiary,
    PriorityType priority = PriorityType.standard,
    QueueSource source = QueueSource.mobileApp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _queueRepository.joinQueue(
        businessId: businessId,
        businessName: businessName,
        businessLogo: businessLogo,
        branchId: branchId,
        branchName: branchName,
        branchAddress: branchAddress,
        serviceId: serviceId,
        serviceName: serviceName,
        createdByUserId: currentUser.id,
        customerId: currentUser.isGuest ? null : currentUser.id,
        groupSize: groupSize,
        beneficiaryId: beneficiary?.id,
        beneficiaryName: beneficiary?.name,
        priority: priority,
        source: source,
      );

      _refreshTickets();
      return ticket;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelTicket(String entryId, {String? reason}) async {
    _isLoading = true;
    notifyListeners();

    final success = await _queueRepository.cancelTicket(entryId, reason: reason);
    _isLoading = false;
    _refreshTickets();
    return success;
  }

  /// Testing Helper: triggers state transitions for unit and widget tests
  @visibleForTesting
  void simulateNextState(String entryId) {
    _queueRepository.simulateNextQueueEvent(entryId);
    _refreshTickets();
  }

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
    await _queueRepository.submitFeedback(
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
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
