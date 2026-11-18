import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String getDashboardTitle(String role) {
    switch (role) {
      case 'admin':
        return 'Admin Dashboard';
      case 'staff':
        return 'Mess Staff Dashboard';
      case 'student':
        return 'Student Dashboard';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final user = authProvider.user!;

    return Scaffold(
      appBar: AppBar(
        title: Text(getDashboardTitle(user.role)),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 48)),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(user.email),
            const SizedBox(height: 12),
            Chip(label: Text(user.role.toUpperCase())),
          ],
        ),
      ),
    );
  }
}
