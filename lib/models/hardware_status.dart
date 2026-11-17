enum ConnectionMode {
  disconnected,
  bluetooth,
  wifiHotspot, // Mobile hotspot ON -> ESP32 connects to phone
  esp32Ap, // Mobile Wi-Fi ON -> ESP32 opens its own hotspot
}

extension ConnectionModeX on ConnectionMode {
  String get label {
    switch (this) {
      case ConnectionMode.disconnected:
        return 'Disconnected';
      case ConnectionMode.bluetooth:
        return 'Bluetooth (BLE)';
      case ConnectionMode.wifiHotspot:
        return 'Wi-Fi (Mobile Hotspot)';
      case ConnectionMode.esp32Ap:
        return 'Wi-Fi (ESP32 Hotspot)';
    }
  }
}

class HardwareStatus {
  final bool isConnected;
  final ConnectionMode mode;
  final String deviceName;
  final int satelliteCount;
  final int batteryPercent;
  final double? latitude;
  final double? longitude;
  final DateTime lastUpdated;

  const HardwareStatus({
    this.isConnected = false,
    this.mode = ConnectionMode.disconnected,
    this.deviceName = 'ESP32-PanicButton',
    this.satelliteCount = 0,
    this.batteryPercent = 100,
    this.latitude,
    this.longitude,
    required this.lastUpdated,
  });

  HardwareStatus copyWith({
    bool? isConnected,
    ConnectionMode? mode,
    String? deviceName,
    int? satelliteCount,
    int? batteryPercent,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
  }) {
    return HardwareStatus(
      isConnected: isConnected ?? this.isConnected,
      mode: mode ?? this.mode,
      deviceName: deviceName ?? this.deviceName,
      satelliteCount: satelliteCount ?? this.satelliteCount,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
