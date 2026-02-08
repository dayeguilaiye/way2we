import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/group/bloc/join_group_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

class MockGroupProvider extends Mock implements GroupProvider {}

void main() {
  late MockGroupProvider mockGroupProvider;

  setUp(() {
    mockGroupProvider = MockGroupProvider();
  });

  group('JoinGroupBloc', () {
    test('initial state is JoinGroupState with empty code', () {
      final bloc = JoinGroupBloc(groupProvider: mockGroupProvider);
      expect(bloc.state.status, JoinGroupStatus.initial);
      expect(bloc.state.invitationCode, '');
      expect(bloc.state.canPreview, false);
      expect(bloc.state.canJoin, false);
    });

    blocTest<JoinGroupBloc, JoinGroupState>(
      'uppercases code and resets status when code changes',
      build: () => JoinGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const JoinGroupState(status: JoinGroupStatus.failure),
      act: (bloc) => bloc.add(const JoinGroupCodeChanged('ab12cd')),
      expect: () => [
        isA<JoinGroupState>()
            .having((s) => s.status, 'status', JoinGroupStatus.initial)
            .having((s) => s.invitationCode, 'invitationCode', 'AB12CD')
            .having((s) => s.isCodeValid, 'isCodeValid', true),
      ],
    );

    blocTest<JoinGroupBloc, JoinGroupState>(
      'loads preview successfully for valid code',
      setUp: () {
        when(
          () =>
              mockGroupProvider.getGroupByInvitation(code: any(named: 'code')),
        ).thenAnswer(
          (_) async => const GroupPreviewResponse(
            id: 1,
            name: 'Family',
            memberCount: 3,
            createdAt: '2025-01-01T00:00:00Z',
          ),
        );
      },
      build: () => JoinGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const JoinGroupState(invitationCode: 'ABC123'),
      act: (bloc) => bloc.add(const JoinGroupPreviewRequested()),
      expect: () => [
        isA<JoinGroupState>().having(
          (s) => s.status,
          'status',
          JoinGroupStatus.loadingPreview,
        ),
        isA<JoinGroupState>()
            .having((s) => s.status, 'status', JoinGroupStatus.previewLoaded)
            .having((s) => s.groupId, 'groupId', 1)
            .having((s) => s.groupName, 'groupName', 'Family')
            .having((s) => s.memberCount, 'memberCount', 3),
      ],
    );

    blocTest<JoinGroupBloc, JoinGroupState>(
      'emits failure when preview request fails',
      setUp: () {
        when(
          () =>
              mockGroupProvider.getGroupByInvitation(code: any(named: 'code')),
        ).thenThrow(
          const GroupApiException(
            'Invalid invitation code',
            code: 'ERR_INVITATION_CODE_INVALID',
          ),
        );
      },
      build: () => JoinGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const JoinGroupState(invitationCode: 'ABC123'),
      act: (bloc) => bloc.add(const JoinGroupPreviewRequested()),
      expect: () => [
        isA<JoinGroupState>().having(
          (s) => s.status,
          'status',
          JoinGroupStatus.loadingPreview,
        ),
        isA<JoinGroupState>()
            .having((s) => s.status, 'status', JoinGroupStatus.failure)
            .having(
              (s) => s.errorCode,
              'errorCode',
              'ERR_INVITATION_CODE_INVALID',
            ),
      ],
    );

    blocTest<JoinGroupBloc, JoinGroupState>(
      'joins group successfully after preview',
      setUp: () {
        when(
          () => mockGroupProvider.joinGroup(
            invitationCode: any(named: 'invitationCode'),
          ),
        ).thenAnswer(
          (_) async => const JoinGroupResponse(
            groupId: 1,
            groupName: 'Family',
            memberCount: 3,
            role: 'member',
          ),
        );
      },
      build: () => JoinGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const JoinGroupState(
        status: JoinGroupStatus.previewLoaded,
        invitationCode: 'ABC123',
        groupId: 1,
        groupName: 'Family',
        memberCount: 3,
      ),
      act: (bloc) => bloc.add(const JoinGroupConfirmed()),
      expect: () => [
        isA<JoinGroupState>().having(
          (s) => s.status,
          'status',
          JoinGroupStatus.joining,
        ),
        isA<JoinGroupState>()
            .having((s) => s.status, 'status', JoinGroupStatus.success)
            .having((s) => s.groupId, 'groupId', 1)
            .having((s) => s.groupName, 'groupName', 'Family'),
      ],
    );

    blocTest<JoinGroupBloc, JoinGroupState>(
      'does nothing when preview requested with invalid code',
      build: () => JoinGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const JoinGroupState(invitationCode: 'A1'),
      act: (bloc) => bloc.add(const JoinGroupPreviewRequested()),
      expect: () => <JoinGroupState>[],
      verify: (_) {
        verifyNever(
          () =>
              mockGroupProvider.getGroupByInvitation(code: any(named: 'code')),
        );
      },
    );

    blocTest<JoinGroupBloc, JoinGroupState>(
      'does nothing when join requested without preview data',
      build: () => JoinGroupBloc(groupProvider: mockGroupProvider),
      seed: () => const JoinGroupState(invitationCode: 'ABC123'),
      act: (bloc) => bloc.add(const JoinGroupConfirmed()),
      expect: () => <JoinGroupState>[],
      verify: (_) {
        verifyNever(
          () => mockGroupProvider.joinGroup(
            invitationCode: any(named: 'invitationCode'),
          ),
        );
      },
    );
  });
}
