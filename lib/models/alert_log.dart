enum AlertType {
  safeCheckIn,
  silentSos,
  loudSiren,
  antiSnatch,
  locationShare,
  callMember,
}

extension AlertTypeX on AlertType {
  String get label {
    switch (this) {
      case AlertType.safeCheckIn:
        return 'Safe Check-in';
      case AlertType.silentSos:
        return 'Silent SOS';
      case AlertType.loudSiren:
        return 'Loud Emergency Siren';
      case AlertType.antiSnatch:
        return 'Anti-Snatch Alert';
      case AlertType.locationShare:
        return 'Location Shared';
      case AlertType.callMember:
        return 'Emergency Call';
    }
  }
}

class AlertLog {
  final String id;
  final AlertType type;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final bool isLastKnownLocation;
  final String? audioPath;
  final String message;
  final String sentVia; // 'Online + App', 'SMS (Offline)', 'Local BLE/WiFi'

  const AlertLog({
    required this.id,
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.isLastKnownLocation = false,
    this.audioPath,
    required this.message,
    required this.sentVia,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'isLastKnownLocation': isLastKnownLocation ? 1 : 0,
      'audioPath': audioPath,
      'message': message,
      'sentVia': sentVia,
    };
  }

  factory AlertLog.fromMap(Map<String, dynamic> map) {
    return AlertLog(
      id: map['id'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.loudSiren,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      isLastKnownLocation: (map['isLastKnownLocation'] as int? ?? 0) == 1,
      audioPath: map['audioPath'] as String?,
      message: map['message'] as String,
      sentVia: map['sentVia'] as String,
    );
  }
}
