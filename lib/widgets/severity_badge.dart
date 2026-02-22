import 'package:flutter/material.dart';
import '../constants/theme.dart';

/// A reusable badge widget that displays a severity level (High / Medium / Low)
/// with the corresponding color. Used in IncidentListScreen and SearchFilterScreen.
class SeverityBadge extends StatelessWidget {
  final String? severity;

  const SeverityBadge({super.key, required this.severity});

  Color get _color {
    switch (severity) {
      case 'High':
        return AppTheme.severityHigh;
      case 'Medium':
        return AppTheme.severityMedium;
      case 'Low':
        return AppTheme.severityLow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        severity ?? 'N/A',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
