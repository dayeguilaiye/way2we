import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/auth/bloc/verification_code_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/features/auth/view/login_page.dart';

import '../../../helpers/pump_app.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockVerificationCodeBloc
    extends MockBloc<VerificationCodeEvent, VerificationCodeState>
    implements VerificationCodeBloc {}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget buildTestWidget() {
    return RepositoryProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: BlocProvider<VerificationCodeBloc>(
        create: (_) => VerificationCodeBloc(authProvider: mockAuthProvider),
        child: const AuthView(),
      ),
    );
  }

  group('LoginPage (AuthView) UI Tests', () {
    testWidgets('renders register mode by default', (tester) async {
      await tester.pumpApp(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify register mode elements
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('switches to login mode when Login tab is tapped', (
      tester,
    ) async {
      await tester.pumpApp(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap "Log In" toggle
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Should show Login button and NO Confirm Password (register-only field)
      expect(find.text('Create Account'), findsNothing);
      expect(find.text('Confirm Password'), findsNothing);

      // Should show password/code login mode toggles
      expect(find.text('Password Login'), findsOneWidget);
      expect(find.text('Code Login'), findsOneWidget);

      // Password field should be visible (lock icon)
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows verification code input in code login mode', (
      tester,
    ) async {
      await tester.pumpApp(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Login mode
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Switch to Code Login
      await tester.tap(find.text('Code Login'));
      await tester.pumpAndSettle();

      // Should show verification code field (numbers icon)
      expect(find.byIcon(Icons.numbers), findsOneWidget);

      // Password field should NOT be visible
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('switches back to password login mode', (tester) async {
      await tester.pumpApp(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Login mode
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Switch to Code Login first
      await tester.tap(find.text('Code Login'));
      await tester.pumpAndSettle();

      // Switch back to Password Login
      await tester.tap(find.text('Password Login'));
      await tester.pumpAndSettle();

      // Password field should be visible again
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // Verification code numbers icon should NOT be visible
      expect(find.byIcon(Icons.numbers), findsNothing);
    });

    testWidgets('switches back to register mode from login mode', (
      tester,
    ) async {
      await tester.pumpApp(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Login mode
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Switch back to Register mode
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Should show register-specific elements
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('shows social login options', (tester) async {
      await tester.pumpApp(buildTestWidget());
      await tester.pumpAndSettle();

      // Social login icons should be present
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget); // Google
      expect(find.byIcon(Icons.apple), findsOneWidget); // Apple
    });
  });
}
