import 'package:flutter_test/flutter_test.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/data/repositories/queue_repository.dart';
import 'package:easyqueue/data/models/user_model.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';

void main() {
  group('QueueViewModel & State Machine Tests', () {
    late QueueRepository queueRepository;
    late QueueViewModel queueViewModel;
    late UserModel testUser;

    setUp(() {
      queueRepository = QueueRepository(enableAutoCountdown: false);
      queueViewModel = QueueViewModel(queueRepository: queueRepository);
      testUser = UserModel(
        id: 'usr_test_1',
        displayName: 'Test Customer',
        phoneNumber: '+14155552671',
        countryCode: '+1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    tearDown(() {
      queueRepository.dispose();
      queueViewModel.dispose();
    });

    test('Initial queue state for clean user has no active tickets until joined', () {
      expect(queueViewModel.activeTickets.isEmpty, true);
      expect(queueViewModel.primaryActiveTicket, isNull);
    });

    test('Join new queue generates unique token and increments active tickets', () async {
      final initialCount = queueViewModel.activeTickets.length;

      final ticket = await queueViewModel.joinQueue(
        businessId: 'biz_city_diag',
        businessName: 'City Diagnostics & Labs',
        branchId: 'br_diag_central',
        branchName: 'Central Diagnostic Center',
        branchAddress: '89 Science Park Blvd',
        serviceId: 'srv_blood_test',
        serviceName: 'Complete Blood Count & Lipid Panel',
        currentUser: testUser,
        groupSize: 1,
      );

      expect(ticket, isNotNull);
      expect(ticket!.serviceId, 'srv_blood_test');
      expect(ticket.status, QueueStatus.waiting);
      expect(queueViewModel.activeTickets.length, initialCount + 1);
    });

    test('Prevent duplicate active ticket for same service (UC-025)', () async {
      final initialCount = queueViewModel.activeTickets.length;

      // Join once
      final ticket1 = await queueViewModel.joinQueue(
        businessId: 'biz_metro_bank',
        businessName: 'Metro Global Bank',
        branchId: 'br_bank_fin',
        branchName: 'Financial District Branch',
        branchAddress: '100 Financial Way',
        serviceId: 'srv_teller',
        serviceName: 'Cash Deposit & Withdrawal Teller',
        currentUser: testUser,
      );

      expect(queueViewModel.activeTickets.length, initialCount + 1);

      // Attempt joining again for same service
      final ticket2 = await queueViewModel.joinQueue(
        businessId: 'biz_metro_bank',
        businessName: 'Metro Global Bank',
        branchId: 'br_bank_fin',
        branchName: 'Financial District Branch',
        branchAddress: '100 Financial Way',
        serviceId: 'srv_teller',
        serviceName: 'Cash Deposit & Withdrawal Teller',
        currentUser: testUser,
      );

      // Should return existing ticket without duplicating
      expect(ticket2!.id, ticket1!.id);
      expect(queueViewModel.activeTickets.length, initialCount + 1);
    });

    test('Queue Simulation progresses states: WAITING -> APPROACHING -> CALLED -> SERVING -> COMPLETED', () async {
      final ticket = await queueViewModel.joinQueue(
        businessId: 'biz_salon_luxe',
        businessName: 'Salon Luxe',
        branchId: 'br_salon_uptown',
        branchName: 'Uptown Galleria',
        branchAddress: '320 Fashion Promenade',
        serviceId: 'srv_facial',
        serviceName: 'Hydrating Facial',
        currentUser: testUser,
      );

      final entryId = ticket!.id;

      // Simulate until called
      while (queueViewModel.getTicketById(entryId)!.status == QueueStatus.waiting) {
        queueViewModel.simulateNextState(entryId);
      }

      expect(queueViewModel.getTicketById(entryId)!.status, QueueStatus.approaching);

      // Simulate to CALLED
      queueViewModel.simulateNextState(entryId);
      final calledTicket = queueViewModel.getTicketById(entryId)!;
      expect(calledTicket.status, QueueStatus.called);
      expect(calledTicket.assignedCounterNumber, isNotNull);

      // Simulate to SERVING
      queueViewModel.simulateNextState(entryId);
      expect(queueViewModel.getTicketById(entryId)!.status, QueueStatus.serving);

      // Simulate to COMPLETED
      queueViewModel.simulateNextState(entryId);
      final completedTicket = queueViewModel.getTicketById(entryId)!;
      expect(completedTicket.status, QueueStatus.completed);
      expect(completedTicket.isActive, false);
    });

    test('Cancel active ticket updates status to CANCELLED (UC-038)', () async {
      final ticket = await queueViewModel.joinQueue(
        businessId: 'biz_auto_care',
        businessName: 'Apex Precision Auto',
        branchId: 'br_auto_east',
        branchName: 'East Hub',
        branchAddress: '77 Motorway Way',
        serviceId: 'srv_oil_change',
        serviceName: 'Synthetic Oil Change',
        currentUser: testUser,
      );

      final success = await queueViewModel.cancelTicket(ticket!.id, reason: 'Test cancellation');
      expect(success, true);

      final updated = queueViewModel.getTicketById(ticket.id)!;
      expect(updated.status, QueueStatus.cancelled);
      expect(updated.isActive, false);
    });
  });
}
