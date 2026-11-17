import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/button_action_config.dart';
import '../../models/hardware_status.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _simulatorExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final hw = state.hardwareStatus;
    final loc = state.currentLocation;
    final userName = state.currentUser?.name ?? 'Guardian User';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        // Top Greeting & Connection Banner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hw.isConnected
                      ? 'ESP32 Device Protected • Active'
                      : 'ESP32 Standby • Auto-reconnecting...',
                  style: TextStyle(
                    fontSize: 13,
                    color: hw.isConnected ? AppColors.safeGreenDark : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            _ConnectionStatusPill(isConnected: hw.isConnected, mode: hw.mode),
          ],
        ),

        const SizedBox(height: 18),

        // 1. HARDWARE STATUS CARD (Requirement 11, 1, 12)
        _HardwareStatusCard(hw: hw, loc: loc),

        const SizedBox(height: 24),

        // 2. HERO SOS EMERGENCY SECTION (Dynamically reflects Long Press Trigger setting)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Emergency & Safety Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Text(
                'Custom Triggers Active',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Large Hero SOS Button (Dynamically configured by user in Triggers / Settings)
        _HeroSosButton(
          config: state.buttonConfigs[ButtonPressType.longPress] ??
              const ButtonActionConfig(
                pressType: ButtonPressType.longPress,
                actionType: ButtonActionType.loudSiren,
                holdDurationSeconds: 2,
              ),
          onTap: () async {
            final config = state.buttonConfigs[ButtonPressType.longPress]!;
            final log = await state.triggerButtonAction(config);
            if (context.mounted) {
              _showActionFeedback(context, '${config.actionType.shortTitle}: ${log.message}', config.actionType.color);
            }
          },
        ),

        const SizedBox(height: 14),

        // 3. DUAL QUICK ACTION CARDS (Dynamically reflect 1x Click & 2x Click settings)
        Builder(
          builder: (context) {
            final singleConfig = state.buttonConfigs[ButtonPressType.single] ??
                const ButtonActionConfig(
                  pressType: ButtonPressType.single,
                  actionType: ButtonActionType.safeCheckIn,
                );
            final doubleConfig = state.buttonConfigs[ButtonPressType.doublePress] ??
                const ButtonActionConfig(
                  pressType: ButtonPressType.doublePress,
                  actionType: ButtonActionType.silentSos,
                );

            return Row(
              children: [
                // 1x Click Action Card (Customizable)
                Expanded(
                  child: _QuickActionCard(
                    title: singleConfig.actionType.shortTitle,
                    subtitle: '1x Click • ${singleConfig.actionType.defaultSubtitle}',
                    icon: singleConfig.actionType.icon,
                    gradient: singleConfig.actionType.gradient,
                    accentColor: singleConfig.actionType.color,
                    onTap: () async {
                      final log = await state.triggerButtonAction(singleConfig);
                      if (context.mounted) {
                        _showActionFeedback(
                          context,
                          '1x Click: ${log.message}',
                          singleConfig.actionType.color,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 2x Click Action Card (Customizable)
                Expanded(
                  child: _QuickActionCard(
                    title: doubleConfig.actionType.shortTitle,
                    subtitle: '2x Click • ${doubleConfig.actionType.defaultSubtitle}',
                    icon: doubleConfig.actionType.icon,
                    gradient: doubleConfig.actionType.gradient,
                    accentColor: doubleConfig.actionType.color,
                    onTap: () async {
                      final log = await state.triggerButtonAction(doubleConfig);
                      if (context.mounted) {
                        _showActionFeedback(
                          context,
                          '2x Click: ${log.message}',
                          doubleConfig.actionType.color,
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // 4. LOCATION SHARING & ANTI-SNATCH GUARDS
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Continuous Live Sharing Switch
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.share_location_rounded, color: AppColors.infoBlue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Real-Time Live Location',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            state.continuousLocationSharing
                                ? 'Broadcasting live coordinates continuously'
                                : 'Share live GPS updates to family members',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.continuousLocationSharing,
                      activeThumbColor: AppColors.infoBlue,
                      onChanged: state.toggleContinuousLocationSharing,
                    ),
                  ],
                ),
              ),

              // Instant Single Share Button if continuous is off
              if (!state.continuousLocationSharing) ...[
                const Divider(height: 1, color: AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final log = await state.shareCurrentLocationOnce();
                        if (context.mounted) {
                          final coordsStr = log.latitude != null && log.longitude != null
                              ? ' (${log.latitude!.toStringAsFixed(4)}, ${log.longitude!.toStringAsFixed(4)})'
                              : '';
                          _showActionFeedback(
                            context,
                            'Live Phone Location Shared with Family!$coordsStr',
                            AppColors.infoBlue,
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 16, color: AppColors.infoBlue),
                      label: const Text(
                        'Share Current Location Once',
                        style: TextStyle(color: AppColors.infoBlue, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.infoBlue.withValues(alpha: 0.3)),
                        backgroundColor: AppColors.infoBlue.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],

              const Divider(height: 1, color: AppColors.borderLight),

              // Anti-Snatch Disconnect Alert
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.snatchPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phonelink_erase_rounded, color: AppColors.snatchPurple, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Anti-Snatch / Theft Alert',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const Text(
                            'Triggers instant alert if ESP32 disconnects suddenly',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.hardwareService.antiSnatchArmed,
                      activeThumbColor: AppColors.snatchPurple,
                      onChanged: state.toggleAntiSnatch,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. ESP32 HARDWARE SIMULATION DRAWER
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _simulatorExpanded = !_simulatorExpanded),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.developer_board_rounded, color: AppColors.textPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESP32 Hardware Simulator',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            Text(
                              'Test click actions, WiFi/BLE bridges & anti-snatch',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _simulatorExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_simulatorExpanded) ...[
                const Divider(height: 1, color: AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.bluetooth, size: 16, color: Colors.blue),
                        label: const Text('Simulate BLE'),
                        onPressed: () {
                          state.hardwareService.simulateConnect(
                            mode: ConnectionMode.bluetooth,
                            satellites: 9,
                            battery: 88,
                          );
                          _showActionFeedback(
                            context,
                            'Simulated: ESP32 Connected via Bluetooth BLE (9 Sats, 88% Bat)',
                            AppColors.infoBlue,
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.wifi, size: 16, color: Colors.teal),
                        label: const Text('Simulate Wi-Fi AP'),
                        onPressed: () {
                          state.hardwareService.simulateConnect(
                            mode: ConnectionMode.esp32Ap,
                            satellites: 11,
                            battery: 95,
                          );
                          _showActionFeedback(
                            context,
                            'Simulated: ESP32 Connected via Wi-Fi AP (11 Sats, 95% Bat)',
                            Colors.teal,
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.touch_app_outlined, size: 16, color: Colors.green),
                        label: const Text('1x Click (Safe)'),
                        onPressed: () async {
                          final config = state.buttonConfigs[ButtonPressType.single]!;
                          final log = await state.triggerButtonAction(config);
                          if (context.mounted) {
                            _showActionFeedback(
                              context,
                              '1x Click Executed: ${log.message}',
                              AppColors.safeGreenDark,
                            );
                          }
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.double_arrow_rounded, size: 16, color: Colors.orange),
                        label: const Text('2x Click (Silent)'),
                        onPressed: () async {
                          final config = state.buttonConfigs[ButtonPressType.doublePress]!;
                          final log = await state.triggerButtonAction(config);
                          if (context.mounted) {
                            _showActionFeedback(
                              context,
                              '2x Click Executed: ${log.message}',
                              AppColors.silentAmberDark,
                            );
                          }
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.timer_outlined, size: 16, color: Colors.red),
                        label: const Text('Long Press (Siren)'),
                        onPressed: () async {
                          final config = state.buttonConfigs[ButtonPressType.longPress]!;
                          final log = await state.triggerButtonAction(config);
                          if (context.mounted) {
                            _showActionFeedback(
                              context,
                              'Long Press Executed: ${log.message}',
                              AppColors.primary,
                            );
                          }
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.link_off_rounded, size: 16, color: Colors.purple),
                        label: const Text('Simulate Snatch'),
                        onPressed: () async {
                          state.hardwareService.simulateAntiSnatchDisconnect();
                          final log = await state.alertDispatcher.dispatchAntiSnatch(state.members);
                          state.addAlertLogDirectly(log);
                          if (context.mounted) {
                            _showActionFeedback(
                              context,
                              'Anti-Snatch Disconnect Alert Triggered!',
                              AppColors.snatchPurple,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  void _showActionFeedback(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Modern Hardware Status Card
class _HardwareStatusCard extends StatelessWidget {
  final HardwareStatus hw;
  final dynamic loc;

  const _HardwareStatusCard({required this.hw, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hw.isConnected ? Icons.memory_rounded : Icons.memory_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hw.deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      hw.mode.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hw.isConnected
                      ? AppColors.safeGreen.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hw.isConnected ? AppColors.safeGreen : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hw.isConnected ? AppColors.safeGreen : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hw.isConnected ? 'ONLINE' : 'STANDBY',
                      style: TextStyle(
                        color: hw.isConnected ? AppColors.safeGreen : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 18),

          // Telemetry Row: Battery, Satellites, Signal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TelemetryTile(
                icon: Icons.battery_charging_full_rounded,
                iconColor: hw.batteryPercent > 20 ? AppColors.safeGreen : Colors.orange,
                title: 'Battery',
                value: '${hw.batteryPercent}%',
              ),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
              _TelemetryTile(
                icon: Icons.satellite_alt_rounded,
                iconColor: AppColors.infoBlue,
                title: 'GPS Signal',
                value: '${hw.satelliteCount} Sats',
              ),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
              _TelemetryTile(
                icon: Icons.cell_tower_rounded,
                iconColor: Colors.amber,
                title: 'Link Bridge',
                value: hw.mode == ConnectionMode.bluetooth ? 'BLE 5.0' : 'Wi-Fi AP',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Live Coordinates Chip / Last Known Outdoor Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  loc?.isLastKnownFallback == true
                      ? Icons.history_rounded
                      : Icons.my_location_rounded,
                  color: loc?.isLastKnownFallback == true ? Colors.amber : Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc != null
                        ? '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'
                            '${loc.isLastKnownFallback ? ' (Last Known Outdoor)' : ' (Live Accurate)'}'
                        : 'Searching for GPS Lock...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _TelemetryTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// Hero Dynamic Action Button (Reflects Long Press setting)
class _HeroSosButton extends StatelessWidget {
  final ButtonActionConfig config;
  final VoidCallback onTap;

  const _HeroSosButton({
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final action = config.actionType;
    final color = action.color;
    final gradient = action.gradient;
    final centerWord = action == ButtonActionType.loudSiren
        ? 'SOS'
        : (action == ButtonActionType.callMember
            ? 'CALL'
            : (action == ButtonActionType.safeCheckIn ? 'SAFE' : 'ALERT'));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 28,
                      spreadRadius: 6,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon, color: Colors.white, size: 48),
                      const SizedBox(height: 4),
                      Text(
                        centerWord,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                action.shortTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Long Press (${config.holdDurationSeconds}s) • ${action.defaultSubtitle}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dual Quick Action Cards (Check-in & Stealth)
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small Connection Status Pill
class _ConnectionStatusPill extends StatelessWidget {
  final bool isConnected;
  final ConnectionMode mode;

  const _ConnectionStatusPill({required this.isConnected, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.safeGreen.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
            size: 16,
            color: isConnected ? AppColors.safeGreenDark : Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connected' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isConnected ? AppColors.safeGreenDark : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
