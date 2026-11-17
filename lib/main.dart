import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'providers/app_state_provider.dart';
import 'screens/login_screen.dart';
import 'screens/member_home_screen.dart';
import 'screens/user_home_screen.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundMonitorService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider()..init(),
      child: const PanicButtonApp(),
    ),
  );
}

class PanicButtonApp extends StatelessWidget {
  const PanicButtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PanicButton',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AppStateProvider>(
        builder: (context, state, _) {
          if (!state.isInitialized) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.sosGradient,
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            );
          }

          final user = state.currentUser;
          if (user == null) {
            return const LoginScreen();
          }

          if (user.role == UserRole.member) {
            return const MemberHomeScreen();
          }
          return const UserHomeScreen();
        },
      ),
    );
  }
}
