import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/alert_log.dart';
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
  bool _showRouteLine = true;
  bool _isAcquiringGps = false;

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
        return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapLayerType.googleSatellite:
        return 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapLayerType.googleTerrain:
        return 'https://mt{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
    }
  }

  Future<void> _openExternalMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _acquireGps(AppStateProvider state) async {
    setState(() => _isAcquiringGps = true);
    try {
      await state.requestCurrentLocation();
    } finally {
      if (mounted) setState(() => _isAcquiringGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final loc = state.currentLocation;
    final hw = state.hardwareStatus;
    final userName = state.currentUser?.name ?? 'Protected Device';
    final route = state.routePoints;
    final logsWithLoc = state.logs.where((l) => l.latitude != null && l.longitude != null).toList();

    // Check if any location or previous route data is available
    final hasLocationData = loc != null || route.isNotEmpty || logsWithLoc.isNotEmpty;

    // IF NO LOCATION DATA EXISTS: DO NOT SHOW MAP, SHOW CLEAN EMPTY STATE (Requirement)
    if (!hasLocationData) {
      return _buildNoLocationState(context, state);
    }

    // Determine center coordinate
    final LatLng center;
    if (loc != null) {
      center = LatLng(loc.latitude, loc.longitude);
    } else if (route.isNotEmpty) {
      center = route.last;
    } else {
      center = LatLng(logsWithLoc.first.latitude!, logsWithLoc.first.longitude!);
    }

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

            // Continuous Journey Route Polyline (Covered distance from start to current)
            if (_showRouteLine && route.length >= 2)
              PolylineLayer(
                polylines: [
                  // Outer glow
                  Polyline(
                    points: route,
                    strokeWidth: 7.0,
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
                  ),
                  // Core Google Blue route
                  Polyline(
                    points: route,
                    strokeWidth: 4.5,
                    color: const Color(0xFF1A73E8),
                  ),
                ],
              ),

            // Accuracy radius circle (Google Maps style cyan/blue wash)
            if (loc != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: loc.accuracy,
                    useRadiusInMeter: true,
                    color: (isOutdoorFallback ? Colors.amber : const Color(0xFF4285F4))
                        .withValues(alpha: 0.18),
                    borderColor: isOutdoorFallback ? Colors.amber : const Color(0xFF1A73E8),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            // Markers Layer: Start Point, Waypoints/Previous Alerts, Current Pin
            MarkerLayer(
              markers: [
                // 1. Journey Start Point Marker (if route exists and differs from current)
                if (route.length >= 2)
                  Marker(
                    point: route.first,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.safeGreenDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ),

                // 2. Previous Alert History Pins along the route
                ...logsWithLoc.take(6).map((logItem) {
                  final logPoint = LatLng(logItem.latitude!, logItem.longitude!);
                  final isSos = logItem.type == AlertType.loudSiren || logItem.type == AlertType.silentSos;
                  return Marker(
                    point: logPoint,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSos ? Colors.red.shade700 : Colors.teal.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(
                        isSos ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                }),

                // 3. Current Live Google Find My Device Pulsing Marker
                Marker(
                  point: center,
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isOutdoorFallback ? Colors.amber : AppColors.primary)
                              .withValues(alpha: 0.22),
                        ),
                      ),
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
                            BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
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

        // Floating Top Status Header & Journey Distance Banner
        if (_showOverlays)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top device status row
                Container(
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

                // Journey Distance & Route Points Chip (if path covered exists)
                if (route.length >= 2) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.route_rounded, color: Color(0xFF4285F4), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Traveled: ${state.totalDistanceKm.toStringAsFixed(2)} km • ${route.length} GPS Points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showRouteLine = !_showRouteLine),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              _showRouteLine ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Floating Map Controls on Right Side (Fullscreen + Zoom + Layer Toggle + Recenter)
        Positioned(
          right: 16,
          top: _showOverlays ? (route.length >= 2 ? 134 : 86) : 16,
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
                                : '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)} (Last Seen)',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: '${center.latitude}, ${center.longitude}'),
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
                          onPressed: () => _openExternalMap(center.latitude, center.longitude),
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

  // High-Design Empty State when NO location or previous history exists
  Widget _buildNoLocationState(BuildContext context, AppStateProvider state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Radar Pulse Aura Graphic
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F0FE),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.radar_rounded,
                    size: 54,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'No Location History Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Neither live GPS coordinates nor previous travel history has been recorded yet.\n\nOnce location sharing is activated, an emergency button is pressed, or GPS locks onto satellites, your live journey path and distance will appear on Google Maps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // Action 1: Acquire Live GPS
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isAcquiringGps ? null : () => _acquireGps(state),
                  icon: _isAcquiringGps
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location_rounded, size: 20),
                  label: Text(_isAcquiringGps ? 'Acquiring GPS Fix...' : 'Acquire Current GPS Fix'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action 2: Start Real-time Continuous Tracking
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => state.toggleContinuousLocationSharing(true),
                  icon: const Icon(Icons.share_location_rounded, size: 20, color: AppColors.primary),
                  label: const Text(
                    'Start Real-Time Tracking',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action 3: Simulate Demo Journey
              TextButton.icon(
                onPressed: () => state.simulateJourneyStep(),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text('Test with Demo Journey Path'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
