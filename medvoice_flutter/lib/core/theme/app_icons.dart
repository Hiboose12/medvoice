import 'package:flutter/material.dart';

/// Centralized icon mappings for MedVoice application features.
abstract final class AppIcons {
  // Navigation
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData dashboardSolid = Icons.dashboard;
  static const IconData feed = Icons.forum_outlined;
  static const IconData feedSolid = Icons.forum;
  static const IconData post = Icons.post_add_outlined;
  static const IconData postSolid = Icons.post_add;
  static const IconData profile = Icons.account_circle_outlined;
  static const IconData profileSolid = Icons.account_circle;

  // Features
  static const IconData complaints = Icons.assignment_outlined;
  static const IconData chat = Icons.chat_bubble_outline;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsActive = Icons.notifications_active;
  static const IconData settings = Icons.settings_outlined;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData logout = Icons.logout_outlined;

  // Actions
  static const IconData add = Icons.add;
  static const IconData arrowRight = Icons.chevron_right_rounded;
  static const IconData arrowBack = Icons.arrow_back_ios_new_rounded;
  static const IconData search = Icons.search;
  static const IconData scan = Icons.document_scanner_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData copy = Icons.copy_rounded;

  // Semantics / Indicators
  static const IconData verified = Icons.verified_rounded;
  static const IconData pending = Icons.pending_actions_outlined;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData success = Icons.check_circle_outline_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData security = Icons.shield_outlined;
}
