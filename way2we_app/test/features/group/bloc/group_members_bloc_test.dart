import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/group/bloc/members/group_members_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/models/member.dart';

class MockGroupProvider extends Mock implements GroupProvider {}

void main() {
  late GroupProvider groupProvider;
  late GroupMembersBloc bloc;

  setUp(() {
    groupProvider = MockGroupProvider();
    bloc = GroupMembersBloc(groupProvider: groupProvider);
  });

  const memberJson = {
    'id': 1,
    'user_id': 101,
    'nickname': 'TestUser',
    'avatar_url': 'example.com/avatar',
    'role': 'admin',
    'permissions': ['all'],
    'joined_at': '2023-01-01T12:00:00Z',
  };

  final member = GroupMember.fromJson(memberJson);

  group('GroupMembersBloc', () {
    test('initial state is GroupMembersInitial', () {
      expect(bloc.state, equals(GroupMembersInitial()));
    });

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [Loading, Loaded] when LoadGroupMembers succeeds',
      build: () {
        when(
          () => groupProvider.listMembers(groupId: 1),
        ).thenAnswer((_) async => [memberJson]);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGroupMembers(1)),
      expect: () => [
        GroupMembersLoading(),
        GroupMembersLoaded([member]),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [Loading, Error] when LoadGroupMembers fails',
      build: () {
        when(
          () => groupProvider.listMembers(groupId: 1),
        ).thenThrow(Exception('Failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGroupMembers(1)),
      expect: () => [
        GroupMembersLoading(),
        const GroupMembersError('Exception: Failed to load'),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [OperationInProgress, Success, Loaded] when UpdateMemberRole succeeds',
      build: () {
        when(
          () => groupProvider.updateMemberRole(
            groupId: 1,
            userId: 101,
            role: 'member',
          ),
        ).thenAnswer((_) async {});

        // Mock list refresh
        when(
          () => groupProvider.listMembers(groupId: 1),
        ).thenAnswer((_) async => []);

        return bloc;
      },
      seed: () => GroupMembersLoaded([member]),
      act: (bloc) => bloc.add(
        const UpdateMemberRole(
          groupId: 1,
          userId: 101,
          role: GroupRole.member,
        ),
      ),
      expect: () => [
        MemberOperationInProgress(),
        const MemberOperationSuccess('角色更新成功'),
        const GroupMembersLoaded([]),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [OperationInProgress, Success, Loaded] when UpdateMemberPermissions succeeds',
      build: () {
        when(
          () => groupProvider.updateMemberPermissions(
            groupId: 1,
            userId: 101,
            permissions: ['create_agreement'],
          ),
        ).thenAnswer((_) async {});

        // Mock list refresh
        when(
          () => groupProvider.listMembers(groupId: 1),
        ).thenAnswer((_) async => []);

        return bloc;
      },
      seed: () => GroupMembersLoaded([member]),
      act: (bloc) => bloc.add(
        const UpdateMemberPermissions(
          groupId: 1,
          userId: 101,
          permissions: ['create_agreement'],
        ),
      ),
      expect: () => [
        MemberOperationInProgress(),
        const MemberOperationSuccess('权限更新成功'),
        const GroupMembersLoaded([]),
      ],
    );
  });
}
