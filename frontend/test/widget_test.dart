import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hostel_mess_app/features/auth/providers/auth_provider.dart';
import 'package:hostel_mess_app/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('Login screen displays required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Hostel Mess'), findsOneWidget);

    expect(find.text('Sign in to continue'), findsOneWidget);

    expect(find.byType(TextFormField), findsNWidgets(2));

    expect(find.text('Login'), findsOneWidget);
  });
}
