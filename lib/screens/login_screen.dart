import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'user@panicbutton.app');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  bool _biometricAvailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final auth = context.read<AppStateProvider>().authService;
    final available = await auth.canCheckBiometrics();
    if (mounted) {
      setState(() => _biometricAvailable = available);
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final ok = await context.read<AppStateProvider>().login(
          _emailController.text,
          _passwordController.text,
        );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!ok) _error = 'Invalid email or password';
      });
    }
  }

  Future<void> _handleBiometric() async {
    final appState = context.read<AppStateProvider>();
    final ok = await appState.authService.authenticateWithBiometrics();
    if (ok && mounted) {
      await appState.loginWithSavedBiometric();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PanicButton',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ESP32 Smart Safety & Family Protection',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.person, size: 18),
                        label: const Text('User Side'),
                        onPressed: () {
                          _emailController.text = 'user@panicbutton.app';
                          _passwordController.text = '123456';
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.family_restroom, size: 18),
                        label: const Text('Member Side'),
                        onPressed: () {
                          _emailController.text = 'member@panicbutton.app';
                          _passwordController.text = '123456';
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                  if (_biometricAvailable) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _handleBiometric,
                      icon: const Icon(Icons.fingerprint, size: 24),
                      label: const Text('Unlock with Fingerprint'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
