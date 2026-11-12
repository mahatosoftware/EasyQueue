import 'package:flutter/foundation.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/data/models/business_model.dart';
import 'package:easyqueue/data/models/queue_entry_model.dart';
import 'package:easyqueue/data/models/notification_model.dart';
import 'package:easyqueue/data/repositories/business_repository.dart';
import 'package:easyqueue/data/repositories/queue_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final BusinessRepository _businessRepository;
  final QueueRepository _queueRepository;

  List<BusinessModel> _nearbyBusinesses = [];
  List<QueueEntryModel> _activeTickets = [];
  List<AppNotificationModel> _notifications = [];
  BusinessCategory _selectedCategory = BusinessCategory.all;
  bool _isLoading = false;

  HomeViewModel({
    required this._businessRepository,
    required this._queueRepository,
  }) {
    _activeTickets = _queueRepository.activeTickets;
    _notifications = _queueRepository.notifications;

    _queueRepository.ticketsStream.listen((tickets) {
      _activeTickets = tickets.where((t) => t.isActive).toList();
      notifyListeners();
    });

    _queueRepository.notificationsStream.listen((notifs) {
      _notifications = notifs;
      notifyListeners();
    });

    loadData();
  }

  List<BusinessModel> get nearbyBusinesses => _nearbyBusinesses;
  List<QueueEntryModel> get activeTickets => _activeTickets;
  QueueEntryModel? get primaryActiveTicket => _activeTickets.isNotEmpty ? _activeTickets.first : null;
  List<AppNotificationModel> get notifications => _notifications;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  BusinessCategory get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _nearbyBusinesses = await _businessRepository.getBusinessesByCategory(_selectedCategory);

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(BusinessCategory category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    _nearbyBusinesses = await _businessRepository.getBusinessesByCategory(_selectedCategory);
    notifyListeners();
  }
}
