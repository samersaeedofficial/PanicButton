import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/alert_log.dart';
import '../models/button_action_config.dart';
import '../models/family_member.dart';
import 'audio_service.dart';
import 'background_service.dart';
import 'database_service.dart';
import 'hardware_service.dart';
import 'location_service.dart';

class AlertDispatcherService {
  final LocationService locationService;
  final AudioService audioService;
  final HardwareService hardwareService;

  AlertDispatcherService({
    required this.locationService,
    required this.audioService,
    required this.hardwareService,
  });

  Future<bool> _hasInternet() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  Future<AlertLog> dispatchAction({
    required ButtonActionConfig config,
    required List<FamilyMember> members,
  }) async {
    final loc = await locationService.getBestAvailableLocation();
    final online = await _hasInternet();
    final sentVia = online ? 'Online + App' : 'SMS (Offline SIM)';

    String? audioPath;
    AlertType alertType;
    String message;

    switch (config.actionType) {
      case ButtonActionType.safeCheckIn:
        alertType = AlertType.safeCheckIn;
        message = 'I reached safely.';
        await hardwareService.sendCommandToEsp32('BEEP_SHORT');
        break;

      case ButtonActionType.silentSos:
        alertType = AlertType.silentSos;
        message = 'SILENT SOS! User needs help discreetly.';
        await hardwareService.sendCommandToEsp32('BUZZER_OFF');
        audioPath = await audioService.recordPanicClip(durationSeconds: 8);
        break;

      case ButtonActionType.loudSiren:
        alertType = AlertType.loudSiren;
        message = 'EMERGENCY! Loud Siren triggered.';
        await hardwareService.sendCommandToEsp32('SIREN_ON');
        audioPath = await audioService.recordPanicClip(durationSeconds: 10);
        break;

      case ButtonActionType.shareLocation:
        alertType = AlertType.locationShare;
        message = 'Live location shared with family.';
        break;

      case ButtonActionType.recordAudioAlert:
        alertType = AlertType.silentSos;
        message = 'Audio panic alert recorded and sent.';
        audioPath = await audioService.recordPanicClip(durationSeconds: 10);
        break;

      case ButtonActionType.callMember:
        alertType = AlertType.callMember;
        final target = members.where((m) => m.id == config.targetMemberId).firstOrNull;
        if (target != null) {
          message = 'Calling ${target.name} (${target.phone})';
          await _dialPhone(target.phone);
        } else if (config.targetMemberId != null && config.targetMemberId!.trim().isNotEmpty) {
          message = 'Calling Emergency Number (${config.targetMemberId})';
          await _dialPhone(config.targetMemberId!.trim());
        } else if (members.isNotEmpty) {
          message = 'Calling ${members.first.name} (${members.first.phone})';
          await _dialPhone(members.first.phone);
        } else {
          message = 'Call action triggered (no family member or phone number configured).';
        }
        break;
    }

    if (!online && members.isNotEmpty) {
      await _sendOfflineSmsFallback(members, message, loc);
    }

    final log = AlertLog(
      id: const Uuid().v4(),
      type: alertType,
      timestamp: DateTime.now(),
      latitude: loc?.latitude,
      longitude: loc?.longitude,
      isLastKnownLocation: loc?.isLastKnownFallback ?? false,
      audioPath: audioPath,
      message: message,
      sentVia: sentVia,
    );

    await DatabaseService.instance.insertAlertLog(log);
    await BackgroundMonitorService.showAlertNotification(
      title: alertType.label,
      body: message,
    );
    return log;
  }

  Future<AlertLog> dispatchAntiSnatch(List<FamilyMember> members) async {
    final loc = await locationService.getBestAvailableLocation();
    final online = await _hasInternet();
    final sentVia = online ? 'Online + App' : 'SMS (Offline SIM)';
    const message =
        'ANTI-SNATCH ALERT! ESP32 disconnected unexpectedly from phone.';

    if (!online && members.isNotEmpty) {
      await _sendOfflineSmsFallback(members, message, loc);
    }

    final log = AlertLog(
      id: const Uuid().v4(),
      type: AlertType.antiSnatch,
      timestamp: DateTime.now(),
      latitude: loc?.latitude,
      longitude: loc?.longitude,
      isLastKnownLocation: loc?.isLastKnownFallback ?? false,
      message: message,
      sentVia: sentVia,
    );

    await DatabaseService.instance.insertAlertLog(log);
    await BackgroundMonitorService.showAlertNotification(
      title: 'Anti-Snatch Alert!',
      body: message,
    );
    return log;
  }

  Future<void> _dialPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendOfflineSmsFallback(
    List<FamilyMember> members,
    String message,
    LocationSnapshot? loc,
  ) async {
    final coords = loc != null
        ? 'https://maps.google.com/?q=${loc.latitude},${loc.longitude}'
        : 'Location unavailable';
    final body = '$message\nLocation: $coords';
    final recipients = members.map((m) => m.phone).join(',');
    final uri = Uri(
      scheme: 'sms',
      path: recipients,
      queryParameters: {'body': body},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
