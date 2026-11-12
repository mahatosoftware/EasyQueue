import 'package:flutter/foundation.dart';
import 'package:easyqueue/data/models/family_member_model.dart';
import 'package:easyqueue/data/repositories/family_repository.dart';

class FamilyViewModel extends ChangeNotifier {
  final FamilyRepository _familyRepository;

  List<FamilyMemberModel> _familyMembers = [];
  bool _isLoading = false;

  FamilyViewModel({required this._familyRepository}) {
    _familyMembers = _familyRepository.familyMembers;
    _familyRepository.familyMembersStream.listen((members) {
      _familyMembers = members;
      notifyListeners();
    });
  }

  List<FamilyMemberModel> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;

  Future<FamilyMemberModel> addFamilyMember({
    required String name,
    required String relationship,
    String? dateOfBirth,
    String? phoneNumber,
    String? accessibilityRequirements,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final member = await _familyRepository.addFamilyMember(
        name: name,
        relationship: relationship,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        accessibilityRequirements: accessibilityRequirements,
      );
      return member;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFamilyMember(String memberId) async {
    await _familyRepository.removeFamilyMember(memberId);
  }
}
