import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tennis_habit/features/review/domain/models/tennis_log_model.dart';
import 'package:tennis_habit/features/review/presentation/widgets/share_card_widget.dart';

class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  final String _testUserId = 'test_user_id';
  final DateTime _selectedDate = DateTime.now();

  List<String> _selectedTags = [];
  int _conditionScore = 3;
  Map<String, int> _scores = {};
  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _availableTags = ['연습', '레슨', '단식', '복식', '하드코트', '클레이코트', '잔디코트'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChecklistsAndTodayLog();
  }

  Future<void> _fetchChecklistsAndTodayLog() async {
    setState(() => _isLoading = true);
    
    // 1. Fetch custom checklists
    final checklistSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_testUserId)
        .collection('checklists')
        .orderBy('createdAt', descending: false)
        .get();

    final List<String> checklistTitles = checklistSnapshot.docs
        .map((doc) => doc.data()['title'] as String)
        .toList();

    // Default items if none exist
    if (checklistTitles.isEmpty) {
      checklistTitles.addAll(['스플릿 스텝 잘하기', '공 4개 통과하는 느낌으로 치기', '라켓 끝까지 던지기']);
    }

    // 2. Fetch today's log if exists
    final logId = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final logDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_testUserId)
        .collection('tennis_logs')
        .doc(logId)
        .get();

    Map<String, int> initialScores = {for (var title in checklistTitles) title: 2};
    List<String> initialTags = [];
    int initialCondition = 3;
    String initialFeedback = '';

    if (logDoc.exists) {
      final log = TennisLogModel.fromMap(logDoc.data()!, logDoc.id);
      initialTags = log.sessionTags;
      initialCondition = log.conditionScore;
      initialFeedback = log.feedbackText;
      // Merge existing scores with checklist (in case checklist items changed)
      for (var title in checklistTitles) {
        if (log.scores.containsKey(title)) {
          initialScores[title] = log.scores[title]!;
        }
      }
    }

    setState(() {
      _scores = initialScores;
      _selectedTags = initialTags;
      _conditionScore = initialCondition;
      _feedbackController.text = initialFeedback;
      _isLoading = false;
    });
  }

  Future<void> _saveLog() async {
    final log = TennisLogModel(
      date: _selectedDate,
      sessionTags: _selectedTags,
      conditionScore: _conditionScore,
      scores: _scores,
      feedbackText: _feedbackController.text,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_testUserId)
          .collection('tennis_logs')
          .doc(log.documentId)
          .set(log.toMap(), SetOptions(merge: true));

      if (mounted) {
        _showShareDialog(log);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  void _showShareDialog(TennisLogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ShareCardWidget(log: log),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _onTagSelected(String tag, bool selected) {
    HapticFeedback.lightImpact();
    setState(() {
      if (selected) {
        _selectedTags.add(tag);
      } else {
        _selectedTags.remove(tag);
      }
    });
  }

  void _onScoreChanged(String criteria, int score) {
    HapticFeedback.lightImpact();
    setState(() {
      _scores[criteria] = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 테니스 회고'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveLog,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionCard(
                  title: '세션 태그',
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableTags.map((tag) {
                      return ChoiceChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        onSelected: (selected) => _onTagSelected(tag, selected),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: '오늘의 컨디션',
                  child: Column(
                    children: [
                      Slider(
                        value: _conditionScore.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _conditionScore.toString(),
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _conditionScore = value.round();
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('지침', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('최상', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: '핵심 체크리스트',
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _fetchChecklistsAndTodayLog,
                    tooltip: '체크리스트 새로고침',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _scores.keys.map((criteria) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(criteria, style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: _ScoreButton(
                                    emoji: '😥',
                                    label: '아쉬움',
                                    isSelected: _scores[criteria] == 1,
                                    onTap: () => _onScoreChanged(criteria, 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ScoreButton(
                                    emoji: '😐',
                                    label: '보통',
                                    isSelected: _scores[criteria] == 2,
                                    onTap: () => _onScoreChanged(criteria, 2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ScoreButton(
                                    emoji: '🔥',
                                    label: '완벽함',
                                    isSelected: _scores[criteria] == 3,
                                    onTap: () => _onScoreChanged(criteria, 3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: '오늘의 깨달음',
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: '예: 오늘은 백핸드 시선을 끝까지 고정했다.',
                    ),
                    maxLength: 100,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionCard({required String title, Widget? trailing, required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScoreButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? (emoji == '🔥' ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.secondary.withOpacity(0.1)) : Colors.transparent,
          border: Border.all(
            color: isSelected ? (emoji == '🔥' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary) : Colors.grey.shade800,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? (emoji == '🔥' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary) : Colors.grey.shade400,
            )),
          ],
        ),
      ),
    );
  }
}
