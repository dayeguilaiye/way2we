import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

class MockGroupProvider extends Mock implements GroupProvider {}

void main() {
  group('GroupControlBloc', () {
    late GroupProvider groupProvider;
    late GroupControlBloc bloc;

    final mockGroups = [
      const UserGroup(
        id: 1,
        name: 'Group 1',
        memberCount: 2,
        role: 'admin',
        joinedAt: '2023-01-01',
        createdAt: '2023-01-01',
      ),
      const UserGroup(
        id: 2,
        name: 'Group 2',
        memberCount: 3,
        role: 'member',
        joinedAt: '2023-01-01',
        createdAt: '2023-01-01',
      ),
    ];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      groupProvider = MockGroupProvider();
      bloc = GroupControlBloc(groupProvider: groupProvider);
    });

    tearDown(() {
      bloc.close();
    });

    blocTest<GroupControlBloc, GroupControlState>(
      'emits [LoadInProgress, LoadSuccess] when loading groups success',
      setUp: () {
        when(() => groupProvider.getUserGroups()).thenAnswer(
          (_) async => GetUserGroupsResponse(groups: mockGroups),
        );
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const GroupControlGroupsLoaded()),
      expect: () => [
        GroupControlLoadInProgress(),
        GroupControlLoadSuccess(
          groups: mockGroups,
          selectedGroup: mockGroups.first,
        ),
      ],
    );

    blocTest<GroupControlBloc, GroupControlState>(
      'selects persisted group if exists',
      setUp: () {
        SharedPreferences.setMockInitialValues({'last_selected_group_id': 2});
        when(() => groupProvider.getUserGroups()).thenAnswer(
          (_) async => GetUserGroupsResponse(groups: mockGroups),
        );
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const GroupControlGroupsLoaded()),
      expect: () => [
        GroupControlLoadInProgress(),
        GroupControlLoadSuccess(
          groups: mockGroups,
          selectedGroup: mockGroups[1],
        ),
      ],
    );

    blocTest<GroupControlBloc, GroupControlState>(
      'selects group and persists',
      build: () => bloc,
      seed: () => GroupControlLoadSuccess(
        groups: mockGroups,
        selectedGroup: mockGroups[0],
      ),
      act: (bloc) => bloc.add(const GroupControlGroupSelected(2)),
      expect: () => [
        GroupControlLoadSuccess(
          groups: mockGroups,
          selectedGroup: mockGroups[1],
        ),
      ],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('last_selected_group_id'), 2);
      },
    );
  });
}
