import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../data/models/analytics_models.dart';

class EmotionDistributionChart extends StatelessWidget {
  final TrendInsights insights;

  const EmotionDistributionChart({Key? key, required this.insights}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (insights.emotions.isEmpty) return const SizedBox.shrink();

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
              const Icon(Icons.pie_chart_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Emotion Distribution',
                style: AppTheme.subheadingStyle.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: _buildHorizontalBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBars() {
    final int total = insights.emotions.fold(0, (sum, item) => sum + item.count);
    int maxCount = 0;
    for (var e in insights.emotions) {
      if (e.count > maxCount) maxCount = e.count;
    }

    final sorted = List.of(insights.emotions)..sort((a, b) => b.count.compareTo(a.count));

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final emotion = sorted[index];
        final style = EmotionStyle.fromEmotion(emotion.emotion);
        final pct = (emotion.count / total) * 100;
        final fraction = maxCount > 0 ? emotion.count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  style.label,
                  style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
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
                            color: style.color,
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
                width: 40,
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
