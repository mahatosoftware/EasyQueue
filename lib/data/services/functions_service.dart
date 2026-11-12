import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class FunctionsService {
  final FirebaseFunctions? _functions;

  FunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? _resolveFunctions();

  static FirebaseFunctions? _resolveFunctions() {
    try {
      return FirebaseFunctions.instance;
    } catch (e) {
      debugPrint('FirebaseFunctions not initialized in this environment: $e');
      return null;
    }
  }

  bool get isAvailable => _functions != null;

  /// Calls Cloud Function `joinQueue`
  Future<Map<String, dynamic>?> joinQueue({
    required String businessId,
    required String branchId,
    required String serviceId,
    required String customerName,
    String? phoneNumber,
    int numberOfPeople = 1,
    String priorityCategory = 'NORMAL',
    String source = 'MOBILE_APP',
    String? notes,
    String? deviceToken,
  }) async {
    if (_functions == null) return null;
    try {
      final callable = _functions.httpsCallable('joinQueue');
      final response = await callable.call({
        'businessId': businessId,
        'branchId': branchId,
        'serviceId': serviceId,
        'customerName': customerName,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
        'numberOfPeople': numberOfPeople,
        'priorityCategory': priorityCategory,
        'source': source,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (deviceToken != null && deviceToken.isNotEmpty) 'deviceToken': deviceToken,
      });

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Cloud Functions joinQueue notice: $e');
      return null;
    }
  }
}
