import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import '../models/button_action_config.dart';
import '../models/hardware_status.dart';

class HardwareService {
  static const String esp32DeviceName = 'ESP32-PanicButton';
  static const String esp32ApBaseUrl = 'http://192.168.4.1';

  final StreamController<HardwareStatus> _statusController =
      StreamController<HardwareStatus>.broadcast();
  final StreamController<ButtonPressType> _buttonPressController =
      StreamController<ButtonPressType>.broadcast();
  final StreamController<void> _antiSnatchController =
      StreamController<void>.broadcast();

  Stream<HardwareStatus> get statusStream => _statusController.stream;
  Stream<ButtonPressType> get buttonPressStream => _buttonPressController.stream;
  Stream<void> get antiSnatchStream => _antiSnatchController.stream;

  HardwareStatus _currentStatus = HardwareStatus(lastUpdated: DateTime.now());
  HardwareStatus get currentStatus => _currentStatus;

  bool antiSnatchArmed = true;

  BluetoothDevice? _connectedBleDevice;
  StreamSubscription<BluetoothAdapterState>? _bleStateSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connStateSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _wifiPollTimer;

  Future<void> init() async {
    // Monitor Bluetooth adapter state for auto-connect on supported platforms
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
      try {
        _bleStateSub = FlutterBluePlus.adapterState.listen((state) {
          if (state == BluetoothAdapterState.on) {
            _startBleAutoConnect();
          } else if (!_currentStatus.isConnected ||
              _currentStatus.mode == ConnectionMode.bluetooth) {
            _handleDisconnect(wasConnected: _currentStatus.isConnected);
          }
        });
      } catch (_) {}
    }

    // Monitor Wi-Fi / Hotspot connectivity
    try {
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        if (results.contains(ConnectivityResult.wifi)) {
          _startWifiBridge();
        } else {
          _stopWifiBridge();
        }
      });
    } catch (_) {}
  }

  Future<void> _startBleAutoConnect() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        for (final r in results) {
          if (r.device.platformName.contains('ESP32') ||
              r.device.platformName.contains('Panic')) {
            await FlutterBluePlus.stopScan();
            await _connectBleDevice(r.device);
            break;
          }
        }
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> _connectBleDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: true);
      _connectedBleDevice = device;

      _connStateSub?.cancel();
      _connStateSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          _updateStatus(
            _currentStatus.copyWith(
              isConnected: true,
              mode: ConnectionMode.bluetooth,
              deviceName: device.platformName.isNotEmpty
                  ? device.platformName
                  : esp32DeviceName,
              lastUpdated: DateTime.now(),
            ),
          );
          _discoverBleServices(device);
        } else if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect(wasConnected: true);
        }
      });
    } catch (_) {}
  }

  Future<void> _discoverBleServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.notify) {
            await char.setNotifyValue(true);
            char.lastValueStream.listen((bytes) {
              _parseEsp32Payload(utf8.decode(bytes, allowMalformed: true));
            });
          }
        }
      }
    } catch (_) {}
  }

  void _startWifiBridge() {
    _wifiPollTimer?.cancel();
    _wifiPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final res = await http
            .get(Uri.parse('$esp32ApBaseUrl/status'))
            .timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _updateStatus(
            _currentStatus.copyWith(
              isConnected: true,
              mode: ConnectionMode.esp32Ap,
              satelliteCount: data['sats'] as int? ?? 0,
              batteryPercent: data['bat'] as int? ?? 100,
              latitude: (data['lat'] as num?)?.toDouble(),
              longitude: (data['lng'] as num?)?.toDouble(),
              lastUpdated: DateTime.now(),
            ),
          );
          if (data['event'] != null) {
            _parseEsp32Payload(data['event'] as String);
          }
        }
      } catch (_) {
        // ESP32 AP not reachable on this Wi-Fi network
      }
    });
  }

  void _stopWifiBridge() {
    _wifiPollTimer?.cancel();
    _wifiPollTimer = null;
  }

  Future<void> sendCommandToEsp32(String command) async {
    // Try BLE first, then Wi-Fi AP
    if (_connectedBleDevice != null &&
        _currentStatus.mode == ConnectionMode.bluetooth) {
      try {
        final services = await _connectedBleDevice!.discoverServices();
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.properties.write) {
              await c.write(utf8.encode(command));
              return;
            }
          }
        }
      } catch (_) {}
    }

    if (_currentStatus.mode == ConnectionMode.esp32Ap ||
        _currentStatus.mode == ConnectionMode.wifiHotspot) {
      try {
        await http
            .post(
              Uri.parse('$esp32ApBaseUrl/command'),
              body: jsonEncode({'cmd': command}),
            )
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  void _parseEsp32Payload(String payload) {
    final upper = payload.trim().toUpperCase();
    if (upper.contains('SINGLE')) {
      _buttonPressController.add(ButtonPressType.single);
    } else if (upper.contains('DOUBLE')) {
      _buttonPressController.add(ButtonPressType.doublePress);
    } else if (upper.contains('LONG')) {
      _buttonPressController.add(ButtonPressType.longPress);
    }
  }

  void _handleDisconnect({required bool wasConnected}) {
    _updateStatus(
      _currentStatus.copyWith(
        isConnected: false,
        mode: ConnectionMode.disconnected,
        lastUpdated: DateTime.now(),
      ),
    );
    if (wasConnected && antiSnatchArmed) {
      _antiSnatchController.add(null);
    }
  }

  void _updateStatus(HardwareStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // --- Simulation helpers for testing without physical ESP32 ---
  void simulateConnect({
    ConnectionMode mode = ConnectionMode.bluetooth,
    int satellites = 9,
    int battery = 88,
  }) {
    _updateStatus(
      _currentStatus.copyWith(
        isConnected: true,
        mode: mode,
        satelliteCount: satellites,
        batteryPercent: battery,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void simulateButtonPress(ButtonPressType pressType) {
    _buttonPressController.add(pressType);
  }

  void simulateAntiSnatchDisconnect() {
    _handleDisconnect(wasConnected: true);
  }

  void dispose() {
    _bleStateSub?.cancel();
    _scanSub?.cancel();
    _connStateSub?.cancel();
    _connectivitySub?.cancel();
    _wifiPollTimer?.cancel();
    _statusController.close();
    _buttonPressController.close();
    _antiSnatchController.close();
  }
}
