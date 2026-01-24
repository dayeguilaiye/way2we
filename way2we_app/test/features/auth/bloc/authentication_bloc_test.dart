import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  group('AuthenticationBloc', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationUnauthenticated] when AppStarted and no token',
      setUp: () {
        when(() => mockAuthProvider.getToken()).thenAnswer((_) async => null);
      },
      build: () => AuthenticationBloc(authProvider: mockAuthProvider),
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthenticationUnauthenticated()],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationAuthenticated] when AppStarted and has token',
      setUp: () {
        when(
          () => mockAuthProvider.getToken(),
        ).thenAnswer((_) async => 'valid-token');
      },
      build: () => AuthenticationBloc(authProvider: mockAuthProvider),
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthenticationAuthenticated()],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationUnauthenticated] when AppLogoutRequested',
      setUp: () {
        when(() => mockAuthProvider.logout()).thenAnswer((_) async {});
      },
      build: () => AuthenticationBloc(authProvider: mockAuthProvider),
      act: (bloc) => bloc.add(const AppLogoutRequested()),
      expect: () => [const AuthenticationUnauthenticated()],
      verify: (_) {
        verify(() => mockAuthProvider.logout()).called(1);
      },
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationAuthenticated] when AppLoginSucceeded',
      build: () => AuthenticationBloc(authProvider: mockAuthProvider),
      act: (bloc) => bloc.add(const AppLoginSucceeded()),
      expect: () => [const AuthenticationAuthenticated()],
    );
  });
}
