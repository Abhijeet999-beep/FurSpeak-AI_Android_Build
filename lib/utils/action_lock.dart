import 'dart:async';
import 'package:flutter/foundation.dart';

/// Global action lock for the FurSpeak AI application.
/// Prevents multiple async actions from being executed simultaneously,
/// such as double-tapping a button that triggers a camera intent or network request.
class ActionLock {
  bool _isLocked = false;
  
  /// Returns whether an action is currently running.
  bool get isLocked => _isLocked;

  /// Executes [action] if the lock is not currently active.
  /// Automatically releases the lock when [action] completes.
  Future<void> execute(Future<void> Function() action) async {
    if (_isLocked) {
      debugPrint('ActionLock: Execution blocked - already locked.');
      return;
    }
    debugPrint('ActionLock: Locking action...');
    _isLocked = true;
    try {
      await action();
    } catch (e) {
      debugPrint('ActionLock: Error during action: $e');
    } finally {
      _isLocked = false;
      debugPrint('ActionLock: Action released.');
    }
  }

  /// Manually lock. Useful for navigation transitions or long-running sync operations.
  void lock() => _isLocked = true;
  
  /// Manually unlock.
  void unlock() => _isLocked = false;
}

/// Global instance to be used across the app.
final ActionLock globalActionLock = ActionLock();
