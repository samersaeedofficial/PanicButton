import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/alert_log.dart';
import '../../providers/app_state_provider.dart';

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  Color _badgeColor(AlertType type) {
    switch (type) {
      case AlertType.safeCheckIn:
        return Colors.green;
      case AlertType.silentSos:
        return Colors.orange;
      case AlertType.loudSiren:
        return Colors.red;
      case AlertType.antiSnatch:
        return Colors.purple;
      case AlertType.locationShare:
        return Colors.blue;
      case AlertType.callMember:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final logs = state.logs;

    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'No alert logs yet.\nPress any SOS or Check-in button to record.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = logs[index];
        final color = _badgeColor(log.type);
        final formattedTime =
            DateFormat('dd MMM yyyy • hh:mm:ss a').format(log.timestamp);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Icons.notifications_active, color: color),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    log.type.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.sentVia,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(log.message),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (log.latitude != null && log.longitude != null)
                  Text(
                    'Location: ${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}'
                    '${log.isLastKnownLocation ? ' (Last Known)' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                if (log.audioPath != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        state.audioService.playClip(log.audioPath!),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Play Recorded Audio'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
