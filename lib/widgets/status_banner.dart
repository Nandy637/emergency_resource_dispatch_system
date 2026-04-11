// ============================================================
// widget: status_banner.dart
// Animated top banner that shows the current emergency status
// with a colour, icon, and label. Colour changes per status.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  final String status;
  final String? eta; // e.g. "~4 min"

  const StatusBanner({super.key, required this.status, this.eta});

  // ── status metadata ───────────────────────────────────────
  static IconData _iconFor(String s) {
    switch (s) {
      case 'assigned':  return Icons.check_circle_outline;
      case 'onTheWay':  return Icons.directions_car;
      case 'arrived':   return Icons.location_on;
      case 'completed': return Icons.task_alt;
      default:          return Icons.hourglass_empty; // pending
    }
  }

  static String _labelFor(String s) {
    switch (s) {
      case 'assigned':  return 'Responder Assigned';
      case 'onTheWay':  return 'Responder On the Way';
      case 'arrived':   return 'Responder Has Arrived';
      case 'completed': return 'Incident Completed';
      default:          return 'Searching for Responder…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final icon  = _iconFor(status);
    final label = _labelFor(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.4))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (eta != null && status == 'onTheWay')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                'ETA $eta',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
