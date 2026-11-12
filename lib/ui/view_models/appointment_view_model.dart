import 'package:flutter/foundation.dart';
import 'package:easyqueue/data/models/appointment_model.dart';
import 'package:easyqueue/data/repositories/appointment_repository.dart';

class AppointmentViewModel extends ChangeNotifier {
  final AppointmentRepository _appointmentRepository;

  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  bool _isLoading = false;

  AppointmentViewModel({required this._appointmentRepository}) {
    _refresh();
    _appointmentRepository.appointmentsStream.listen((_) {
      _refresh();
    });
  }

  List<AppointmentModel> get allAppointments => _allAppointments;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  List<AppointmentModel> get pastAppointments => _pastAppointments;
  bool get isLoading => _isLoading;

  void _refresh() {
    _allAppointments = _appointmentRepository.allAppointments;
    _upcomingAppointments = _appointmentRepository.upcomingAppointments;
    _pastAppointments = _appointmentRepository.pastAppointments;
    notifyListeners();
  }

  Future<AppointmentModel?> bookAppointment({
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
    _isLoading = true;
    notifyListeners();

    try {
      final apt = await _appointmentRepository.bookAppointment(
        customerId: customerId,
        businessId: businessId,
        businessName: businessName,
        businessLogo: businessLogo,
        branchId: branchId,
        branchName: branchName,
        branchAddress: branchAddress,
        serviceId: serviceId,
        serviceName: serviceName,
        appointmentTime: appointmentTime,
        beneficiaryId: beneficiaryId,
        beneficiaryName: beneficiaryName,
        preparationNotes: preparationNotes,
      );
      _refresh();
      return apt;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    _isLoading = true;
    notifyListeners();
    final res = await _appointmentRepository.cancelAppointment(appointmentId);
    _isLoading = false;
    _refresh();
    return res;
  }

  Future<String?> checkInAppointment(String appointmentId) async {
    _isLoading = true;
    notifyListeners();
    final entryId = await _appointmentRepository.checkInAppointment(appointmentId);
    _isLoading = false;
    _refresh();
    return entryId;
  }
}
