// This is a basic Flutter widget test for the Firebase Auth app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebaseauth/main.dart';

void main() {
  testWidgets('Login screen has email and password fields', (WidgetTester tester) async {
    // Create a mock AuthProvider
    final mockAuthProvider = AuthProvider();
    
    // Build our login screen with a mock provider
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: LoginScreen(),
        ),
      ),
    );

    // Verify that the login form has email and password fields
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    
    // Verify that the login button is shown
    expect(find.text('Login'), findsOneWidget);
    
    // Verify that the Google sign-in button is shown
    expect(find.text('Sign in with Google'), findsOneWidget);
    
    // Verify that the register link is shown
    expect(find.text('Don\'t have an account? Register'), findsOneWidget);
  });
}
