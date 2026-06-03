import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'checklist_manage_screen.dart';
import 'package:tennis_habit/core/theme/app_theme.dart';
import 'package:tennis_habit/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _testUserId = 'test_user_id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  SizedBox(height: 16),
                  Text('테스트 유저', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('test_user_id', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('디자인 테마 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ValueListenableBuilder<AppThemeType>(
              valueListenable: themeNotifier,
              builder: (context, currentTheme, _) {
                return Column(
                  children: AppThemeType.values.map((themeType) {
                    return RadioListTile<AppThemeType>(
                      title: Text(AppTheme.getThemeName(themeType)),
                      value: themeType,
                      groupValue: currentTheme,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) {
                        if (value != null) themeNotifier.value = value;
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('앱 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('체크리스트 관리'),
              subtitle: const Text('나만의 훈련 목표를 설정하세요'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChecklistManageScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('알림 설정'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('버전 정보'),
              subtitle: const Text('1.0.0'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
