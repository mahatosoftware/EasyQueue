import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member_model.dart';

class FamilyRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  String? _currentUserId;
  final List<FamilyMemberModel> _familyMembers = [];
  final _familyController = StreamController<List<FamilyMemberModel>>.broadcast();
  StreamSubscription? _familySubscription;

  FamilyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? initialUserId,
  })  : _firestore = firestore ?? _resolveFirestore(),
        _auth = auth ?? _resolveAuth(),
        _currentUserId = initialUserId {
    _initUser();
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
      updateUser(uid);
    }
  }

  void updateUser(String? userId) {
    if (_currentUserId == userId && _familySubscription != null) {
      return;
    }
    _currentUserId = userId;
    _familySubscription?.cancel();

    if (_firestore != null && userId != null && userId.isNotEmpty) {
      _listenToFirestoreFamily(userId);
    }
  }

  void _listenToFirestoreFamily(String userId) {
    if (_firestore == null) return;

    try {
      _familySubscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('familyMembers')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final List<FamilyMemberModel> list = [];
        for (final doc in snapshot.docs) {
          try {
            list.add(FamilyMemberModel.fromMap(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Error parsing family member ${doc.id}: $e');
          }
        }
        _familyMembers.clear();
        _familyMembers.addAll(list);
        _notify();
      }, onError: (e) {
        debugPrint('Firestore family members listener error: $e');
      });
    } catch (e) {
      debugPrint('Error setting up family members listener: $e');
    }
  }

  Stream<List<FamilyMemberModel>> get familyMembersStream => _familyController.stream;
  List<FamilyMemberModel> get familyMembers => List.unmodifiable(_familyMembers);

  void _notify() {
    _familyController.add(List.unmodifiable(_familyMembers));
  }

  Future<FamilyMemberModel> addFamilyMember({
    required String name,
    required String relationship,
    String? dateOfBirth,
    String? phoneNumber,
    String? accessibilityRequirements,
  }) async {
    final memberId = 'fam_${const Uuid().v4().substring(0, 8)}';
    final member = FamilyMemberModel(
      id: memberId,
      name: name,
      relationship: relationship,
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber,
      accessibilityRequirements: accessibilityRequirements,
      createdAt: DateTime.now(),
    );

    _familyMembers.add(member);
    _notify();

    if (_firestore != null && _currentUserId != null && _currentUserId!.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('familyMembers')
            .doc(memberId)
            .set({
          'id': memberId,
          'name': name,
          'relationship': relationship,
          'dateOfBirth': dateOfBirth,
          'phoneNumber': phoneNumber,
          'accessibilityRequirements': accessibilityRequirements,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore addFamilyMember error: $e');
      }
    }

    return member;
  }

  Future<void> removeFamilyMember(String memberId) async {
    _familyMembers.removeWhere((m) => m.id == memberId);
    _notify();

    if (_firestore != null && _currentUserId != null && _currentUserId!.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('familyMembers')
            .doc(memberId)
            .delete();
      } catch (e) {
        debugPrint('Firestore removeFamilyMember error: $e');
      }
    }
  }

  void dispose() {
    _familySubscription?.cancel();
    _familyController.close();
  }
}
