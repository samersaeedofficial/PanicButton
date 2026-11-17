import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/button_action_config.dart';
import '../../providers/app_state_provider.dart';
import '../../services/permission_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final PermissionService _permService = PermissionService();
  List<PermissionItem> _permissions = [];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final list = await _permService.checkAllPermissions();
    if (mounted) setState(() => _permissions = list);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Button Action Customizer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _ButtonConfigCard(
          title: 'Single Click (1x Press)',
          config: state.buttonConfigs[ButtonPressType.single]!,
          state: state,
        ),
        const SizedBox(height: 10),
        _ButtonConfigCard(
          title: 'Double Click (2x Press)',
          config: state.buttonConfigs[ButtonPressType.doublePress]!,
          state: state,
        ),
        const SizedBox(height: 10),
        _ButtonConfigCard(
          title: 'Long Press',
          config: state.buttonConfigs[ButtonPressType.longPress]!,
          state: state,
          showHoldDuration: true,
        ),
        const SizedBox(height: 20),

        // Background Service
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: SwitchListTile(
            title: const Text('Run in Background'),
            subtitle: const Text(
              'Keep ESP32 Bluetooth/Wi-Fi & Anti-Snatch active',
            ),
            value: state.backgroundServiceRunning,
            onChanged: state.toggleBackgroundService,
            secondary: const Icon(Icons.settings_backup_restore),
          ),
        ),
        const SizedBox(height: 20),

        // Permissions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mobile Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () async {
                await _permService.requestAllPermissions();
                await _loadPermissions();
              },
              child: const Text('Grant All'),
            ),
          ],
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: _permissions.map((p) {
              final granted = p.status.isGranted;
              return ListTile(
                leading: Icon(
                  granted ? Icons.check_circle : Icons.error_outline,
                  color: granted ? Colors.green : Colors.orange,
                ),
                title: Text(p.title),
                subtitle: Text(p.description),
                trailing: granted
                    ? const Text('Granted', style: TextStyle(color: Colors.green))
                    : TextButton(
                        onPressed: () async {
                          await _permService.requestSingle(p.permission);
                          await _loadPermissions();
                        },
                        child: const Text('Allow'),
                      ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: state.logout,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class _ButtonConfigCard extends StatelessWidget {
  final String title;
  final ButtonActionConfig config;
  final AppStateProvider state;
  final bool showHoldDuration;

  const _ButtonConfigCard({
    required this.title,
    required this.config,
    required this.state,
    this.showHoldDuration = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ButtonActionType>(
              initialValue: config.actionType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: ButtonActionType.values.map((action) {
                return DropdownMenuItem(
                  value: action,
                  child: Text(action.label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  state.updateButtonConfig(config.copyWith(actionType: val));
                }
              },
            ),
            if (showHoldDuration) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Hold Time: '),
                  Expanded(
                    child: Slider(
                      value: config.holdDurationSeconds.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '${config.holdDurationSeconds}s',
                      onChanged: (val) {
                        state.updateButtonConfig(
                          config.copyWith(holdDurationSeconds: val.round()),
                        );
                      },
                    ),
                  ),
                  Text('${config.holdDurationSeconds} sec'),
                ],
              ),
            ],
            if (config.actionType == ButtonActionType.callMember) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: state.members.any((m) => m.id == config.targetMemberId)
                    ? config.targetMemberId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Member to Call',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: state.members.map((m) {
                  return DropdownMenuItem(
                    value: m.id,
                    child: Text('${m.name} (${m.phone})'),
                  );
                }).toList(),
                onChanged: (val) {
                  state.updateButtonConfig(
                    config.copyWith(targetMemberId: val),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
