import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockGroupProvider extends Mock implements GroupProvider {}

void main() {
  group('AuthenticationBloc', () {
    late MockAuthProvider mockAuthProvider;
    late MockGroupProvider mockGroupProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockGroupProvider = MockGroupProvider();
    });

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationUnauthenticated] when AppStarted and no token',
      setUp: () {
        when(() => mockAuthProvider.getToken()).thenAnswer((_) async => null);
        when(
          () => mockGroupProvider.getUserGroups(),
        ).thenAnswer((_) async => const GetUserGroupsResponse(groups: []));
      },
      build: () => AuthenticationBloc(
        authProvider: mockAuthProvider,
        groupProvider: mockGroupProvider,
      ),
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthenticationUnauthenticated()],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationAuthenticated] when AppStarted and has token',
      setUp: () {
        when(
          () => mockAuthProvider.getToken(),
        ).thenAnswer((_) async => 'valid-token');
        when(
          () => mockGroupProvider.getUserGroups(),
        ).thenAnswer((_) async => const GetUserGroupsResponse(groups: []));
      },
      build: () => AuthenticationBloc(
        authProvider: mockAuthProvider,
        groupProvider: mockGroupProvider,
      ),
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const AuthenticationAuthenticated()],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationUnauthenticated] when AppLogoutRequested',
      setUp: () {
        when(() => mockAuthProvider.logout()).thenAnswer((_) async {});
      },
      build: () => AuthenticationBloc(
        authProvider: mockAuthProvider,
        groupProvider: mockGroupProvider,
      ),
      act: (bloc) => bloc.add(const AppLogoutRequested()),
      expect: () => [const AuthenticationUnauthenticated()],
      verify: (_) {
        verify(() => mockAuthProvider.logout()).called(1);
      },
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationAuthenticated] when AppLoginSucceeded (no groups)',
      setUp: () {
        when(
          () => mockGroupProvider.getUserGroups(),
        ).thenAnswer((_) async => const GetUserGroupsResponse(groups: []));
      },
      build: () => AuthenticationBloc(
        authProvider: mockAuthProvider,
        groupProvider: mockGroupProvider,
      ),
      act: (bloc) => bloc.add(const AppLoginSucceeded()),
      expect: () => [const AuthenticationAuthenticated(hasGroup: false)],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationAuthenticated] when AppLoginSucceeded (has groups)',
      setUp: () {
        when(() => mockGroupProvider.getUserGroups()).thenAnswer(
          (_) async => const GetUserGroupsResponse(
            groups: [
              UserGroup(
                id: 1,
                name: 'G',
                role: 'admin',
                joinedAt: '',
                createdAt: '',
                memberCount: 1,
                permissions: [],
              ),
            ],
          ),
        );
      },
      build: () => AuthenticationBloc(
        authProvider: mockAuthProvider,
        groupProvider: mockGroupProvider,
      ),
      act: (bloc) => bloc.add(const AppLoginSucceeded()),
      expect: () => [const AuthenticationAuthenticated(hasGroup: true)],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationAuthenticated] when AppLoginSucceeded with needsOnboarding (skips group check)',
      build: () => AuthenticationBloc(
        authProvider: mockAuthProvider,
        groupProvider: mockGroupProvider,
      ),
      act: (bloc) => bloc.add(const AppLoginSucceeded(needsOnboarding: true)),
      expect: () => [const AuthenticationAuthenticated(needsOnboarding: true)],
      verify: (_) {
        verifyNever(() => mockGroupProvider.getUserGroups());
      },
    );
  });
}
