import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/history_controller.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../config/lottie_registry.dart';
import '../../data/models/detection_result.dart';
import '../../data/models/behavior_insights.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import '../widgets/weekly_trend_card.dart';
import '../widgets/emotion_distribution_chart.dart';
import '../widgets/daily_activity_chart.dart';
import '../widgets/insight_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/pipeline_types.dart';
import '../../theme/app_animations.dart';



class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (context, controller, child) {
        return Scaffold(
            backgroundColor: AppTheme.bgColor,
            appBar: AppBar(
              title: Text('History & Insights', 
                style: AppTheme.titleStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => controller.loadHistory(),
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                  tooltip: 'Refresh history',
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(context, controller),
          );
        },
      );
  }

  Widget _buildBody(BuildContext context, HistoryController controller) {
    if (controller.isLoading) {
      return _buildShimmerLoading();
    }

    if (controller.error != null) {
      return _buildErrorState(context, controller);
    }

    if (controller.results.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Insights Header
          SliverToBoxAdapter(
            child: _buildInsightsHeader(controller),
          ),

          // 2. Intelligence Cards (High Priority AI Findings)
          if (controller.cachedAnalytics?.intelligence != null && 
              controller.cachedAnalytics!.intelligence.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final insight = controller.cachedAnalytics!.intelligence[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space12),
                      child: PetMoodGlass(
                        color: AppTheme.surfaceActive,
                        opacity: 0.4,
                        borderRadius: AppTheme.borderRadiusLarge,
                        child: InsightCard(insight: insight),
                      ),
                    );
                  },
                  childCount: controller.cachedAnalytics!.intelligence.length,
                ),
              ),
            ),

          // 3. Analytical Charts
          if (controller.cachedInsights != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space16),
                    child: PetMoodGlass(
                      color: AppTheme.surfaceActive,
                      opacity: 0.4,
                      borderRadius: AppTheme.borderRadiusLarge,
                      child: WeeklyTrendCard(insights: controller.cachedInsights!),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space16),
                    child: PetMoodGlass(
                      color: AppTheme.surfaceActive,
                      opacity: 0.4,
                      borderRadius: AppTheme.borderRadiusLarge,
                      child: EmotionDistributionChart(insights: controller.cachedInsights!),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space16),
                    child: PetMoodGlass(
                      color: AppTheme.surfaceActive,
                      opacity: 0.4,
                      borderRadius: AppTheme.borderRadiusLarge,
                      child: DailyActivityChart(
                        insights: controller.cachedInsights!,
                        cachedSpots: controller.cachedDailySpots ?? [],
                      ),
                    ),
                  ),
                ]),
              ),
            ),

          // 4. Section Divider Label
          if (controller.results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space16, AppTheme.space16, AppTheme.space12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Recent Scans',
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: 16,
                    color: AppTheme.textLightColor.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

          // 5. Historical Items
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space16, 0, AppTheme.space16, AppTheme.space32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final result = controller.results[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space16),
                    child: RepaintBoundary(
                      child: _HistoryItemCard(result: result, index: index),
                    ),
                  );
                },
                childCount: controller.results.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHIMMER LOADING ────────────────────────────────────────────────
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.space16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space16),
        child: Shimmer.fromColors(
          baseColor: AppTheme.surfaceActive.withOpacity(0.15),
          highlightColor: AppTheme.surfaceActive.withOpacity(0.05),
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              color: AppTheme.surfaceActive,
              borderRadius: AppTheme.borderRadiusLarge,
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceActive.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLarge),
                      bottomLeft: Radius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 18, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.borderRadiusPill)),
                        const SizedBox(height: 12),
                        Container(height: 12, width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.borderRadiusPill)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── INSIGHTS HEADER ────────────────────────────────────────────────
  Widget _buildInsightsHeader(HistoryController controller) {
    final insights = controller.insights;
    
    // Empty Insights State
    if (insights == null || insights.totalScans == 0) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: PetMoodGlass(
          color: AppTheme.surfaceActive,
          opacity: 0.4,
          borderRadius: AppTheme.borderRadiusExtraLarge,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: AppTheme.borderRadiusMedium,
                      ),
                      child: const Icon(Icons.insights_rounded, color: AppTheme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Text(
                      'Behavior Insights',
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLow.withValues(alpha: 0.3),
                    borderRadius: AppTheme.borderRadiusLarge,
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                  ),
                  child: Text(
                    'Scan more videos to unlock behavioral insights.\nWe need a bit more data to analyze patterns.',
                    textAlign: TextAlign.center,
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.textLightColor, 
                      height: 1.5, 
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Active Insights State
    final topEmotion = EmotionStyle.fromEmotion(insights.mostFrequentEmotion);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space12, AppTheme.space16, AppTheme.space16),
      child: PetMoodGlass(
        color: topEmotion.color,
        opacity: 0.12, // Slightly more visible for the main header
        borderRadius: AppTheme.borderRadiusExtraLarge,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: topEmotion.color.withOpacity(0.15),
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    child: Icon(Icons.insights_rounded, color: topEmotion.color, size: 24),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Text(
                    'Behavior Insights',
                    style: AppTheme.titleStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space12, horizontal: AppTheme.space16),
                decoration: BoxDecoration(
                  color: topEmotion.color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.borderRadiusLarge,
                ),
                child: Text(
                  controller.cachedInsights?.summary ?? 'Your dog has been mostly ${topEmotion.label} recently🐾',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 14,
                    color: topEmotion.color,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              Row(
                children: [
                  Expanded(
                    child: _InsightStatCard(
                      icon: Icons.analytics_outlined,
                      value: insights.totalScans.toString(),
                      label: 'Total Scans',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: _InsightStatCard(
                      icon: topEmotion.icon,
                      value: topEmotion.label,
                      label: 'Most Frequent',
                      color: topEmotion.color,
                    ),
                  ),
                ],
              ),
              if (insights.emotionDistribution.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space20),
                _EmotionDistributionBar(distribution: insights.emotionDistribution),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
        child: StaggeredEntrance(
          children: [
            Lottie.asset(
              LottieRegistry.get('dog_1'),
              width: 220,
              height: 220,
              repeat: true,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'No Scans Found 🐾',
              textAlign: TextAlign.center,
              style: AppTheme.titleStyle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              'Your pet\'s emotional history will appear here once you start scanning.',
              textAlign: TextAlign.center,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 15,
                color: AppTheme.textLightColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.space32),
            SquishButton(
              onPressed: () {
                FurHaptics.impact();
                context.goHome();
              },
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: AppTheme.borderRadiusPill,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Start Scanning',
                      style: AppTheme.titleStyle.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ERROR STATE ────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, HistoryController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              controller.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppTheme.space24),
            ElevatedButton.icon(
              onPressed: () => controller.loadHistory(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: AppTheme.primaryButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(AppTheme.errorColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HISTORY ITEM CARD — Enhanced with emotion badge, relative time, confidence
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _HistoryItemCard extends StatelessWidget {
  final DetectionResult result;
  final int index;
  
  const _HistoryItemCard({required this.result, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final emotionStyle = EmotionStyle.fromEmotion(result.emotion);
    final relativeTime = _formatRelativeTime(result.timestamp);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: PetMoodGlass(
        color: AppTheme.surfaceActive,
        opacity: 0.6,
        borderRadius: AppTheme.borderRadiusLarge,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusLarge,
          onTap: () {
            FurHaptics.tap();
            context.pushResult(result.uuid);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                // Thumbnail with emotion color border
                Hero(
                  tag: 'history_thumb_${result.uuid}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.borderRadiusMedium,
                      border: Border.all(
                        color: emotionStyle.color.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: emotionStyle.color.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: _buildThumbnail(result),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emotion badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: emotionStyle.color.withValues(alpha: 0.12),
                          borderRadius: AppTheme.borderRadiusPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emotionStyle.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              emotionStyle.label,
                              style: AppTheme.captionStyle.copyWith(
                                fontSize: 12,
                                color: emotionStyle.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Relative timestamp
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppTheme.textLightColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            relativeTime,
                            style: AppTheme.captionStyle.copyWith(
                              fontSize: 11,
                              color: AppTheme.textLightColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textLightColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(DetectionResult result) {
    // 1. Try local image if not video
    if (!result.isVideo && result.mediaPath.isNotEmpty) {
      final file = File(result.mediaPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    
    // 2. Try local frame image if video
    if (result.isVideo && result.frameImagePath != null) {
      final file = File(result.frameImagePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    // 3. Try network fallback
    if (result.frameImageUrl != null && result.frameImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: result.frameImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: AppTheme.surfaceElevated,
          highlightColor: AppTheme.surfaceBase,
          child: Container(color: AppTheme.surfaceActive),
        ),
        errorWidget: (context, url, error) => _buildEmojiFallback(result.emotion),
      );
    }

    // 4. Emoji fallback
    return _buildEmojiFallback(result.emotion);
  }

  Widget _buildEmojiFallback(String emotion) {
    final emotionStyle = EmotionStyle.fromEmotion(emotion);
    return Container(
      color: emotionStyle.color.withValues(alpha: 0.08),
      child: Center(
        child: Text(emotionStyle.emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// REUSABLE INSIGHT STAT CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _InsightStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InsightStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PetMoodGlass(
      color: color,
      opacity: 0.08,
      borderRadius: AppTheme.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              value,
              style: AppTheme.titleStyle.copyWith(
                fontSize: 16,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: AppTheme.captionStyle.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppTheme.textLightColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EMOTION DISTRIBUTION BAR (compact visualization)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _EmotionDistributionBar extends StatelessWidget {
  final Map<String, int> distribution;
  const _EmotionDistributionBar({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    // Sort by count descending
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked bar
        ClipRRect(
          borderRadius: AppTheme.borderRadiusPill,
          child: SizedBox(
            height: 8,
            child: Row(
              children: sorted.map((entry) {
                final ratio = entry.value / total;
                final style = EmotionStyle.fromEmotion(entry.key);
                return Expanded(
                  flex: (ratio * 100).round().clamp(1, 100),
                  child: Container(color: style.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        // Legend
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: 4,
          children: sorted.take(4).map((entry) {
            final style = EmotionStyle.fromEmotion(entry.key);
            final pct = ((entry.value / total) * 100).round();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: style.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${style.label} $pct%',
                  style: AppTheme.captionStyle.copyWith(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
