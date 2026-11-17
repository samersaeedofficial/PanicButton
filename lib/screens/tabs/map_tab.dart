import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final loc = state.currentLocation;
    final center = loc != null
        ? LatLng(loc.latitude, loc.longitude)
        : const LatLng(33.6844, 73.0479); // Default fallback

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.panicbutton.app',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: loc?.accuracy ?? 30,
                  useRadiusInMeter: true,
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(blurRadius: 8, color: Colors.black26),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Clean Find My Device-style bottom sheet
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.currentUser?.name ?? 'Protected Device',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          loc?.isLastKnownFallback == true
                              ? 'Last Known Outdoor'
                              : 'Live GPS',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc != null
                        ? 'Lat: ${loc.latitude.toStringAsFixed(5)}  •  Lng: ${loc.longitude.toStringAsFixed(5)}'
                        : 'Waiting for GPS fix...',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
