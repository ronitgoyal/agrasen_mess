import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/student_dashboard/screens/student_dashboard_screen.dart';
import 'features/qr_scanner/screens/staff_home_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const HostelMessApp());
}

class HostelMessApp extends StatelessWidget {
  const HostelMessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = AuthProvider();
        provider.initialize();
        return provider;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hostel Mess Management',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isInitializing) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}
    if (authProvider.isLoggedIn) {
      final role = authProvider.user!.role;

      if (role == 'student') {
        return const StudentDashboardPage();
      }

      if (role == 'staff' || role == 'mess_staff' || role == 'mess_incharge') {
        return const StaffHomeScreen();
      }

      if (role == 'admin') {
        return AdminDashboardScreen();
      }

      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
