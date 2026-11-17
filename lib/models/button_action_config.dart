import 'package:flutter/material.dart';

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

  String get shortTitle {
    switch (this) {
      case ButtonActionType.safeCheckIn:
        return 'Safe Check-in';
      case ButtonActionType.silentSos:
        return 'Silent SOS';
      case ButtonActionType.loudSiren:
        return 'Emergency Siren';
      case ButtonActionType.shareLocation:
        return 'Share Location';
      case ButtonActionType.recordAudioAlert:
        return 'Audio SOS';
      case ButtonActionType.callMember:
        return 'Emergency Call';
    }
  }

  String get defaultSubtitle {
    switch (this) {
      case ButtonActionType.safeCheckIn:
        return '"I reached safely" message';
      case ButtonActionType.silentSos:
        return 'Discreet alert (No Buzzer)';
      case ButtonActionType.loudSiren:
        return 'High-Alert alarm & dispatch';
      case ButtonActionType.shareLocation:
        return 'Broadcast live phone GPS';
      case ButtonActionType.recordAudioAlert:
        return 'Record audio & send alert';
      case ButtonActionType.callMember:
        return 'Direct dial emergency contact';
    }
  }

  IconData get icon {
    switch (this) {
      case ButtonActionType.safeCheckIn:
        return Icons.check_circle_rounded;
      case ButtonActionType.silentSos:
        return Icons.visibility_off_rounded;
      case ButtonActionType.loudSiren:
        return Icons.crisis_alert_rounded;
      case ButtonActionType.shareLocation:
        return Icons.share_location_rounded;
      case ButtonActionType.recordAudioAlert:
        return Icons.mic_rounded;
      case ButtonActionType.callMember:
        return Icons.phone_in_talk_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ButtonActionType.safeCheckIn:
        return const Color(0xFF00C853);
      case ButtonActionType.silentSos:
        return const Color(0xFFFF9100);
      case ButtonActionType.loudSiren:
        return const Color(0xFFE52535);
      case ButtonActionType.shareLocation:
        return const Color(0xFF0091EA);
      case ButtonActionType.recordAudioAlert:
        return const Color(0xFF7C4DFF);
      case ButtonActionType.callMember:
        return const Color(0xFF00897B);
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case ButtonActionType.safeCheckIn:
        return const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF00A844)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ButtonActionType.silentSos:
        return const LinearGradient(
          colors: [Color(0xFF374151), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ButtonActionType.loudSiren:
        return const LinearGradient(
          colors: [Color(0xFFFF334B), Color(0xFFD31027)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ButtonActionType.shareLocation:
        return const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF1967D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ButtonActionType.recordAudioAlert:
        return const LinearGradient(
          colors: [Color(0xFF9061F9), Color(0xFF6C2BD9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ButtonActionType.callMember:
        return const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
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
