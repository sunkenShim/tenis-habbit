import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tennis_habit/features/review/domain/models/tennis_log_model.dart';
import 'package:intl/intl.dart';

class HistoryTimelineScreen extends StatefulWidget {
  const HistoryTimelineScreen({super.key});

  @override
  State<HistoryTimelineScreen> createState() => _HistoryTimelineScreenState();
}

class _HistoryTimelineScreenState extends State<HistoryTimelineScreen> {
  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TennisLogModel>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('tennis_logs')
        .get();

    final Map<DateTime, List<TennisLogModel>> newEvents = {};
    for (var doc in querySnapshot.docs) {
      final log = TennisLogModel.fromMap(doc.data(), doc.id);
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      if (newEvents[date] == null) {
        newEvents[date] = [];
      }
      newEvents[date]!.add(log);
    }

    setState(() {
      _events = newEvents;
    });
  }

  List<TennisLogModel> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 히스토리'),
      ),
      body: Column(
        children: [
          TableCalendar<TennisLogModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return const Center(
        child: Text('기록이 없는 날입니다.'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final log = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: ListTile(
            title: Text(
              '${log.matchTypes.join(", ")} | ${log.courtSurface}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('컨디션: ${log.conditionScore} | 점수: ${log.scores.values.fold(0, (a, b) => a + b)}'),
                if (log.feedbackText.isNotEmpty)
                  Text(
                    log.feedbackText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLogDetail(log),
          ),
        );
      },
    );
  }

  Future<void> _deleteLog(TennisLogModel log, BuildContext sheetContext) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text('${DateFormat('yyyy년 MM월 dd일').format(log.date)} 기록을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('tennis_logs')
        .doc(log.documentId)
        .delete();

    if (sheetContext.mounted) Navigator.pop(sheetContext);
    _fetchLogs();
  }

  void _showLogDetail(TennisLogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy년 MM월 dd일 회고').format(log.date),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteLog(log, sheetContext),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text('세션 상세', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: [
                      ...log.matchTypes.map((t) => Chip(label: Text(t))),
                      Chip(label: Text(log.courtSurface), backgroundColor: Colors.green.withOpacity(0.1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('오늘의 컨디션: ${log.conditionScore}점', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('체크리스트 점수', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...log.scores.entries.map((e) => ListTile(
                    title: Text(e.key),
                    trailing: Text(e.value == 3 ? '🔥 완벽' : e.value == 2 ? '😐 보통' : '😥 아쉬움'),
                  )),
                  const SizedBox(height: 20),
                  const Text('오늘의 깨달음', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(log.feedbackText.isEmpty ? '작성된 내용이 없습니다.' : log.feedbackText),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
