import 'package:flutter/material.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/ui/features/home/main_navigation_shell.dart';
import 'package:easyqueue/ui/features/auth/auth_screen.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Skip the Wait.\nJoin Remotely.',
      'description':
          'Find nearby clinics, banks, diagnostic labs, salons, and government offices. Join live queues with one tap.',
      'icon': Icons.queue_play_next_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Track Real-Time\nQueue Progress',
      'description':
          'Watch your token move up in line, see exact customers ahead, and relax until your turn approaches.',
      'icon': Icons.speed_rounded,
      'color': AppColors.secondary,
    },
    {
      'title': 'Instant Counter\nAssignments',
      'description':
          'Receive clear counter announcements and directions directly on your phone. No physical line required.',
      'icon': Icons.countertops_rounded,
      'color': AppColors.accent,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, AppConstants.bottomNavPadding),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Easy Queue',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                      );
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (slide['color'] as Color).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide['icon'] as IconData, size: 64, color: slide['color'] as Color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title'] as String,
                          style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['description'] as String,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isSel = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSel ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < _slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                    );
                  }
                },
                child: Text(
                  _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                child: const Text('Sign In to Existing Account'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
