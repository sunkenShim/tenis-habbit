import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tennis_habit/features/review/domain/models/tennis_log_model.dart';
import 'package:tennis_habit/core/utils/mock_data_generator.dart';

class StatsDashboardScreen extends StatelessWidget {
  const StatsDashboardScreen({super.key});

  final String _testUserId = 'test_user_id';

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
                  child: LineChart(_buildLineChartData(logs)),
                ),
                const SizedBox(height: 32),
                const Text('세션 태그 분포', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(_buildPieChartData(logs)),
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

  LineChartData _buildLineChartData(List<TennisLogModel> logs) {
    final spots = <FlSpot>[];
    for (int i = 0; i < logs.length; i++) {
      double avgScore = logs[i].scores.values.fold(0, (sum, item) => sum + item) / logs[i].scores.length;
      spots.add(FlSpot(i.toDouble(), avgScore));
    }

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
      maxY: 3,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.green,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
        ),
      ],
    );
  }

  PieChartData _buildPieChartData(List<TennisLogModel> logs) {
    final Map<String, int> tagCounts = {};
    for (var log in logs) {
      for (var tag in log.sessionTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.red, Colors.teal];
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
