import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../models/business_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';

class BusinessRepository {
  final FirebaseFirestore? _firestore;
  List<BusinessModel> _cachedBusinesses = [];
  final _businessesController = StreamController<List<BusinessModel>>.broadcast();
  StreamSubscription? _businessesSubscription;
  bool _initialized = false;

  BusinessRepository({
    FirebaseFirestore? firestore,
    List<BusinessModel>? initialBusinesses,
  })  : _firestore = firestore ?? _resolveFirestore(),
        _cachedBusinesses = initialBusinesses != null ? List.from(initialBusinesses) : [] {
    _initRepository();
  }

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('FirebaseFirestore not initialized in environment: $e');
      return null;
    }
  }

  Stream<List<BusinessModel>> get businessesStream => _businessesController.stream;
  List<BusinessModel> get cachedBusinesses => List.unmodifiable(_cachedBusinesses);

  Future<void> _initRepository() async {
    if (_initialized) return;
    _initialized = true;

    if (_firestore != null) {
      try {
        // Listen for real-time updates to active businesses
        _businessesSubscription = _firestore
            .collection('businesses')
            .where('status', isEqualTo: 'ACTIVE')
            .snapshots()
            .listen((snapshot) async {
          final loaded = await _parseBusinessDocuments(snapshot.docs);
          _cachedBusinesses = loaded;
          _businessesController.add(List.unmodifiable(_cachedBusinesses));
        }, onError: (e) {
          debugPrint('Business snapshot error: $e');
        });

        await getAllBusinesses();
      } catch (e) {
        debugPrint('Firestore business initialization note: $e');
        _businessesController.add(List.unmodifiable(_cachedBusinesses));
      }
    } else {
      _businessesController.add(List.unmodifiable(_cachedBusinesses));
    }
  }

  Future<List<BusinessModel>> getAllBusinesses() async {
    if (_firestore == null) {
      return _cachedBusinesses;
    }

    try {
      final snapshot = await _firestore
          .collection('businesses')
          .where('status', isEqualTo: 'ACTIVE')
          .get();

      _cachedBusinesses = await _parseBusinessDocuments(snapshot.docs);
      _businessesController.add(List.unmodifiable(_cachedBusinesses));
      return _cachedBusinesses;
    } catch (e) {
      debugPrint('Error getting businesses from Firestore: $e');
      return _cachedBusinesses;
    }
  }

  Future<List<BusinessModel>> _parseBusinessDocuments(
      List<DocumentSnapshot<Map<String, dynamic>>> docs) async {
    final List<BusinessModel> list = [];

    for (final doc in docs) {
      final data = doc.data() ?? <String, dynamic>{};
      List<BranchModel> branches = [];

      try {
        // Fetch branches from subcollection
        final branchesSnap = await doc.reference
            .collection('branches')
            .where('status', isEqualTo: 'ACTIVE')
            .get();

        for (final branchDoc in branchesSnap.docs) {
          final branchData = branchDoc.data();

          // Fetch services from subcollection
          final servicesSnap = await branchDoc.reference
              .collection('services')
              .where('status', isEqualTo: 'ACTIVE')
              .get();

          final services = servicesSnap.docs.map((sDoc) {
            return ServiceModel.fromMap(sDoc.data(), sDoc.id);
          }).toList();

          final branch = BranchModel.fromMap({
            ...branchData,
            'services': services.map((s) => s.toMap()).toList(),
          }, branchDoc.id);
          branches.add(branch);
        }
      } catch (e) {
        debugPrint('Error parsing branches for business ${doc.id}: $e');
      }

      // If document embedded branches directly
      if (branches.isEmpty && data['branches'] is List) {
        branches = (data['branches'] as List)
            .map((b) => BranchModel.fromMap(b as Map<String, dynamic>, b['id'] ?? ''))
            .toList();
      }

      list.add(BusinessModel.fromMap({
        ...data,
        'branches': branches.map((b) => b.toMap()).toList(),
      }, doc.id));
    }

    return list;
  }

  Future<List<BusinessModel>> getBusinessesByCategory(BusinessCategory category) async {
    final all = await getAllBusinesses();
    if (category == BusinessCategory.all) {
      return all;
    }
    return all.where((b) => b.category == category).toList();
  }

  Future<List<BusinessModel>> searchBusinesses({
    required String query,
    BusinessCategory? category,
    String? sortBy, // 'nearest', 'shortest_wait', 'highest_rated'
  }) async {
    final all = await getAllBusinesses();
    final lowerQuery = query.toLowerCase().trim();

    List<BusinessModel> results = all.where((b) {
      final matchesCategory = category == null ||
          category == BusinessCategory.all ||
          b.category == category;
      if (!matchesCategory) return false;

      if (lowerQuery.isEmpty) return true;

      final matchesName = b.name.toLowerCase().contains(lowerQuery);
      final matchesDescription = b.description.toLowerCase().contains(lowerQuery);
      final matchesBranches = b.branches.any((br) =>
          br.name.toLowerCase().contains(lowerQuery) ||
          br.address.toLowerCase().contains(lowerQuery) ||
          br.services.any((s) =>
              s.name.toLowerCase().contains(lowerQuery) ||
              s.description.toLowerCase().contains(lowerQuery)));

      return matchesName || matchesDescription || matchesBranches;
    }).toList();

    if (sortBy != null) {
      switch (sortBy) {
        case 'highest_rated':
          results.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'nearest':
          results.sort((a, b) {
            final distA = a.branches.isNotEmpty ? a.branches.first.distanceKm : 999.0;
            final distB = b.branches.isNotEmpty ? b.branches.first.distanceKm : 999.0;
            return distA.compareTo(distB);
          });
          break;
        case 'shortest_wait':
          results.sort((a, b) {
            final waitA = a.branches.isNotEmpty && a.branches.first.services.isNotEmpty
                ? a.branches.first.services.first.estimatedWaitMinutes
                : 9999;
            final waitB = b.branches.isNotEmpty && b.branches.first.services.isNotEmpty
                ? b.branches.first.services.first.estimatedWaitMinutes
                : 9999;
            return waitA.compareTo(waitB);
          });
          break;
      }
    }

    return results;
  }

  Future<BusinessModel?> getBusinessById(String businessId) async {
    final all = await getAllBusinesses();
    try {
      return all.firstWhere((b) => b.id == businessId);
    } catch (_) {}

    if (_firestore != null) {
      try {
        final doc = await _firestore.collection('businesses').doc(businessId).get();
        if (doc.exists) {
          final parsed = await _parseBusinessDocuments([doc]);
          return parsed.isNotEmpty ? parsed.first : null;
        }
      } catch (e) {
        debugPrint('Error getting business $businessId from Firestore: $e');
      }
    }

    return null;
  }

  Future<BranchModel?> getBranchById(String businessId, String branchId) async {
    final biz = await getBusinessById(businessId);
    if (biz == null) return null;
    try {
      return biz.branches.firstWhere((b) => b.id == branchId);
    } catch (_) {
      return null;
    }
  }

  Future<ServiceModel?> getServiceById(
    String businessId,
    String branchId,
    String serviceId,
  ) async {
    final branch = await getBranchById(businessId, branchId);
    if (branch == null) return null;
    try {
      return branch.services.firstWhere((s) => s.id == serviceId);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> resolveQrDestination(String qrData) async {
    final trimmed = qrData.trim();
    if (trimmed.isEmpty) return null;

    String? bizId;
    String? branchId;
    String? srvId;

    // 1. Check if it is a JSON payload
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          bizId = (decoded['biz'] ?? decoded['businessId'] ?? decoded['id'])?.toString();
          branchId = (decoded['branch'] ?? decoded['branchId'])?.toString();
          srvId = (decoded['srv'] ?? decoded['service'] ?? decoded['serviceId'])?.toString();
        }
      } catch (_) {}
    }

    // 2. Check if it is a URI (HTTP/HTTPS or Custom Scheme like eq:// or easyqueue://)
    if (bizId == null) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        // Query parameters
        bizId = uri.queryParameters['biz'] ??
            uri.queryParameters['businessId'] ??
            uri.queryParameters['business'] ??
            uri.queryParameters['b'];
        branchId = uri.queryParameters['branch'] ??
            uri.queryParameters['branchId'] ??
            uri.queryParameters['br'];
        srvId = uri.queryParameters['srv'] ??
            uri.queryParameters['service'] ??
            uri.queryParameters['serviceId'] ??
            uri.queryParameters['s'];

        // Path segments: e.g. /join/{bizId}/{branchId} or /businesses/{bizId}/branches/{branchId}
        final segments = uri.pathSegments;
        final joinIndex = segments.indexOf('join');
        if (joinIndex != -1 && segments.length > joinIndex + 1) {
          bizId ??= segments[joinIndex + 1];
          if (segments.length > joinIndex + 2) {
            branchId ??= segments[joinIndex + 2];
          }
        }
      }
    }

    // 3. Delimited text or direct identifier fallback (e.g. "biz_apollo" or "biz_apollo:br_apollo_main")
    if (bizId == null) {
      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        bizId = parts[0];
        if (parts.length > 1) branchId = parts[1];
        if (parts.length > 2) srvId = parts[2];
      } else if (trimmed.contains('|')) {
        final parts = trimmed.split('|');
        bizId = parts[0];
        if (parts.length > 1) branchId = parts[1];
        if (parts.length > 2) srvId = parts[2];
      } else if (trimmed.startsWith('biz_')) {
        bizId = trimmed;
      }
    }

    // 4. Resolve Business
    BusinessModel? biz;
    if (bizId != null && bizId.isNotEmpty) {
      biz = await getBusinessById(bizId);
    }

    final all = await getAllBusinesses();
    if (biz == null) {
      if (bizId != null) {
        biz = all.where((b) => b.id.toLowerCase() == bizId!.toLowerCase()).firstOrNull;
      }
      if (biz == null && branchId != null) {
        biz = all.where((b) => b.branches.any((br) => br.id == branchId)).firstOrNull;
      }
      // If the QR was a generic check-in and there are active businesses, fallback to primary
      if (biz == null && (bizId == null || bizId.isEmpty) && all.isNotEmpty) {
        biz = all.first;
      }
    }

    if (biz == null) {
      return null;
    }

    // 5. Resolve Branch
    BranchModel? branch;
    if (branchId != null && branchId.isNotEmpty) {
      branch = await getBranchById(biz.id, branchId);
    }
    branch ??= biz.branches.firstOrNull;
    branch ??= BranchModel(
      id: 'br_default',
      businessId: biz.id,
      name: '${biz.name} Main Branch',
      address: 'Main Location',
      latitude: 0.0,
      longitude: 0.0,
      openingHours: '9:00 AM - 6:00 PM',
      phoneNumber: '',
      services: const [],
    );

    // 6. Resolve Service
    ServiceModel? service;
    if (srvId != null && srvId.isNotEmpty) {
      service = await getServiceById(biz.id, branch.id, srvId);
    }
    service ??= branch.services.firstOrNull;
    service ??= ServiceModel(
      id: 'srv_general',
      businessId: biz.id,
      branchId: branch.id,
      name: 'General Queue',
      category: 'General',
      description: 'General service queue',
      estimatedMinutesPerCustomer: 10,
    );

    return {
      'business': biz,
      'branch': branch,
      'service': service,
    };
  }

  void dispose() {
    _businessesSubscription?.cancel();
    _businessesController.close();
  }
}
