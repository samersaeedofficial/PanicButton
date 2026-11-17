import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

class FamilyTab extends StatelessWidget {
  const FamilyTab({super.key});

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showAddMemberModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: 'Family');
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscurePass = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Add Family Member / Guardian',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This person will receive your live GPS alerts and can log into the Member app.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: relationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (e.g. Father, Sister, Friend)',
                    prefixIcon: Icon(Icons.favorite_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Member Login Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: passCtrl,
                  obscureText: obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Member Login Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () => setModalState(() => obscurePass = !obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty ||
                        emailCtrl.text.trim().isEmpty ||
                        passCtrl.text.isEmpty) {
                      return;
                    }
                    await context.read<AppStateProvider>().addFamilyMember(
                          name: nameCtrl.text,
                          relation: relationCtrl.text.isEmpty ? 'Family' : relationCtrl.text,
                          phone: phoneCtrl.text,
                          email: emailCtrl.text,
                          password: passCtrl.text,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Guardian Member'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final members = state.members;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trusted Emergency Circle',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Guardians receive instant SOS, coordinates & voice clips.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 48, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Family Members Added',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add your family or trusted contacts so they receive alerts.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _showAddMemberModal(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Guardian'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...members.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        m.relation,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.phone,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: 'Delete member',
                            onPressed: () => state.deleteFamilyMember(m.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: AppColors.borderLight, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.vpn_key_outlined, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Login: ${m.email}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quick call
                          IconButton(
                            icon: const Icon(Icons.call_rounded, size: 18, color: Colors.green),
                            onPressed: () => _makeCall(m.phone),
                            tooltip: 'Call Member',
                          ),
                          // Quick SMS
                          IconButton(
                            icon: const Icon(Icons.message_rounded, size: 18, color: AppColors.infoBlue),
                            onPressed: () => _sendSms(m.phone),
                            tooltip: 'SMS Member',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: members.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMemberModal(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Guardian', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}
