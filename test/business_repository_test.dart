import 'package:flutter_test/flutter_test.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/data/models/business_model.dart';
import 'package:easyqueue/data/models/branch_model.dart';
import 'package:easyqueue/data/models/service_model.dart';
import 'package:easyqueue/data/repositories/business_repository.dart';

void main() {
  group('BusinessRepository Tests', () {
    late BusinessRepository repository;

    setUp(() {
      repository = BusinessRepository(initialBusinesses: _getTestBusinesses());
    });

    test('Fetch all businesses returns seeded industry providers', () async {
      final list = await repository.getAllBusinesses();
      expect(list.isNotEmpty, true);
      expect(list.any((b) => b.category == BusinessCategory.hospital), true);
      expect(list.any((b) => b.category == BusinessCategory.diagnostic), true);
      expect(list.any((b) => b.category == BusinessCategory.bank), true);
    });

    test('Filter by category returns matching businesses', () async {
      final clinics = await repository.getBusinessesByCategory(BusinessCategory.hospital);
      expect(clinics.every((b) => b.category == BusinessCategory.hospital), true);

      final banks = await repository.getBusinessesByCategory(BusinessCategory.bank);
      expect(banks.every((b) => b.category == BusinessCategory.bank), true);
    });

    test('Search query matches business name, service name, and branch address', () async {
      final bloodTestResults = await repository.searchBusinesses(query: 'Blood Test');
      expect(bloodTestResults.isNotEmpty, true);
      expect(bloodTestResults.first.name, contains('City Diagnostics'));

      final salonResults = await repository.searchBusinesses(query: 'Haircut');
      expect(salonResults.isNotEmpty, true);
      expect(salonResults.first.name, contains('Salon Luxe'));
    });

    test('QR Code destination resolution parses deep link', () async {
      const qrLink = 'eq://join?biz=biz_metro_bank&branch=br_bank_fin&srv=srv_teller';
      final resolved = await repository.resolveQrDestination(qrLink);

      expect(resolved, isNotNull);
      expect(resolved!['business'].id, 'biz_metro_bank');
      expect(resolved['branch'].id, 'br_bank_fin');
      expect(resolved['service'].id, 'srv_teller');
    });

    test('QR Code destination resolution parses EasyQueueBusiness poster URLs', () async {
      // 1. Service Poster URL
      const servicePosterUrl = 'https://easyqueue.in/join/biz_apollo/br_apollo_main?service=srv_gen_med';
      final res1 = await repository.resolveQrDestination(servicePosterUrl);
      expect(res1, isNotNull);
      expect(res1!['business'].id, 'biz_apollo');
      expect(res1['branch'].id, 'br_apollo_main');
      expect(res1['service'].id, 'srv_gen_med');

      // 2. Branch Poster URL (auto-selects first service)
      const branchPosterUrl = 'https://easyqueue.in/join/biz_apollo/br_apollo_main';
      final res2 = await repository.resolveQrDestination(branchPosterUrl);
      expect(res2, isNotNull);
      expect(res2!['business'].id, 'biz_apollo');
      expect(res2['branch'].id, 'br_apollo_main');
      expect(res2['service'], isNotNull);

      // 3. Direct ID lookup
      final res3 = await repository.resolveQrDestination('biz_apollo');
      expect(res3, isNotNull);
      expect(res3!['business'].id, 'biz_apollo');

      // 4. JSON payload
      final res4 = await repository.resolveQrDestination('{"biz":"biz_city_diag","branch":"br_diag_central","srv":"srv_blood_test"}');
      expect(res4, isNotNull);
      expect(res4!['business'].id, 'biz_city_diag');
      expect(res4['service'].id, 'srv_blood_test');
    });
  });
}

List<BusinessModel> _getTestBusinesses() {
  return [
    BusinessModel(
      id: 'biz_apollo',
      name: 'Apollo Specialty Clinic',
      logoUrl: '',
      category: BusinessCategory.hospital,
      description: 'Multi-specialty outpatient care.',
      rating: 4.9,
      reviewCount: 342,
      isVerified: true,
      branches: [
        BranchModel(
          id: 'br_apollo_main',
          businessId: 'biz_apollo',
          name: 'Downtown Medical Center',
          address: '452 Healthcare Ave, Suite 100',
          latitude: 37.7749,
          longitude: -122.4194,
          distanceKm: 1.4,
          openingHours: '8:00 AM - 8:00 PM',
          phoneNumber: '+1-555-0101',
          activeQueuesCount: 3,
          totalCounters: 6,
          services: [
            ServiceModel(
              id: 'srv_gen_med',
              businessId: 'biz_apollo',
              branchId: 'br_apollo_main',
              name: 'General Medicine & Consultation',
              category: 'Consultation',
              description: 'Routine physician consultation.',
              estimatedMinutesPerCustomer: 12,
              currentWaitingCount: 0,
            ),
          ],
        ),
      ],
    ),
    BusinessModel(
      id: 'biz_city_diag',
      name: 'City Diagnostics & Labs',
      logoUrl: '',
      category: BusinessCategory.diagnostic,
      description: 'Accredited clinical laboratory.',
      rating: 4.8,
      reviewCount: 215,
      branches: [
        BranchModel(
          id: 'br_diag_central',
          businessId: 'biz_city_diag',
          name: 'Central Diagnostic Center',
          address: '89 Science Park Blvd',
          latitude: 37.7833,
          longitude: -122.4167,
          distanceKm: 2.1,
          openingHours: '7:00 AM - 6:00 PM',
          phoneNumber: '+1-555-0102',
          services: [
            ServiceModel(
              id: 'srv_blood_test',
              businessId: 'biz_city_diag',
              branchId: 'br_diag_central',
              name: 'Complete Blood Test & Lipid Panel',
              category: 'Pathology',
              description: 'Fasting blood draw.',
              estimatedMinutesPerCustomer: 6,
            ),
          ],
        ),
      ],
    ),
    BusinessModel(
      id: 'biz_metro_bank',
      name: 'Metro Global Bank',
      logoUrl: '',
      category: BusinessCategory.bank,
      description: 'Retail and commercial banking.',
      rating: 4.7,
      reviewCount: 520,
      branches: [
        BranchModel(
          id: 'br_bank_fin',
          businessId: 'biz_metro_bank',
          name: 'Financial District Branch',
          address: '100 Financial Way',
          latitude: 37.7915,
          longitude: -122.3980,
          distanceKm: 3.2,
          openingHours: '9:00 AM - 5:00 PM',
          phoneNumber: '+1-555-0103',
          services: [
            ServiceModel(
              id: 'srv_teller',
              businessId: 'biz_metro_bank',
              branchId: 'br_bank_fin',
              name: 'Cash Deposit & Withdrawal Teller',
              category: 'Cashier',
              description: 'Cash deposits.',
              estimatedMinutesPerCustomer: 5,
            ),
          ],
        ),
      ],
    ),
    BusinessModel(
      id: 'biz_salon_luxe',
      name: 'Salon Luxe & Spa',
      logoUrl: '',
      category: BusinessCategory.salon,
      description: 'Hair styling and treatments.',
      rating: 4.9,
      reviewCount: 180,
      branches: [
        BranchModel(
          id: 'br_salon_main',
          businessId: 'biz_salon_luxe',
          name: 'Downtown Salon Studio',
          address: '120 Fashion Plaza',
          latitude: 37.7880,
          longitude: -122.4100,
          distanceKm: 1.1,
          openingHours: '10:00 AM - 8:00 PM',
          phoneNumber: '+1-555-0104',
          services: [
            ServiceModel(
              id: 'srv_haircut',
              businessId: 'biz_salon_luxe',
              branchId: 'br_salon_main',
              name: 'Haircut & Styling',
              category: 'Hair',
              description: 'Custom wash and cut.',
              estimatedMinutesPerCustomer: 25,
            ),
          ],
        ),
      ],
    ),
  ];
}
