import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../data/models/analytics_models.dart';

class WeeklyTrendCard extends StatelessWidget {
  final TrendInsights insights;

  const WeeklyTrendCard({Key? key, required this.insights}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (insights.weeklyTrends.isEmpty) return const SizedBox.shrink();

    final thisWeekMap = insights.weeklyTrends[0].emotionCounts;
    final lastWeekMap = insights.weeklyTrends[1].emotionCounts;

    final int thisWeekTotal = thisWeekMap.values.fold(0, (sum, val) => sum + val);
    final int lastWeekTotal = lastWeekMap.values.fold(0, (sum, val) => sum + val);
    final int maxTotal = [thisWeekTotal, lastWeekTotal, 1].reduce((a, b) => a > b ? a : b); // Ensure > 0

    String pctChange = "";
    Color pctColor = AppTheme.textLightColor;
    if (lastWeekTotal > 0) {
      final double diff = (thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100;
      final sign = diff > 0 ? "+" : "";
      pctChange = "$sign${diff.round()}%";
      pctColor = diff >= 0 ? AppTheme.successColor : AppTheme.errorColor;
    } else if (thisWeekTotal > 0 && lastWeekTotal == 0) {
      pctChange = "+100%";
      pctColor = AppTheme.successColor;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'This Week vs Last Week',
                  style: AppTheme.subheadingStyle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (pctChange.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pctColor.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusPill,
                  ),
                  child: Text(
                    pctChange,
                    style: AppTheme.captionStyle.copyWith(
                      color: pctColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insights.weeklySummary,
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          _buildComparisonRow('This Week', thisWeekTotal, maxTotal, true),
          const SizedBox(height: 12),
          _buildComparisonRow('Last Week', lastWeekTotal, maxTotal, false),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, int total, int maxTotal, bool isCurrent) {
    final double fraction = total / maxTotal;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTheme.captionStyle.copyWith(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedContainer(
                    duration: AppTheme.animSlow,
                    curve: Curves.easeOutCubic,
                    height: 12,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.primaryColor : AppTheme.textLightColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            '$total',
            textAlign: TextAlign.end,
            style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
