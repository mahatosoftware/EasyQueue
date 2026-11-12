import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/main.dart';
import 'package:easyqueue/data/services/local_storage_service.dart';
import 'package:easyqueue/data/repositories/auth_repository.dart';
import 'package:easyqueue/data/repositories/business_repository.dart';
import 'package:easyqueue/data/repositories/queue_repository.dart';
import 'package:easyqueue/data/repositories/appointment_repository.dart';
import 'package:easyqueue/data/repositories/family_repository.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';
import 'package:easyqueue/ui/view_models/home_view_model.dart';
import 'package:easyqueue/ui/view_models/explore_view_model.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';
import 'package:easyqueue/ui/view_models/appointment_view_model.dart';
import 'package:easyqueue/ui/view_models/family_view_model.dart';
import 'package:easyqueue/ui/view_models/profile_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('When unauthenticated, EasyQueue launches with AuthScreen (Email, Password, Reset & Google)', (WidgetTester tester) async {
    final storageService = LocalStorageService();
    final authRepository = AuthRepository(storageService: storageService);
    final businessRepository = BusinessRepository();
    final queueRepository = QueueRepository(enableAutoCountdown: false);
    final appointmentRepository = AppointmentRepository(queueRepository: queueRepository);
    final familyRepository = FamilyRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository: authRepository)),
          ChangeNotifierProvider(
            create: (_) => HomeViewModel(
              businessRepository: businessRepository,
              queueRepository: queueRepository,
            ),
          ),
          ChangeNotifierProvider(create: (_) => ExploreViewModel(businessRepository: businessRepository)),
          ChangeNotifierProvider(create: (_) => QueueViewModel(queueRepository: queueRepository)),
          ChangeNotifierProvider(
            create: (_) => AppointmentViewModel(appointmentRepository: appointmentRepository),
          ),
          ChangeNotifierProvider(create: (_) => FamilyViewModel(familyRepository: familyRepository)),
          ChangeNotifierProvider(create: (_) => ProfileViewModel(authRepository: authRepository)),
        ],
        child: const EasyQueueCustomerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Auth Screen is the first screen shown
    expect(find.text('Easy Queue'), findsOneWidget);
    expect(find.text('Sign In'), findsNWidgets(2)); // Tab pill and primary button
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // Clean up
    queueRepository.dispose();
    authRepository.dispose();
    appointmentRepository.dispose();
    familyRepository.dispose();
  });

  testWidgets('When authenticated, EasyQueue renders MainNavigationShell', (WidgetTester tester) async {
    final storageService = LocalStorageService();
    final authRepository = AuthRepository(storageService: storageService);
    // Authenticate user
    await authRepository.signInWithEmail(email: 'alex.morgan@example.com', password: 'password123');

    final businessRepository = BusinessRepository();
    final queueRepository = QueueRepository(enableAutoCountdown: false);
    final appointmentRepository = AppointmentRepository(queueRepository: queueRepository);
    final familyRepository = FamilyRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository: authRepository)),
          ChangeNotifierProvider(
            create: (_) => HomeViewModel(
              businessRepository: businessRepository,
              queueRepository: queueRepository,
            ),
          ),
          ChangeNotifierProvider(create: (_) => ExploreViewModel(businessRepository: businessRepository)),
          ChangeNotifierProvider(create: (_) => QueueViewModel(queueRepository: queueRepository)),
          ChangeNotifierProvider(
            create: (_) => AppointmentViewModel(appointmentRepository: appointmentRepository),
          ),
          ChangeNotifierProvider(create: (_) => FamilyViewModel(familyRepository: familyRepository)),
          ChangeNotifierProvider(create: (_) => ProfileViewModel(authRepository: authRepository)),
        ],
        child: const EasyQueueCustomerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Main Shell Bottom Navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('My Tickets'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Clean up
    queueRepository.dispose();
    authRepository.dispose();
    appointmentRepository.dispose();
    familyRepository.dispose();
  });

  testWidgets('Home screen renders without RenderFlex overflow on small screen width (320px)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320 * 2, 600 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storageService = LocalStorageService();
    final authRepository = AuthRepository(storageService: storageService);
    await authRepository.signInWithEmail(email: 'alex.morgan@example.com', password: 'password123');

    final businessRepository = BusinessRepository();
    final queueRepository = QueueRepository(enableAutoCountdown: false);
    final appointmentRepository = AppointmentRepository(queueRepository: queueRepository);
    final familyRepository = FamilyRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository: authRepository)),
          ChangeNotifierProvider(
            create: (_) => HomeViewModel(
              businessRepository: businessRepository,
              queueRepository: queueRepository,
            ),
          ),
          ChangeNotifierProvider(create: (_) => ExploreViewModel(businessRepository: businessRepository)),
          ChangeNotifierProvider(create: (_) => QueueViewModel(queueRepository: queueRepository)),
          ChangeNotifierProvider(create: (_) => AppointmentViewModel(appointmentRepository: appointmentRepository)),
          ChangeNotifierProvider(create: (_) => FamilyViewModel(familyRepository: familyRepository)),
          ChangeNotifierProvider(create: (_) => ProfileViewModel(authRepository: authRepository)),
        ],
        child: const EasyQueueCustomerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Confirm no exceptions or overflows thrown
    expect(tester.takeException(), isNull);
    expect(find.text('Downtown, San Francisco'), findsOneWidget);

    queueRepository.dispose();
    authRepository.dispose();
    appointmentRepository.dispose();
    familyRepository.dispose();
  });
}
