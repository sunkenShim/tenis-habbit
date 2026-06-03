import 'package:flutter/material.dart';
import 'package:tennis_habit/features/review/presentation/screens/daily_review_screen.dart';
import 'package:tennis_habit/features/stats/presentation/screens/stats_dashboard_screen.dart';
import 'package:tennis_habit/features/history/presentation/screens/history_timeline_screen.dart';
import 'package:tennis_habit/features/profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // 기본값을 '회고' 탭으로 설정 (탭 3)

  final List<Widget> _screens = [
    const StatsDashboardScreen(),
    const HistoryTimelineScreen(),
    const DailyReviewScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true, 를 제거하여 바텀 네비게이션 바가 컨텐츠를 가리지 않도록 함
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8), // 여백을 줄여 바닥에 더 붙게 조정
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.bar_chart, '통계'),
              _buildNavItem(1, Icons.calendar_month, '히스토리'),
              _buildNavItem(2, Icons.edit_note, '회고'),
              _buildNavItem(3, Icons.person, '프로필'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
