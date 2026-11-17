enum ButtonPressType { single, doublePress, longPress }

enum ButtonActionType {
  safeCheckIn,
  silentSos,
  loudSiren,
  shareLocation,
  recordAudioAlert,
  callMember,
}

extension ButtonActionTypeX on ButtonActionType {
  String get label {
    switch (this) {
      case ButtonActionType.safeCheckIn:
        return 'Safe Check-in ("I reached safely")';
      case ButtonActionType.silentSos:
        return 'Silent / Stealth SOS (No Buzzer)';
      case ButtonActionType.loudSiren:
        return 'Loud Emergency Siren + SOS';
      case ButtonActionType.shareLocation:
        return 'Share Current Location Now';
      case ButtonActionType.recordAudioAlert:
        return 'Record Audio & Send Alert';
      case ButtonActionType.callMember:
        return 'Call Family Member';
    }
  }
}

class ButtonActionConfig {
  final ButtonPressType pressType;
  final ButtonActionType actionType;
  final int holdDurationSeconds; // Used for longPress (e.g. 2s default)
  final String? targetMemberId; // Used when actionType == callMember

  const ButtonActionConfig({
    required this.pressType,
    required this.actionType,
    this.holdDurationSeconds = 2,
    this.targetMemberId,
  });

  ButtonActionConfig copyWith({
    ButtonActionType? actionType,
    int? holdDurationSeconds,
    String? targetMemberId,
  }) {
    return ButtonActionConfig(
      pressType: pressType,
      actionType: actionType ?? this.actionType,
      holdDurationSeconds: holdDurationSeconds ?? this.holdDurationSeconds,
      targetMemberId: targetMemberId ?? this.targetMemberId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pressType': pressType.name,
      'actionType': actionType.name,
      'holdDurationSeconds': holdDurationSeconds,
      'targetMemberId': targetMemberId,
    };
  }

  factory ButtonActionConfig.fromMap(Map<String, dynamic> map) {
    return ButtonActionConfig(
      pressType: ButtonPressType.values.firstWhere(
        (e) => e.name == map['pressType'],
        orElse: () => ButtonPressType.single,
      ),
      actionType: ButtonActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => ButtonActionType.safeCheckIn,
      ),
      holdDurationSeconds: map['holdDurationSeconds'] as int? ?? 2,
      targetMemberId: map['targetMemberId'] as String?,
    );
  }
}
