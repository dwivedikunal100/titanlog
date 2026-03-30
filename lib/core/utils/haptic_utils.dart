import 'package:flutter/services.dart';

class HapticUtils {
  HapticUtils._();

  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Used when a set is completed / checkmark tapped
  static void setCompleted() {
    HapticFeedback.mediumImpact();
  }

  /// Used when a PR is achieved
  static void prAchieved() {
    HapticFeedback.heavyImpact();
  }

  /// Used for button taps
  static void buttonTap() {
    HapticFeedback.lightImpact();
  }

  /// Used for swipe actions
  static void swipeAction() {
    HapticFeedback.mediumImpact();
  }

  /// Used when rest timer finishes
  static void timerComplete() {
    HapticFeedback.heavyImpact();
  }
}
