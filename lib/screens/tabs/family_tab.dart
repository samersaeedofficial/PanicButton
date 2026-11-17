import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class FamilyTab extends StatelessWidget {
  const FamilyTab({super.key});

  void _showAddMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Family Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: relationCtrl,
                decoration:
                    const InputDecoration(labelText: 'Relation (e.g. Father)'),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'Login Email for Member'),
              ),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Login Password for Member',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
                    relation: relationCtrl.text.isEmpty
                        ? 'Family'
                        : relationCtrl.text,
                    phone: phoneCtrl.text,
                    email: emailCtrl.text,
                    password: passCtrl.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Member'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final members = state.members;

    return Scaffold(
      body: members.isEmpty
          ? const Center(
              child: Text(
                'No family members added yet.\nTap + to add someone who can track & receive alerts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final m = members[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(m.name[0].toUpperCase()),
                    ),
                    title: Text(
                      '${m.name} (${m.relation})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${m.phone}\nLogin: ${m.email}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => state.deleteFamilyMember(m.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }
}
