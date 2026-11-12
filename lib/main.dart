import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/firebase_auth_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/business_repository.dart';
import 'data/repositories/queue_repository.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/family_repository.dart';
import 'ui/view_models/auth_view_model.dart';
import 'ui/view_models/home_view_model.dart';
import 'ui/view_models/explore_view_model.dart';
import 'ui/view_models/queue_view_model.dart';
import 'ui/view_models/appointment_view_model.dart';
import 'ui/view_models/family_view_model.dart';
import 'ui/view_models/profile_view_model.dart';
import 'ui/features/home/main_navigation_shell.dart';
import 'ui/features/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using easyqueue-prod project configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize services & repositories
  final firebaseAuthService = FirebaseAuthService();
  final storageService = LocalStorageService();
  await storageService.init();

  final authRepository = AuthRepository(
    storageService: storageService,
    firebaseAuthService: firebaseAuthService,
  );
  await authRepository.initializeSession();

  final initialUser = authRepository.currentUser;

  final businessRepository = BusinessRepository();
  final queueRepository = QueueRepository(
    initialUserId: initialUser?.id,
    isGuest: initialUser?.isGuest ?? false,
  );
  final appointmentRepository = AppointmentRepository(
    queueRepository: queueRepository,
    initialUserId: initialUser?.id,
  );
  final familyRepository = FamilyRepository(
    initialUserId: initialUser?.id,
  );

  // Sync active user across repositories when auth state changes
  authRepository.authStateChanges.listen((user) {
    final uid = user?.id;
    final isGuest = user?.isGuest ?? false;
    queueRepository.updateUser(uid, isGuest: isGuest);
    appointmentRepository.updateUser(uid);
    familyRepository.updateUser(uid);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            businessRepository: businessRepository,
            queueRepository: queueRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExploreViewModel(businessRepository: businessRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => QueueViewModel(queueRepository: queueRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AppointmentViewModel(appointmentRepository: appointmentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => FamilyViewModel(familyRepository: familyRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(authRepository: authRepository),
        ),
      ],
      child: const EasyQueueCustomerApp(),
    ),
  );
}

class EasyQueueCustomerApp extends StatelessWidget {
  const EasyQueueCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

/// Authentication Gate: displays AuthScreen if unauthenticated,
/// or MainNavigationShell if authenticated.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    if (authVm.isLoading && authVm.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authVm.isAuthenticated) {
      return const AuthScreen();
    }

    return const MainNavigationShell();
  }
}
