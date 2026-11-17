import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/alert_log.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  String _selectedFilter = 'All';
  String? _currentlyPlayingPath;

  Color _badgeColor(AlertType type) {
    switch (type) {
      case AlertType.safeCheckIn:
        return AppColors.safeGreen;
      case AlertType.silentSos:
        return AppColors.silentAmber;
      case AlertType.loudSiren:
        return AppColors.primary;
      case AlertType.antiSnatch:
        return AppColors.snatchPurple;
      case AlertType.locationShare:
        return AppColors.infoBlue;
      case AlertType.callMember:
        return Colors.teal;
    }
  }

  IconData _badgeIcon(AlertType type) {
    switch (type) {
      case AlertType.safeCheckIn:
        return Icons.check_circle_rounded;
      case AlertType.silentSos:
        return Icons.visibility_off_rounded;
      case AlertType.loudSiren:
        return Icons.warning_amber_rounded;
      case AlertType.antiSnatch:
        return Icons.phonelink_erase_rounded;
      case AlertType.locationShare:
        return Icons.share_location_rounded;
      case AlertType.callMember:
        return Icons.phone_in_talk_rounded;
    }
  }

  Future<void> _openCoordinates(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final allLogs = state.logs;

    final filteredLogs = allLogs.where((log) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'SOS') {
        return log.type == AlertType.loudSiren || log.type == AlertType.silentSos;
      }
      if (_selectedFilter == 'Check-in') {
        return log.type == AlertType.safeCheckIn;
      }
      if (_selectedFilter == 'Anti-Snatch') {
        return log.type == AlertType.antiSnatch;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', allLogs.length),
                const SizedBox(width: 8),
                _filterChip('SOS', allLogs.where((l) => l.type == AlertType.loudSiren || l.type == AlertType.silentSos).length),
                const SizedBox(width: 8),
                _filterChip('Check-in', allLogs.where((l) => l.type == AlertType.safeCheckIn).length),
                const SizedBox(width: 8),
                _filterChip('Anti-Snatch', allLogs.where((l) => l.type == AlertType.antiSnatch).length),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),

        // List of logs
        Expanded(
          child: filteredLogs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history_toggle_off_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Alerts in History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'All emergency alerts, audio recordings and safe check-ins will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLogs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final color = _badgeColor(log.type);
                    final icon = _badgeIcon(log.type);
                    final formattedTime =
                        DateFormat('dd MMM yyyy • hh:mm:ss a').format(log.timestamp);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Type + Sent Via tag
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.type.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Text(
                                  log.sentVia,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Text(
                            log.message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),

                          // Location coordinates link
                          if (log.latitude != null && log.longitude != null) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => _openCoordinates(log.latitude!, log.longitude!),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: log.isLastKnownLocation ? Colors.amber.shade800 : AppColors.infoBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}'
                                      '${log.isLastKnownLocation ? ' (Last Known Outdoor)' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                        color: log.isLastKnownLocation ? Colors.amber.shade900 : AppColors.infoBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Audio recording player
                          if (log.audioPath != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _currentlyPlayingPath == log.audioPath
                                          ? Icons.stop_circle_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                    onPressed: () async {
                                      if (_currentlyPlayingPath == log.audioPath) {
                                        await state.audioService.stopPlayback();
                                        setState(() => _currentlyPlayingPath = null);
                                      } else {
                                        setState(() => _currentlyPlayingPath = log.audioPath);
                                        await state.audioService.playClip(log.audioPath!);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Emergency Voice Clip',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          'Recorded during panic trigger',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.graphic_eq_rounded, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String title, int count) {
    final isSelected = _selectedFilter == title;
    return ChoiceChip(
      label: Text('$title ($count)'),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = title);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.borderLight,
      ),
    );
  }
}
