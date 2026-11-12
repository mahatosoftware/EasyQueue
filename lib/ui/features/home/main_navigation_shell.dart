import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';
import 'package:easyqueue/ui/view_models/appointment_view_model.dart';
import 'home_dashboard_screen.dart';
import 'package:easyqueue/ui/features/explore/explore_screen.dart';
import 'package:easyqueue/ui/features/queue/my_tickets_screen.dart';
import 'package:easyqueue/ui/features/appointments/appointments_view.dart';
import 'package:easyqueue/ui/features/profile/profile_view.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final queueVm = context.watch<QueueViewModel>();
    final aptVm = context.watch<AppointmentViewModel>();

    final activeTicketsCount = queueVm.activeTickets.length;
    final upcomingAptsCount = aptVm.upcomingAppointments.length;

    final List<Widget> screens = [
      HomeDashboardScreen(onNavigateTab: _onTabSelected),
      const ExploreScreen(),
      const MyTicketsScreen(),
      const AppointmentsView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedLight,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: activeTicketsCount > 0,
              label: Text('$activeTicketsCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.confirmation_number_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: activeTicketsCount > 0,
              label: Text('$activeTicketsCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.confirmation_number_rounded),
            ),
            label: 'My Tickets',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: upcomingAptsCount > 0,
              label: Text('$upcomingAptsCount'),
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.calendar_today_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: upcomingAptsCount > 0,
              label: Text('$upcomingAptsCount'),
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.calendar_today_rounded),
            ),
            label: 'Appointments',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
