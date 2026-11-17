import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/hardware_status.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();

  void _recenter(LatLng point) {
    _mapController.move(point, 16.5);
  }

  Future<void> _openExternalMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final loc = state.currentLocation;
    final hw = state.hardwareStatus;
    final userName = state.currentUser?.name ?? 'Protected Device';

    final center = loc != null
        ? LatLng(loc.latitude, loc.longitude)
        : const LatLng(33.6844, 73.0479); // Default fallback

    final isOutdoorFallback = loc?.isLastKnownFallback ?? false;

    return Stack(
      children: [
        // Fullscreen OpenStreetMap layer
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16,
            minZoom: 4,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.panicbutton.app',
            ),
            // Accuracy radius circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: loc?.accuracy ?? 35,
                  useRadiusInMeter: true,
                  color: isOutdoorFallback
                      ? Colors.amber.withValues(alpha: 0.18)
                      : AppColors.infoBlue.withValues(alpha: 0.18),
                  borderColor: isOutdoorFallback ? Colors.amber : AppColors.infoBlue,
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            // Find My Device Pulsing Radar Marker
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isOutdoorFallback ? Colors.amber : AppColors.primary)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOutdoorFallback ? Colors.amber.shade700 : AppColors.primary,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Floating Top Status Header (Google Find My Device style)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hw.isConnected ? AppColors.safeGreen : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isOutdoorFallback
                            ? 'Inside building/basement • Using Last Outdoor GPS'
                            : 'Live GPS Active • ${hw.satelliteCount} Satellites locked',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOutdoorFallback ? Colors.amber.shade900 : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                  tooltip: 'Recenter to device',
                  onPressed: () => _recenter(center),
                ),
              ],
            ),
          ),
        ),

        // Floating Bottom Sheet (Find My Device Info & Controls)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top device status row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                hw.deviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isOutdoorFallback ? Colors.amber : AppColors.safeGreen)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isOutdoorFallback ? 'LAST KNOWN' : 'LIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isOutdoorFallback ? Colors.amber.shade900 : AppColors.safeGreenDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Battery ${hw.batteryPercent}% • ${hw.mode.label}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Coordinates pill with copy button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc != null
                              ? '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'
                              : 'Waiting for coordinates...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (loc != null)
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: '${loc.latitude}, ${loc.longitude}'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coordinates copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Action Buttons
                Row(
                  children: [
                    // Sound Siren Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          state.hardwareService.sendCommandToEsp32('BEEP_SHORT');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Buzzer sound triggered on ESP32!')),
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        label: const Text('Ring Device'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Open in Google Maps
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: loc != null
                            ? () => _openExternalMap(loc.latitude, loc.longitude)
                            : null,
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Directions'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
