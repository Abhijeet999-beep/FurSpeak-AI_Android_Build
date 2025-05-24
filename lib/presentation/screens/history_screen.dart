import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:furspeak_ai/data/models/emotion_history.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/presentation/screens/guest_mode_warning_screen.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/widgets/root_nav_shell.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<EmotionHistory>> _historyFuture;
  final _authService = AuthService();
  String? _selectedEmotion;
  DateTimeRange? _selectedDateRange;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkAndLoadHistory();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _checkAndLoadHistory() {
    if (!_authService.isGuest) {
      try {
        final isar = GetIt.instance<Isar>();
        _historyFuture =
            isar.emotionHistorys.where().sortByTimestampDesc().findAll();
      } catch (e) {
        print('[HistoryScreen] Error loading history: $e');
        _historyFuture = Future.value([]);
      }
    } else {
      _historyFuture = Future.value([]);
    }
  }

  void _onFilterChanged() {
    HapticFeedback.selectionClick();
    setState(() {}); // Stub: would filter results in a real implementation
  }

  @override
  Widget build(BuildContext context) {
    // Guest access is now handled by route guards and RootNavShell
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(
          'Emotion History',
          style: AppTheme.titleStyle.copyWith(color: AppTheme.primaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: 0, // TODO: Implement history items
          itemBuilder: (context, index) {
            return const SizedBox(); // TODO: Implement history item widget
          },
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return AppTheme.successColor;
      case 'alert':
        return AppTheme.accentColor;
      case 'angry':
        return AppTheme.errorColor;
      case 'relax':
        return AppTheme.primaryColor;
      default:
        return AppTheme.textLightColor;
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😄';
      case 'alert':
        return '⚠️';
      case 'angry':
        return '😠';
      case 'relax':
        return '😌';
      default:
        return '🐶';
    }
  }

  Widget _placeholderImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.textLightColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          const Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
