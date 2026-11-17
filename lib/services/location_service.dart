import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSnapshot {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isLastKnownFallback;

  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.isLastKnownFallback = false,
  });
}

class LocationService {
  static const _lastLatKey = 'last_known_outdoor_lat';
  static const _lastLngKey = 'last_known_outdoor_lng';
  static const _lastAccKey = 'last_known_outdoor_acc';
  static const _lastTimeKey = 'last_known_outdoor_time';

  StreamSubscription<Position>? _positionSub;
  LocationSnapshot? _currentLocation;
  LocationSnapshot? _lastKnownOutdoorLocation;

  LocationSnapshot? get currentLocation => _currentLocation;
  LocationSnapshot? get lastKnownOutdoorLocation => _lastKnownOutdoorLocation;

  Future<void> init() async {
    await _loadLastKnownOutdoor();
  }

  Future<void> _loadLastKnownOutdoor() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_lastLatKey);
    final lng = prefs.getDouble(_lastLngKey);
    final acc = prefs.getDouble(_lastAccKey) ?? 25.0;
    final timeStr = prefs.getString(_lastTimeKey);

    if (lat != null && lng != null && timeStr != null) {
      _lastKnownOutdoorLocation = LocationSnapshot(
        latitude: lat,
        longitude: lng,
        accuracy: acc,
        timestamp: DateTime.parse(timeStr),
        isLastKnownFallback: true,
      );
    }
  }

  Future<void> _saveLastKnownOutdoor(Position pos) async {
    // Consider outdoor if accuracy is reasonably good (< 50m)
    if (pos.accuracy <= 50.0) {
      final snapshot = LocationSnapshot(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: DateTime.now(),
        isLastKnownFallback: true,
      );
      _lastKnownOutdoorLocation = snapshot;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLatKey, pos.latitude);
      await prefs.setDouble(_lastLngKey, pos.longitude);
      await prefs.setDouble(_lastAccKey, pos.accuracy);
      await prefs.setString(_lastTimeKey, snapshot.timestamp.toIso8601String());
    }
  }

  Future<LocationSnapshot?> getBestAvailableLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _lastKnownOutdoorLocation;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _lastKnownOutdoorLocation;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      _currentLocation = LocationSnapshot(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: DateTime.now(),
        isLastKnownFallback: false,
      );
      await _saveLastKnownOutdoor(pos);
      return _currentLocation;
    } catch (_) {
      // If GPS fails (e.g., inside basement/building), return Last Known Outdoor Location
      return _currentLocation ?? _lastKnownOutdoorLocation;
    }
  }

  void startContinuousTracking(void Function(LocationSnapshot) onUpdate) {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
      final snap = LocationSnapshot(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: DateTime.now(),
      );
      _currentLocation = snap;
      await _saveLastKnownOutdoor(pos);
      onUpdate(snap);
    });
  }

  void stopContinuousTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void dispose() {
    stopContinuousTracking();
  }
}
