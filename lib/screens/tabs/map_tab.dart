import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/hardware_status.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

enum MapLayerType { googleRoadmap, googleSatellite, googleTerrain }

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  MapLayerType _selectedLayer = MapLayerType.googleRoadmap;
  bool _showOverlays = true;

  void _recenter(LatLng point) {
    _mapController.move(point, 16.5);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  String _getTileUrl() {
    switch (_selectedLayer) {
      case MapLayerType.googleRoadmap:
        // Real Google Maps clean standard roadmap with labels & streets
        return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapLayerType.googleSatellite:
        // Real Google Satellite Hybrid (HD Satellite + Street names)
        return 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapLayerType.googleTerrain:
        // Real Google Maps Terrain clean view
        return 'https://mt{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
    }
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
        // Google Maps Clean Tiles Layer
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16.0,
            minZoom: 3,
            maxZoom: 20,
          ),
          children: [
            TileLayer(
              key: ValueKey(_selectedLayer),
              urlTemplate: _getTileUrl(),
              subdomains: const ['0', '1', '2', '3'],
              userAgentPackageName: 'com.panicbutton.app',
              maxZoom: 20,
            ),
            // Accuracy radius circle (Google Maps style cyan/blue wash)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: loc?.accuracy ?? 35,
                  useRadiusInMeter: true,
                  color: (isOutdoorFallback ? Colors.amber : const Color(0xFF4285F4))
                      .withValues(alpha: 0.18),
                  borderColor: isOutdoorFallback ? Colors.amber : const Color(0xFF1A73E8),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            // Google Find My Device Live Pulsing Pin Marker
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isOutdoorFallback ? Colors.amber : AppColors.primary)
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      // Core pin circle with drop shadow
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isOutdoorFallback
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFFEA4335), Color(0xFFC5221F)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: isOutdoorFallback ? Colors.amber.shade700 : null,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 24,
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
        if (_showOverlays)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hw.isConnected ? AppColors.safeGreen : Colors.orange,
                    boxShadow: [
                      BoxShadow(
                        color: (hw.isConnected ? AppColors.safeGreen : Colors.orange)
                            .withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isOutdoorFallback
                            ? 'Inside building • Using Last Known Outdoor GPS'
                            : 'Live Google GPS • ${hw.satelliteCount} Satellites locked',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOutdoorFallback ? Colors.amber.shade900 : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Google Maps indicator badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_rounded, size: 14, color: Color(0xFF4285F4)),
                      const SizedBox(width: 4),
                      Text(
                        _selectedLayer == MapLayerType.googleSatellite ? 'Satellite' : 'Google Maps',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Map Controls on Right Side (Fullscreen + Zoom + Layer Toggle + Recenter)
        Positioned(
          right: 16,
          top: _showOverlays ? 86 : 16,
          child: Column(
            children: [
              // Fullscreen Toggle Button (Hides top and bottom bars)
              FloatingActionButton.small(
                heroTag: 'map_fullscreen_toggle',
                backgroundColor: _showOverlays ? Colors.white : const Color(0xFF1A73E8),
                foregroundColor: _showOverlays ? AppColors.textPrimary : Colors.white,
                elevation: 3,
                tooltip: _showOverlays ? 'Full Map View (Hide Bars)' : 'Show Info Bars',
                onPressed: () {
                  setState(() => _showOverlays = !_showOverlays);
                },
                child: Icon(
                  _showOverlays ? Icons.fullscreen_rounded : Icons.fullscreen_exit_rounded,
                  size: 22,
                  color: _showOverlays ? const Color(0xFF1A73E8) : Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Map Style Switcher (Roadmap vs Satellite)
              FloatingActionButton.small(
                heroTag: 'map_layer_toggle',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 3,
                tooltip: 'Switch Map Style (Clean / Satellite)',
                onPressed: () {
                  setState(() {
                    if (_selectedLayer == MapLayerType.googleRoadmap) {
                      _selectedLayer = MapLayerType.googleSatellite;
                    } else {
                      _selectedLayer = MapLayerType.googleRoadmap;
                    }
                  });
                },
                child: Icon(
                  _selectedLayer == MapLayerType.googleSatellite
                      ? Icons.layers_rounded
                      : Icons.satellite_alt_rounded,
                  size: 20,
                  color: const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),

              // Zoom In
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 3,
                tooltip: 'Zoom In',
                onPressed: _zoomIn,
                child: const Icon(Icons.add_rounded, size: 20),
              ),
              const SizedBox(height: 6),

              // Zoom Out
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 3,
                tooltip: 'Zoom Out',
                onPressed: _zoomOut,
                child: const Icon(Icons.remove_rounded, size: 20),
              ),
              const SizedBox(height: 8),

              // Recenter Button
              FloatingActionButton.small(
                heroTag: 'map_recenter',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A73E8),
                elevation: 3,
                tooltip: 'Recenter to device',
                onPressed: () => _recenter(center),
                child: const Icon(Icons.my_location_rounded, size: 20),
              ),
            ],
          ),
        ),

        // Google Find My Device Style Bottom Sheet Card
        if (_showOverlays)
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
                                  isOutdoorFallback ? 'LAST OUTDOOR' : 'LIVE ACCURATE',
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
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFEA4335)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc != null
                              ? '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'
                              : 'Acquiring GPS fix...',
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

                // Bottom Action Buttons: Ring Device & Open in Google Maps
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
                        label: const Text('Google Maps'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
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
