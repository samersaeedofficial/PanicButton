import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/alert_log.dart';
import '../models/button_action_config.dart';
import '../models/family_member.dart';
import '../models/hardware_status.dart';
import '../models/user_model.dart';
import '../services/alert_dispatcher_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/background_service.dart';
import '../services/database_service.dart';
import '../services/hardware_service.dart';
import '../services/location_service.dart';

class AppStateProvider extends ChangeNotifier {
  final AuthService authService = AuthService();
  final HardwareService hardwareService = HardwareService();
  final LocationService locationService = LocationService();
  final AudioService audioService = AudioService();
  late final AlertDispatcherService alertDispatcher;

  AppUser? _currentUser;
  List<FamilyMember> _members = [];
  List<AlertLog> _logs = [];
  HardwareStatus _hardwareStatus = HardwareStatus(lastUpdated: DateTime.now());
  LocationSnapshot? _currentLocation;
  final List<LatLng> _routePoints = [];
  bool _continuousLocationSharing = false;
  bool _backgroundServiceRunning = false;
  bool _isInitialized = false;

  final Map<ButtonPressType, ButtonActionConfig> _buttonConfigs = {
    ButtonPressType.single: const ButtonActionConfig(
      pressType: ButtonPressType.single,
      actionType: ButtonActionType.safeCheckIn,
    ),
    ButtonPressType.doublePress: const ButtonActionConfig(
      pressType: ButtonPressType.doublePress,
      actionType: ButtonActionType.silentSos,
    ),
    ButtonPressType.longPress: const ButtonActionConfig(
      pressType: ButtonPressType.longPress,
      actionType: ButtonActionType.loudSiren,
      holdDurationSeconds: 2,
    ),
  };

  StreamSubscription<HardwareStatus>? _hwSub;
  StreamSubscription<ButtonPressType>? _btnSub;
  StreamSubscription<void>? _snatchSub;

  AppUser? get currentUser => _currentUser;
  List<FamilyMember> get members => _members;
  List<AlertLog> get logs => _logs;
  HardwareStatus get hardwareStatus => _hardwareStatus;
  LocationSnapshot? get currentLocation =>
      _currentLocation ?? locationService.lastKnownOutdoorLocation;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);

  double get totalDistanceKm {
    if (_routePoints.length < 2) return 0.0;
    const distance = Distance();
    double totalMeters = 0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      totalMeters += distance.as(LengthUnit.Meter, _routePoints[i], _routePoints[i + 1]);
    }
    return totalMeters / 1000.0;
  }
  bool get continuousLocationSharing => _continuousLocationSharing;
  bool get backgroundServiceRunning => _backgroundServiceRunning;
  bool get isInitialized => _isInitialized;
  Map<ButtonPressType, ButtonActionConfig> get buttonConfigs => _buttonConfigs;

  AppStateProvider() {
    alertDispatcher = AlertDispatcherService(
      locationService: locationService,
      audioService: audioService,
      hardwareService: hardwareService,
    );
  }

  Future<void> init() async {
    // 1. Always subscribe to event streams first
    _hwSub = hardwareService.statusStream.listen((status) {
      _hardwareStatus = status;
      notifyListeners();
    });

    _btnSub = hardwareService.buttonPressStream.listen((pressType) async {
      final config = _buttonConfigs[pressType];
      if (config != null) {
        await triggerButtonAction(config);
      }
    });

    _snatchSub = hardwareService.antiSnatchStream.listen((_) async {
      final log = await alertDispatcher.dispatchAntiSnatch(_members);
      _logs.insert(0, log);
      notifyListeners();
    });

    // 2. Load cached configs and local DB
    try {
      await _loadButtonConfigs();
      _currentUser = await authService.getSavedUser();
      await refreshData();
    } catch (_) {}

    // 3. Hardware & Location services
    try {
      await locationService.init();
      _currentLocation = await locationService.getBestAvailableLocation();
    } catch (_) {}

    try {
      await hardwareService.init();
    } catch (_) {}

    _isInitialized = true;
    notifyListeners();
  }

  void addAlertLogDirectly(AlertLog log) {
    _logs.insert(0, log);
    notifyListeners();
  }

  Future<void> refreshData() async {
    _members = await DatabaseService.instance.getFamilyMembers();
    _logs = await DatabaseService.instance.getAlertLogs();
    if (_routePoints.isEmpty) {
      for (final log in _logs.reversed) {
        if (log.latitude != null && log.longitude != null) {
          _addRoutePoint(log.latitude!, log.longitude!);
        }
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final user = await authService.login(email, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loginWithSavedBiometric() async {
    final saved = await authService.getSavedUser();
    if (saved != null) {
      _currentUser = saved;
    } else {
      // Fallback to default user on biometric unlock if no prior session
      _currentUser = await authService.login('user@panicbutton.app', '123456');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> addFamilyMember({
    required String name,
    required String relation,
    required String phone,
    required String email,
    required String password,
  }) async {
    final member = FamilyMember(
      id: const Uuid().v4(),
      name: name.trim(),
      relation: relation.trim(),
      phone: phone.trim(),
      email: email.trim(),
      password: password,
      addedAt: DateTime.now(),
    );
    await DatabaseService.instance.insertFamilyMember(member);
    await refreshData();
  }

  Future<void> deleteFamilyMember(String id) async {
    await DatabaseService.instance.deleteFamilyMember(id);
    await refreshData();
  }

  Future<void> toggleContinuousLocationSharing(bool enabled) async {
    _continuousLocationSharing = enabled;
    if (enabled) {
      locationService.startContinuousTracking((snap) {
        _currentLocation = snap;
        _addRoutePoint(snap.latitude, snap.longitude);
        notifyListeners();
      });
    } else {
      locationService.stopContinuousTracking();
    }
    notifyListeners();
  }

  void _addRoutePoint(double lat, double lng) {
    final pt = LatLng(lat, lng);
    if (_routePoints.isEmpty) {
      _routePoints.add(pt);
    } else {
      const distance = Distance();
      final last = _routePoints.last;
      if (distance.as(LengthUnit.Meter, last, pt) >= 4) {
        _routePoints.add(pt);
      }
    }
  }

  Future<void> requestCurrentLocation() async {
    final loc = await locationService.getBestAvailableLocation();
    if (loc != null) {
      _currentLocation = loc;
      _addRoutePoint(loc.latitude, loc.longitude);
      notifyListeners();
    }
  }

  void setSimulatedLocation(double lat, double lng) {
    _currentLocation = LocationSnapshot(
      latitude: lat,
      longitude: lng,
      accuracy: 8.0,
      timestamp: DateTime.now(),
      isLastKnownFallback: false,
    );
    _addRoutePoint(lat, lng);
    notifyListeners();
  }

  void simulateJourneyStep() {
    final baseLat = _currentLocation?.latitude ?? 33.6844;
    final baseLng = _currentLocation?.longitude ?? 73.0479;
    final step = (_routePoints.length + 1) * 0.002;
    setSimulatedLocation(baseLat + step, baseLng + step);
  }

  void clearRouteHistory() {
    _routePoints.clear();
    notifyListeners();
  }

  Future<void> toggleBackgroundService(bool enabled) async {
    _backgroundServiceRunning = enabled;
    if (enabled) {
      await BackgroundMonitorService.start();
    } else {
      await BackgroundMonitorService.stop();
    }
    notifyListeners();
  }

  void toggleAntiSnatch(bool armed) {
    hardwareService.antiSnatchArmed = armed;
    notifyListeners();
  }

  Future<AlertLog> triggerButtonAction(ButtonActionConfig config) async {
    final log = await alertDispatcher.dispatchAction(
      config: config,
      members: _members,
    );
    _logs.insert(0, log);
    notifyListeners();
    return log;
  }

  Future<void> updateButtonConfig(ButtonActionConfig config) async {
    _buttonConfigs[config.pressType] = config;
    final prefs = await SharedPreferences.getInstance();
    final encoded = _buttonConfigs.map(
      (key, value) => MapEntry(key.name, value.toMap()),
    );
    await prefs.setString('button_configs', jsonEncode(encoded));
    notifyListeners();
  }

  Future<void> _loadButtonConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('button_configs');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        final pressType = ButtonPressType.values.firstWhere(
          (e) => e.name == key,
          orElse: () => ButtonPressType.single,
        );
        _buttonConfigs[pressType] = ButtonActionConfig.fromMap(
          value as Map<String, dynamic>,
        );
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _hwSub?.cancel();
    _btnSub?.cancel();
    _snatchSub?.cancel();
    hardwareService.dispose();
    locationService.dispose();
    audioService.dispose();
    super.dispose();
  }
}
