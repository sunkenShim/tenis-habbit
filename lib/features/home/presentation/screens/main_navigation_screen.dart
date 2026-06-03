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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '통계',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '히스토리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: '회고',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
