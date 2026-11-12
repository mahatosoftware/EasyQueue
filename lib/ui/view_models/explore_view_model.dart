import 'package:flutter/foundation.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/data/models/business_model.dart';
import 'package:easyqueue/data/repositories/business_repository.dart';

class ExploreViewModel extends ChangeNotifier {
  final BusinessRepository _businessRepository;

  List<BusinessModel> _searchResults = [];
  String _searchQuery = '';
  BusinessCategory _selectedCategory = BusinessCategory.all;
  String _sortBy = 'nearest'; // 'nearest', 'shortest_wait', 'highest_rated'
  bool _isLoading = false;

  ExploreViewModel({required this._businessRepository}) {
    search();
  }

  List<BusinessModel> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  BusinessCategory get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get isLoading => _isLoading;

  Future<void> search({String? query}) async {
    if (query != null) {
      _searchQuery = query;
    }

    _isLoading = true;
    notifyListeners();

    _searchResults = await _businessRepository.searchBusinesses(
      query: _searchQuery,
      category: _selectedCategory,
      sortBy: _sortBy,
    );

    _isLoading = false;
    notifyListeners();
  }

  void updateCategory(BusinessCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    search();
  }

  void updateSort(String sortBy) {
    if (_sortBy == sortBy) return;
    _sortBy = sortBy;
    search();
  }

  Future<Map<String, dynamic>?> resolveQrCode(String qrData) async {
    return await _businessRepository.resolveQrDestination(qrData);
  }
}
