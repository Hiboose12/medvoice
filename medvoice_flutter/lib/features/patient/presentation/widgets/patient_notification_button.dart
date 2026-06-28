import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/domain/models/dashboard_stats.dart';
import 'package:medvoice_flutter/features/patient/presentation/utils/time_helper.dart';

class PatientNotificationButton extends StatelessWidget {
  const PatientNotificationButton({
    super.key,
    required this.notifications,
    required this.showPanel,
    required this.onToggle,
    required this.onClose,
    required this.onMarkRead,
  });

  final List<PatientNotification> notifications;
  final bool showPanel;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final ValueChanged<int> onMarkRead;

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => !n.isRead).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: PatientColors.card,
          shape: const CircleBorder(
            side: BorderSide(color: PatientColors.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onToggle,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.notifications_outlined,
                size: 22,
                color: PatientColors.textMuted,
              ),
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: PatientColors.card, width: 2),
              ),
            ),
          ),
        if (showPanel)
          Positioned(
            top: 48,
            right: 0,
            child: _NotificationPanel(
              notifications: notifications,
              unread: unread,
              onClose: onClose,
              onMarkRead: onMarkRead,
            ),
          ),
      ],
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({
    required this.notifications,
    required this.unread,
    required this.onClose,
    required this.onMarkRead,
  });

  final List<PatientNotification> notifications;
  final int unread;
  final VoidCallback onClose;
  final ValueChanged<int> onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: PatientColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PatientColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0x80FAFAFA),
                border: Border(bottom: BorderSide(color: PatientColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PatientColors.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: PatientColors.border),
                    ),
                    child: Text(
                      '$unread new',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PatientColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: notifications.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No new notifications',
                        style: TextStyle(
                          fontSize: 14,
                          color: PatientColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return InkWell(
                          onTap: () => onMarkRead(n.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: PatientColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.message,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PatientColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatRelativeTime(n.createdAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFA1A1AA),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0x80FAFAFA),
                border: Border(top: BorderSide(color: PatientColors.cardBorder)),
              ),
              child: Text(
                'View all notifications',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
