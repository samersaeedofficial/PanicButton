import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/button_action_config.dart';
import '../../models/hardware_status.dart';
import '../../providers/app_state_provider.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final hw = state.hardwareStatus;
    final loc = state.currentLocation;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hardware Status Card (Requirement 11)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hw.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: hw.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hw.deviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        hw.isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: hw.isConnected
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: hw.isConnected
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusMetric(
                      icon: Icons.wifi,
                      label: 'Mode',
                      value: hw.mode.label,
                    ),
                    _StatusMetric(
                      icon: Icons.satellite_alt,
                      label: 'GPS Satellites',
                      value: '${hw.satelliteCount} sats',
                    ),
                    _StatusMetric(
                      icon: Icons.battery_charging_full,
                      label: 'Battery',
                      value: '${hw.batteryPercent}%',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc != null
                              ? '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'
                                  '${loc.isLastKnownFallback ? ' (Last Known Outdoor)' : ''}'
                              : 'Acquiring GPS...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Emergency & Check-in Controls
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => state.triggerButtonAction(
                  state.buttonConfigs[ButtonPressType.longPress]!,
                ),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('SOS SIREN'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => state.triggerButtonAction(
                  state.buttonConfigs[ButtonPressType.single]!,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('SAFE CHECK-IN'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => state.triggerButtonAction(
            state.buttonConfigs[ButtonPressType.doublePress]!,
          ),
          icon: const Icon(Icons.visibility_off_outlined),
          label: const Text('Silent / Stealth SOS (No Buzzer)'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // Location Sharing & Anti-Snatch Controls
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Continuous Real-Time Location'),
                subtitle: const Text(
                  'Share live GPS wherever you go',
                ),
                value: state.continuousLocationSharing,
                onChanged: state.toggleContinuousLocationSharing,
                secondary: const Icon(Icons.share_location),
              ),
              if (!state.continuousLocationSharing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await state.triggerButtonAction(
                          const ButtonActionConfig(
                            pressType: ButtonPressType.single,
                            actionType: ButtonActionType.shareLocation,
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location shared with members!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Share Current Location Once'),
                    ),
                  ),
                ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Anti-Snatch / Disconnect Alert'),
                subtitle: const Text(
                  'Trigger alert if ESP32 disconnects unexpectedly',
                ),
                value: state.hardwareService.antiSnatchArmed,
                onChanged: state.toggleAntiSnatch,
                secondary: const Icon(Icons.phonelink_erase),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ESP32 Hardware Simulator (for testing without physical ESP32)
        Card(
          color: Colors.blueGrey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESP32 Hardware Simulator',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Connect BLE'),
                      onPressed: () => state.hardwareService.simulateConnect(
                        mode: ConnectionMode.bluetooth,
                      ),
                    ),
                    ActionChip(
                      label: const Text('Connect Wi-Fi AP'),
                      onPressed: () => state.hardwareService.simulateConnect(
                        mode: ConnectionMode.esp32Ap,
                      ),
                    ),
                    ActionChip(
                      label: const Text('1x Press'),
                      onPressed: () => state.hardwareService
                          .simulateButtonPress(ButtonPressType.single),
                    ),
                    ActionChip(
                      label: const Text('2x Press'),
                      onPressed: () => state.hardwareService
                          .simulateButtonPress(ButtonPressType.doublePress),
                    ),
                    ActionChip(
                      label: const Text('Long Press'),
                      onPressed: () => state.hardwareService
                          .simulateButtonPress(ButtonPressType.longPress),
                    ),
                    ActionChip(
                      label: const Text('Simulate Snatch'),
                      onPressed: () =>
                          state.hardwareService.simulateAntiSnatchDisconnect(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
