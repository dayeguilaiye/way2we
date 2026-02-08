import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/group/bloc/create_group_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

class MockGroupProvider extends Mock implements GroupProvider {}

void main() {
  late MockGroupProvider mockGroupProvider;

  setUp(() {
    mockGroupProvider = MockGroupProvider();
  });

  group('CreateGroupBloc', () {
    test('initial state is CreateGroupState with empty name', () {
      final bloc = CreateGroupBloc(groupProvider: mockGroupProvider);
      expect(bloc.state.name, '');
      expect(bloc.state.status, CreateGroupStatus.initial);
      expect(bloc.state.canSubmit, false);
    });

    blocTest<CreateGroupBloc, CreateGroupState>(
      'emits updated name when CreateGroupNameChanged is added',
      build: () => CreateGroupBloc(groupProvider: mockGroupProvider),
      act: (bloc) => bloc.add(const CreateGroupNameChanged('我的家庭')),
      expect: () => [
        isA<CreateGroupState>()
            .having((s) => s.name, 'name', '我的家庭')
            .having((s) => s.canSubmit, 'canSubmit', true),
      ],
    );

    blocTest<CreateGroupBloc, CreateGroupState>(
      'emits success when CreateGroupSubmitted succeeds',
      setUp: () {
        when(
          () => mockGroupProvider.createGroup(name: any(named: 'name')),
        ).thenAnswer(
          (_) async => const CreateGroupResponse(
            id: 1,
            name: '我的家庭',
            role: 'admin',
          ),
        );
      },
      build: () => CreateGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const CreateGroupState(name: '我的家庭'),
      act: (bloc) => bloc.add(const CreateGroupSubmitted()),
      expect: () => [
        isA<CreateGroupState>().having(
          (s) => s.status,
          'status',
          CreateGroupStatus.submitting,
        ),
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.success)
            .having((s) => s.groupId, 'groupId', 1),
      ],
    );

    blocTest<CreateGroupBloc, CreateGroupState>(
      'emits failure when CreateGroupSubmitted fails',
      setUp: () {
        when(
          () => mockGroupProvider.createGroup(name: any(named: 'name')),
        ).thenThrow(const GroupApiException('创建失败'));
      },
      build: () => CreateGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const CreateGroupState(name: '我的家庭'),
      act: (bloc) => bloc.add(const CreateGroupSubmitted()),
      expect: () => [
        isA<CreateGroupState>().having(
          (s) => s.status,
          'status',
          CreateGroupStatus.submitting,
        ),
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', '创建失败'),
      ],
    );

    blocTest<CreateGroupBloc, CreateGroupState>(
      'does not submit when name is empty',
      build: () => CreateGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const CreateGroupState(),
      act: (bloc) => bloc.add(const CreateGroupSubmitted()),
      expect: () => <CreateGroupState>[],
      verify: (_) {
        verifyNever(
          () => mockGroupProvider.createGroup(name: any(named: 'name')),
        );
      },
    );

    blocTest<CreateGroupBloc, CreateGroupState>(
      'does not submit when name is too long',
      build: () => CreateGroupBloc(groupProvider: mockGroupProvider),
      seed: () => CreateGroupState(name: 'a' * 31),
      act: (bloc) => bloc.add(const CreateGroupSubmitted()),
      expect: () => <CreateGroupState>[],
      verify: (_) {
        verifyNever(
          () => mockGroupProvider.createGroup(name: any(named: 'name')),
        );
      },
    );
  });

  group('CreateGroupState', () {
    test('isNameValid returns false for empty name', () {
      const state = CreateGroupState();
      expect(state.isNameValid, false);
    });

    test('isNameValid returns true for valid name', () {
      const state = CreateGroupState(name: '我的家庭');
      expect(state.isNameValid, true);
    });

    test('isNameValid returns false for name longer than 30 chars', () {
      final state = CreateGroupState(name: 'a' * 31);
      expect(state.isNameValid, false);
    });

    test('isNameValid returns true for name exactly 30 chars', () {
      final state = CreateGroupState(name: 'a' * 30);
      expect(state.isNameValid, true);
    });

    test('canSubmit is true when name is valid and status is initial', () {
      const state = CreateGroupState(name: '我的家庭');
      expect(state.canSubmit, true);
    });

    test('canSubmit is false when status is submitting', () {
      const state = CreateGroupState(
        name: '我的家庭',
        status: CreateGroupStatus.submitting,
      );
      expect(state.canSubmit, false);
    });
  });
}
