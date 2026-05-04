import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../data/models/analytics_models.dart';

class InsightCard extends StatelessWidget {
  final BehaviorInsight insight;

  const InsightCard({Key? key, required this.insight}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      switch (insight.type) {
        case InsightType.pattern:
          return Icons.auto_graph_rounded;
        case InsightType.anomaly:
          return Icons.flash_on_rounded;
        case InsightType.consistency:
          return Icons.verified_rounded;
        case InsightType.shift:
          return Icons.compare_arrows_rounded;
      }
    }

    Color getColor() {
      switch (insight.type) {
        case InsightType.pattern:
          return AppTheme.primaryColor;
        case InsightType.anomaly:
          return AppTheme.accentColor;
        case InsightType.consistency:
          return AppTheme.successColor;
        case InsightType.shift:
          return const Color(0xFF7B61FF); // Purple
      }
    }

    final color = getColor();
    final icon = getIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceActive,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: AppTheme.titleStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (insight.confidence >= 0.8)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'High Confidence',
                          style: AppTheme.captionStyle.copyWith(
                            color: AppTheme.successColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  insight.description,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 14,
                    color: AppTheme.textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
