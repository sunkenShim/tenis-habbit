import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _testUserId = 'test_user_id';
  final TextEditingController _racketController = TextEditingController();
  final TextEditingController _stringController = TextEditingController();
  final TextEditingController _tensionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_testUserId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final equipment = data['equipment'] as Map<String, dynamic>?;
        if (equipment != null) {
          _racketController.text = equipment['racket'] ?? '';
          _stringController.text = equipment['string'] ?? '';
          _tensionController.text = equipment['tension']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('장비 정보 로드 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEquipment() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_testUserId).set({
        'equipment': {
          'racket': _racketController.text,
          'string': _stringController.text,
          'tension': int.tryParse(_tensionController.text) ?? 0,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장비 정보가 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 및 장비 관리'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveEquipment,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                const Text('나의 테니스 장비', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  controller: _racketController,
                  decoration: const InputDecoration(
                    labelText: '라켓 모델',
                    hintText: '예: Wilson Pro Staff 97',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_tennis),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _stringController,
                  decoration: const InputDecoration(
                    labelText: '스트링 종류',
                    hintText: '예: Luxilon Alu Power',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.linear_scale),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tensionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '텐션 (lbs)',
                    hintText: '예: 52',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.compress),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('앱 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
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
