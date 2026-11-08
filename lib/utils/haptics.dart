import 'package:flutter/services.dart';

/// Fire-and-forget haptics that never throw (no vibration hardware, desktop,
/// or widget tests without a platform channel).
class Haptics {
  Haptics._();

  static void light() => _run(HapticFeedback.lightImpact);
  static void medium() => _run(HapticFeedback.mediumImpact);
  static void heavy() => _run(HapticFeedback.heavyImpact);

  static void _run(Future<void> Function() call) {
    try {
      call().catchError((_) {});
    } catch (_) {}
  }
}
