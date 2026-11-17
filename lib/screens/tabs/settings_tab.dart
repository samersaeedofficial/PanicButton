import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/button_action_config.dart';
import '../../providers/app_state_provider.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        // 1. HARDWARE BUTTON CUSTOMIZER SECTION
        const Text(
          'ESP32 Hardware Button Triggers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Customize what happens when you click or hold your physical button.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),

        _ButtonConfigCard(
          badgeLabel: '1x CLICK',
          badgeColor: AppColors.safeGreen,
          title: 'Single Click Action',
          config: state.buttonConfigs[ButtonPressType.single]!,
          state: state,
        ),
        const SizedBox(height: 12),

        _ButtonConfigCard(
          badgeLabel: '2x CLICK',
          badgeColor: AppColors.silentAmber,
          title: 'Double Click Action',
          config: state.buttonConfigs[ButtonPressType.doublePress]!,
          state: state,
        ),
        const SizedBox(height: 12),

        _ButtonConfigCard(
          badgeLabel: 'HOLD PRESS',
          badgeColor: AppColors.primary,
          title: 'Long Press Action',
          config: state.buttonConfigs[ButtonPressType.longPress]!,
          state: state,
          showHoldDuration: true,
        ),

        const SizedBox(height: 24),

        // 2. BACKGROUND SERVICE SECTION
        const Text(
          'System & Background Service',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continuous Background Service',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Keep BLE auto-connect & anti-snatch alive when app is closed',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.backgroundServiceRunning,
                  activeThumbColor: AppColors.primary,
                  onChanged: state.toggleBackgroundService,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 3. MOBILE PERMISSIONS SECTION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Required Mobile Permissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await _permService.requestAllPermissions();
                await _loadPermissions();
              },
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Grant All'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: _permissions.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              final granted = p.status.isGranted;

              return Column(
                children: [
                  if (idx > 0) const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (granted ? AppColors.safeGreen : Colors.orange).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        granted ? Icons.check_circle_rounded : Icons.priority_high_rounded,
                        color: granted ? AppColors.safeGreenDark : Colors.orange.shade800,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      p.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: granted
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.safeGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.safeGreenDark,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: () async {
                              await _permService.requestSingle(p.permission);
                              await _loadPermissions();
                            },
                            child: const Text('Allow'),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 28),

        // 4. LOGOUT BUTTON
        OutlinedButton.icon(
          onPressed: state.logout,
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: const Text(
            'Sign Out of Protected Device',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade200),
            backgroundColor: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _ButtonConfigCard extends StatefulWidget {
  final String badgeLabel;
  final Color badgeColor;
  final String title;
  final ButtonActionConfig config;
  final AppStateProvider state;
  final bool showHoldDuration;

  const _ButtonConfigCard({
    required this.badgeLabel,
    required this.badgeColor,
    required this.title,
    required this.config,
    required this.state,
    this.showHoldDuration = false,
  });

  @override
  State<_ButtonConfigCard> createState() => _ButtonConfigCardState();
}

class _ButtonConfigCardState extends State<_ButtonConfigCard> {
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.config.targetMemberId ?? '');
  }

  @override
  void didUpdateWidget(covariant _ButtonConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.targetMemberId != widget.config.targetMemberId &&
        _phoneCtrl.text != widget.config.targetMemberId) {
      _phoneCtrl.text = widget.config.targetMemberId ?? '';
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final state = widget.state;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: widget.badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action dropdown
          DropdownButtonFormField<ButtonActionType>(
            initialValue: config.actionType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Trigger Action',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: ButtonActionType.values.map((action) {
              return DropdownMenuItem(
                value: action,
                child: Text(
                  action.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                state.updateButtonConfig(config.copyWith(actionType: val));
              }
            },
          ),

          // Hold duration slider (for longPress)
          if (widget.showHoldDuration) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Hold Time: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Slider(
                    value: config.holdDurationSeconds.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppColors.primary,
                    label: '${config.holdDurationSeconds}s',
                    onChanged: (val) {
                      state.updateButtonConfig(
                        config.copyWith(holdDurationSeconds: val.round()),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${config.holdDurationSeconds} sec',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Call Member Target Selector
          if (config.actionType == ButtonActionType.callMember) ...[
            const SizedBox(height: 14),
            if (state.members.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: state.members.any((m) => m.id == config.targetMemberId)
                    ? config.targetMemberId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Guardian to Call',
                  prefixIcon: Icon(Icons.person_pin_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                hint: const Text('Choose a family member...'),
                items: state.members.map((m) {
                  return DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      '${m.name} (${m.phone})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final target = state.members.where((m) => m.id == val).firstOrNull;
                    _phoneCtrl.text = target?.phone ?? '';
                    state.updateButtonConfig(config.copyWith(targetMemberId: val));
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            // Direct Phone Number Field (Works even if no members added!)
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-\(\)]')),
              ],
              decoration: InputDecoration(
                labelText: 'Or Emergency Phone Number to Dial',
                hintText: 'e.g. +923001234567 or 1122',
                prefixIcon: const Icon(Icons.phone_in_talk_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.safeGreenDark),
                  tooltip: 'Save number',
                  onPressed: () {
                    state.updateButtonConfig(
                      config.copyWith(targetMemberId: _phoneCtrl.text.trim()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved "${_phoneCtrl.text.trim()}" as emergency call number!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              onChanged: (val) {
                state.updateButtonConfig(
                  config.copyWith(targetMemberId: val.trim()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
