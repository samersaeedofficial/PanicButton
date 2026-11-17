import 'package:permission_handler/permission_handler.dart';

class PermissionItem {
  final String title;
  final String description;
  final Permission permission;
  final PermissionStatus status;

  const PermissionItem({
    required this.title,
    required this.description,
    required this.permission,
    required this.status,
  });
}

class PermissionService {
  static final List<({String title, String description, Permission permission})>
      _requiredPermissions = [
    (
      title: 'Location (Precise)',
      description: 'Required for live GPS tracking and SOS coordinates',
      permission: Permission.location,
    ),
    (
      title: 'Background Location',
      description: 'Keeps real-time tracking active when app is minimized',
      permission: Permission.locationAlways,
    ),
    (
      title: 'Bluetooth Scan & Connect',
      description: 'Auto-connects to your ESP32 Panic Button',
      permission: Permission.bluetoothConnect,
    ),
    (
      title: 'Bluetooth Scan',
      description: 'Discovers nearby ESP32 hardware',
      permission: Permission.bluetoothScan,
    ),
    (
      title: 'Microphone',
      description: 'Automatically records audio when panic is triggered',
      permission: Permission.microphone,
    ),
    (
      title: 'Phone Calls',
      description: 'Enables "Call Member" action on button press',
      permission: Permission.phone,
    ),
    (
      title: 'SMS (Offline Fallback)',
      description: 'Sends emergency alerts via SIM when internet is down',
      permission: Permission.sms,
    ),
    (
      title: 'Notifications',
      description: 'Shows background service & SOS alert notifications',
      permission: Permission.notification,
    ),
  ];

  Future<List<PermissionItem>> checkAllPermissions() async {
    final List<PermissionItem> items = [];
    for (final entry in _requiredPermissions) {
      final status = await entry.permission.status;
      items.add(
        PermissionItem(
          title: entry.title,
          description: entry.description,
          permission: entry.permission,
          status: status,
        ),
      );
    }
    return items;
  }

  Future<void> requestAllPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
      Permission.notification,
    ].request();

    // Background location should be requested after foreground location
    if (await Permission.location.isGranted) {
      await Permission.locationAlways.request();
    }
  }

  Future<PermissionStatus> requestSingle(Permission permission) async {
    return permission.request();
  }
}
