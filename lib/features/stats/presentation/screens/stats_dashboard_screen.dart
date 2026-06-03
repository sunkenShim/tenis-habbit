import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tennis_habit/features/review/domain/models/tennis_log_model.dart';
import 'package:tennis_habit/core/utils/mock_data_generator.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final String _testUserId = 'test_user_id';
  
  // 선택되지 않은 항목들을 관리 (기본적으로 모두 선택된 상태)
  final Set<String> _unselectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테니스 통계'),
        actions: [
          TextButton(
            onPressed: () async {
              await MockDataGenerator.generate14DaysLogs(_testUserId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('14일치 가상 데이터가 생성되었습니다.')),
                );
              }
            },
            child: const Text('데이터 생성'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_testUserId)
            .collection('tennis_logs')
            .orderBy('date', descending: false)
            .limit(14)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('에러: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!.docs
              .map((doc) => TennisLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          if (logs.isEmpty) {
            return const Center(child: Text('데이터가 없습니다. 우측 상단 버튼으로 생성해보세요.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('최근 14일 점수 추이', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(_buildLineChartData(logs, context)),
                ),
                const SizedBox(height: 16),
                _buildLegend(logs, context),
                const SizedBox(height: 32),
                const Text('세션 종류 분포', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(_buildPieChartData(logs, context, true)),
                ),
                const SizedBox(height: 32),
                const Text('코트 종류 분포', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(_buildPieChartData(logs, context, false)),
                ),
                const SizedBox(height: 32),
                const Text('평균 컨디션', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildConditionSummary(logs),
              ],
            ),
          );
        },
      ),
    );
  }

  LineChartData _buildLineChartData(List<TennisLogModel> logs, BuildContext context) {
    final Set<String> allChecklistKeys = {};
    for (var log in logs) {
      allChecklistKeys.addAll(log.scores.keys);
    }

    final Map<String, List<FlSpot>> spotsMap = {
      for (var key in allChecklistKeys) key: []
    };

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      for (var key in allChecklistKeys) {
        if (log.scores.containsKey(key)) {
          spotsMap[key]!.add(FlSpot(i.toDouble(), log.scores[key]!.toDouble()));
        }
      }
    }

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.tealAccent,
      Colors.cyan,
    ];

    List<LineChartBarData> lineBarsData = [];
    int colorIndex = 0;
    
    spotsMap.forEach((key, spots) {
      // unselectedItems에 포함되지 않은 경우만 차트에 그림
      if (spots.isNotEmpty && !_unselectedItems.contains(key)) {
        final color = colors[colorIndex % colors.length];
        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
      colorIndex++; // 선택 여부와 상관없이 색상 인덱스는 고정 유지
    });

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() % 3 == 0 && value.toInt() < logs.length) {
                final date = logs[value.toInt()].date;
                return Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 10));
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 30)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
      minX: 0,
      maxX: logs.length.toDouble() - 1,
      minY: 1,
      maxY: 3.5,
      lineBarsData: lineBarsData,
    );
  }

  Widget _buildLegend(List<TennisLogModel> logs, BuildContext context) {
    final Set<String> allChecklistKeys = {};
    for (var log in logs) {
      allChecklistKeys.addAll(log.scores.keys);
    }

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.tealAccent,
      Colors.cyan,
    ];

    int colorIndex = 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allChecklistKeys.map((key) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        
        final isSelected = !_unselectedItems.contains(key);
        final textColor = Theme.of(context).brightness == Brightness.dark 
            ? (isSelected ? Colors.black : Colors.white) 
            : (isSelected ? Colors.white : Colors.black);

        return FilterChip(
          label: Text(
            key, 
            style: TextStyle(
              fontSize: 12, 
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: color,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? color : Colors.grey),
          ),
          showCheckmark: false,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _unselectedItems.remove(key); // 선택됨
              } else {
                _unselectedItems.add(key); // 선택 해제됨
              }
            });
          },
        );
      }).toList(),
    );
  }

  PieChartData _buildPieChartData(List<TennisLogModel> logs, BuildContext context, bool isMatchType) {
    final Map<String, int> tagCounts = {};
    for (var log in logs) {
      if (isMatchType) {
        for (var tag in log.matchTypes) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      } else {
        final tag = log.courtSurface;
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.tealAccent
    ];
    int colorIndex = 0;

    return PieChartData(
      sections: tagCounts.entries.map((e) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return PieChartSectionData(
          color: color,
          value: e.value.toDouble(),
          title: '${e.key}\n${e.value}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList(),
    );
  }

  Widget _buildConditionSummary(List<TennisLogModel> logs) {
    double avgCondition = logs.map((l) => l.conditionScore).fold(0, (s, i) => s + i) / logs.length;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.wb_sunny, color: Colors.orange),
        title: Text('최근 14일 평균 컨디션: ${avgCondition.toStringAsFixed(1)} / 5.0'),
        subtitle: const Text('컨디션이 좋을 때 체크리스트 점수도 높은 경향이 있습니다.'),
      ),
    );
  }
}
