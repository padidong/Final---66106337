import 'package:flutter/material.dart';

/// Badge widget showing sync status: Online (synced) or Offline (not synced)
class SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  final bool compact;

  const SyncStatusBadge({
    super.key,
    required this.isSynced,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSynced ? Colors.green : Colors.orange;
    final icon = isSynced ? Icons.cloud_done : Icons.cloud_off;
    final text = isSynced ? 'Online' : 'Offline';

    if (compact) {
      return Icon(icon, size: 16, color: color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
