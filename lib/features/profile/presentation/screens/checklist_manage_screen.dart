import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChecklistManageScreen extends StatefulWidget {
  const ChecklistManageScreen({super.key});

  @override
  State<ChecklistManageScreen> createState() => _ChecklistManageScreenState();
}

class _ChecklistItem {
  final String id;
  String title;
  int order;

  _ChecklistItem({required this.id, required this.title, required this.order});
}

class _ChecklistManageScreenState extends State<ChecklistManageScreen> {
  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _controller = TextEditingController();

  List<_ChecklistItem> _items = [];
  bool _isLoading = true;

  static const List<String> _defaultItems = [
    '항상 스플릿 스텝',
    '항상 리커버리 스텝',
    '대근육으로 친다는 느낌!',
    '공만 보고 치기!!!! staying present',
    '왼팔 뻗어 눌러주기',
    '왼팔 내리지 말고 위로 접기',
    '유닛턴 빠르게 해서 라켓 미리 빼기',
    '타점 앞에서 치기 타이밍 늦지 않기',
    '앉았다 일어나는 느낌 갖기',
    '퍼올려 치지 말기',
    '라켓드롭할때 면 아래로 하기 4시->10시',
    '가속 구간 지키기',
    '공 4개 밀어서 지나가는 느낌 go through the ball. 공을 질기게 치는 느낌',
    '공이 떨어지기 기다리지 말고 공이 높을때 치기',
    '발리 손목쓰지 않기. 몸을 앞으로 밀기',
    '발리 준비 자세에서 라켓 뒤로 빼지 않기',
    '발리 턱 내리지 않기.',
    '서브 트로피 자세, 라켓 드롭',
    '서브 왼팔 올리기',
    '서브 내전',
    '서브때 라켓 각도 더 머리쪽으로 잡기',
    '백핸드 라켓 넘기기',
    '백핸드 라켓드롭',
  ];

  CollectionReference get _collection => FirebaseFirestore.instance
      .collection('users')
      .doc(_currentUserId)
      .collection('checklists');

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    // createdAt 기준으로 전체 로드 (order 필드 없는 문서도 포함)
    final snapshot = await _collection.orderBy('createdAt').get();

    List<_ChecklistItem> loaded = [];
    bool needsMigration = false;

    for (int i = 0; i < snapshot.docs.length; i++) {
      final doc = snapshot.docs[i];
      final data = doc.data() as Map<String, dynamic>;
      final hasOrder = data.containsKey('order');
      if (!hasOrder) needsMigration = true;
      loaded.add(_ChecklistItem(
        id: doc.id,
        title: data['title'] ?? '',
        order: hasOrder ? (data['order'] as int) : i,
      ));
    }

    // order 필드가 없는 기존 문서들 마이그레이션
    if (needsMigration) {
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < loaded.length; i++) {
        batch.update(_collection.doc(loaded[i].id), {'order': i});
        loaded[i].order = i;
      }
      await batch.commit();
    } else {
      // order 필드 기준 정렬
      loaded.sort((a, b) => a.order.compareTo(b.order));
    }

    setState(() {
      _items = loaded;
      _isLoading = false;
    });
  }

  Future<void> _onReorderItem(int oldIndex, int newIndex) async {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      _reindexOrders();
    });
    await _saveAllOrders();
  }

  void _reindexOrders() {
    for (int i = 0; i < _items.length; i++) {
      _items[i].order = i;
    }
  }

  Future<void> _saveAllOrders() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final item in _items) {
      batch.update(_collection.doc(item.id), {'order': item.order});
    }
    await batch.commit();
  }

  void _showAddDialog() {
    _controller.clear();
    int insertPosition = _items.length; // 기본: 맨 뒤

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('새 항목 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '체크리스트 내용 입력',
                      labelText: '내용',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('삽입 위치', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: insertPosition,
                    items: [
                      const DropdownMenuItem(value: 0, child: Text('맨 위')),
                      ..._items.asMap().entries.map((e) => DropdownMenuItem(
                            value: e.key + 1,
                            child: Text(
                              '${e.value.title} 뒤',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => insertPosition = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                TextButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      _addItem(_controller.text.trim(), insertPosition);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(String id, String currentTitle) {
    _controller.text = currentTitle;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 편집'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '내용을 수정하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                _editItem(id, _controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기본값으로 초기화'),
        content: const Text('기존 항목을 모두 삭제하고 기본 체크리스트 23개를 불러올까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetToDefaults();
            },
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(String title, int insertIndex) async {
    // insertIndex 이후 항목들의 order를 +1
    final batch = FirebaseFirestore.instance.batch();
    for (int i = insertIndex; i < _items.length; i++) {
      _items[i].order = i + 1;
      batch.update(_collection.doc(_items[i].id), {'order': i + 1});
    }

    final newDoc = _collection.doc();
    final newItem = _ChecklistItem(id: newDoc.id, title: title, order: insertIndex);
    batch.set(newDoc, {
      'title': title,
      'order': insertIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    setState(() {
      _items.insert(insertIndex, newItem);
    });
  }

  Future<void> _editItem(String id, String newTitle) async {
    await _collection.doc(id).update({'title': newTitle});
    setState(() {
      final item = _items.firstWhere((e) => e.id == id);
      item.title = newTitle;
    });
  }

  Future<void> _deleteItem(String id) async {
    await _collection.doc(id).delete();
    setState(() {
      _items.removeWhere((e) => e.id == id);
      _reindexOrders();
    });
    await _saveAllOrders();
  }

  Future<void> _resetToDefaults() async {
    setState(() => _isLoading = true);

    final existing = await _collection.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    final now = Timestamp.now();
    final List<_ChecklistItem> newItems = [];
    for (int i = 0; i < _defaultItems.length; i++) {
      final newDoc = _collection.doc();
      batch.set(newDoc, {
        'title': _defaultItems[i],
        'order': i,
        'createdAt': Timestamp(now.seconds + i, now.nanoseconds),
      });
      newItems.add(_ChecklistItem(id: newDoc.id, title: _defaultItems[i], order: i));
    }

    await batch.commit();

    setState(() {
      _items = newItems;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기본 체크리스트로 초기화했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트 관리'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') _confirmReset();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('기본값으로 초기화'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('체크리스트 항목이 없습니다.'),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _confirmReset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('기본값 불러오기'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  onReorderItem: _onReorderItem,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      key: ValueKey(item.id),
                      leading: const Icon(Icons.drag_handle, color: Colors.grey),
                      title: Text(item.title),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditDialog(item.id, item.title),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteItem(item.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
