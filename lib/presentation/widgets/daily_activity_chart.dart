import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../data/models/analytics_models.dart';

class DailyActivityChart extends StatelessWidget {
  final TrendInsights insights;
  final List<FlSpot> cachedSpots;

  const DailyActivityChart({
    Key? key,
    required this.insights,
    required this.cachedSpots,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (insights.daily.isEmpty) return const SizedBox.shrink();

    if (cachedSpots.isEmpty) return const SizedBox.shrink();

    double maxCount = 0;
    for (var spot in cachedSpots) {
      if (spot.y > maxCount) maxCount = spot.y;
    }
    if (maxCount == 0) maxCount = 5; // fallback

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceActive,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Activity Trends',
                style: AppTheme.subheadingStyle.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxCount + (maxCount * 0.2), // 20% top padding
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.primaryColor,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) => LineTooltipItem(
                        spot.y.round().toString(),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        
                        // We still derive the date label from insights if not passed directly.
                        // But since we just need "Mon, Tue", let's safely map index -> display data.
                        final sortedDaily = List<DailyScanCount>.from(insights.daily)
                          ..sort((a, b) => a.date.compareTo(b.date));
                        final displayData = sortedDaily.length > 7
                            ? sortedDaily.sublist(sortedDaily.length - 7)
                            : sortedDaily;

                        if (index < 0 || index >= displayData.length) {
                          return const SizedBox.shrink();
                        }
                        final date = displayData[index].date;
                        final label = DateFormat('E').format(date); // Mon, Tue
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.textLightColor,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCount / 4 > 0 ? maxCount / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textLightColor.withOpacity(0.1),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: cachedSpots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
              duration: AppTheme.animSlow,
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}
