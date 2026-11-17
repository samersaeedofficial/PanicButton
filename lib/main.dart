import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'providers/app_state_provider.dart';
import 'screens/login_screen.dart';
import 'screens/member_home_screen.dart';
import 'screens/user_home_screen.dart';
import 'services/background_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade700),
        useMaterial3: true,
      ),
      home: Consumer<AppStateProvider>(
        builder: (context, state, _) {
          if (!state.isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
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
