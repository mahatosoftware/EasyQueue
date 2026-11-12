import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment_model.dart';
import 'queue_repository.dart';

class AppointmentRepository {
  final QueueRepository _queueRepository;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  String? _currentUserId;
  final List<AppointmentModel> _appointments = [];
  final _appointmentsController = StreamController<List<AppointmentModel>>.broadcast();
  StreamSubscription? _appointmentsSubscription;

  AppointmentRepository({
    required this._queueRepository,
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
    if (_currentUserId == userId && _appointmentsSubscription != null) {
      return;
    }
    _currentUserId = userId;
    _appointmentsSubscription?.cancel();

    if (_firestore != null && userId != null && userId.isNotEmpty) {
      _listenToFirestoreAppointments(userId);
    }
  }

  void _listenToFirestoreAppointments(String userId) {
    if (_firestore == null) return;

    try {
      _appointmentsSubscription = _firestore
          .collection('appointments')
          .where('customerId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        final List<AppointmentModel> list = [];
        for (final doc in snapshot.docs) {
          try {
            list.add(AppointmentModel.fromMap(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Error parsing appointment ${doc.id}: $e');
          }
        }

        // Sort by appointment time
        list.sort((a, b) => b.appointmentTime.compareTo(a.appointmentTime));

        _appointments.clear();
        _appointments.addAll(list);
        _notify();
      }, onError: (e) {
        debugPrint('Firestore appointments listener error: $e');
      });
    } catch (e) {
      debugPrint('Error setting up appointments listener: $e');
    }
  }

  Stream<List<AppointmentModel>> get appointmentsStream => _appointmentsController.stream;
  List<AppointmentModel> get allAppointments => List.unmodifiable(_appointments);
  List<AppointmentModel> get upcomingAppointments =>
      _appointments.where((a) => a.isUpcoming).toList();
  List<AppointmentModel> get pastAppointments =>
      _appointments.where((a) => !a.isUpcoming).toList();

  void _notify() {
    _appointmentsController.add(List.unmodifiable(_appointments));
  }

  Future<AppointmentModel> bookAppointment({
    required String customerId,
    required String businessId,
    required String businessName,
    String? businessLogo,
    required String branchId,
    required String branchName,
    required String branchAddress,
    required String serviceId,
    required String serviceName,
    required DateTime appointmentTime,
    String? beneficiaryId,
    String? beneficiaryName,
    String? preparationNotes,
  }) async {
    final aptId = 'apt_${const Uuid().v4().substring(0, 8)}';
    final appointment = AppointmentModel(
      id: aptId,
      customerId: customerId,
      businessId: businessId,
      businessName: businessName,
      businessLogo: businessLogo,
      branchId: branchId,
      branchName: branchName,
      branchAddress: branchAddress,
      serviceId: serviceId,
      serviceName: serviceName,
      slotId: 'slot_${appointmentTime.millisecondsSinceEpoch}',
      beneficiaryId: beneficiaryId,
      beneficiaryName: beneficiaryName,
      appointmentTime: appointmentTime,
      status: 'confirmed',
      preparationNotes: preparationNotes,
      createdAt: DateTime.now(),
    );

    _appointments.insert(0, appointment);
    _notify();

    if (_firestore != null) {
      try {
        await _firestore.collection('appointments').doc(aptId).set({
          'id': aptId,
          'customerId': customerId,
          'customerName': (beneficiaryName != null && beneficiaryName.isNotEmpty) ? beneficiaryName : 'Customer',
          'businessId': businessId,
          'branchId': branchId,
          'serviceId': serviceId,
          'serviceName': serviceName,
          'appointmentTime': Timestamp.fromDate(appointmentTime),
          'scheduledTime': Timestamp.fromDate(appointmentTime),
          'status': 'SCHEDULED',
          if (preparationNotes != null && preparationNotes.isNotEmpty)
            'notes': preparationNotes,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore bookAppointment note: $e');
      }
    }

    return appointment;
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: 'cancelled');
      _notify();
    }

    if (_firestore != null) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'CANCELLED',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      } catch (e) {
        debugPrint('Firestore cancelAppointment note: $e');
      }
    }

    return true;
  }

  /// UC-050: Check-in appointment upon arrival -> Converts to live queue entry
  Future<String?> checkInAppointment(String appointmentId) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return null;

    final apt = _appointments[index];
    final queueEntry = await _queueRepository.joinQueue(
      businessId: apt.businessId,
      businessName: apt.businessName,
      businessLogo: apt.businessLogo,
      branchId: apt.branchId,
      branchName: apt.branchName,
      branchAddress: apt.branchAddress,
      serviceId: apt.serviceId,
      serviceName: apt.serviceName,
      createdByUserId: apt.customerId,
      customerId: apt.customerId,
      beneficiaryId: apt.beneficiaryId,
      beneficiaryName: apt.beneficiaryName,
    );

    _appointments[index] = apt.copyWith(
      status: 'checked_in',
      checkedInAt: DateTime.now(),
      associatedQueueEntryId: queueEntry.id,
    );
    _notify();

    if (_firestore != null) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'CHECKED_IN',
          'checkedInAt': FieldValue.serverTimestamp(),
          'associatedQueueEntryId': queueEntry.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore checkInAppointment note: $e');
      }
    }

    return queueEntry.id;
  }

  void dispose() {
    _appointmentsSubscription?.cancel();
    _appointmentsController.close();
  }
}
