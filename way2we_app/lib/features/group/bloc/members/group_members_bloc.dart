import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/models/member.dart';

part 'group_members_event.dart';
part 'group_members_state.dart';

class GroupMembersBloc extends Bloc<GroupMembersEvent, GroupMembersState> {
  GroupMembersBloc({required GroupProvider groupProvider})
    : _groupProvider = groupProvider,
      super(GroupMembersInitial()) {
    on<LoadGroupMembers>(_onLoadMembers);
    on<UpdateMemberRole>(_onUpdateRole);
    on<UpdateMemberPermissions>(_onUpdatePermissions);
  }

  final GroupProvider _groupProvider;

  Future<void> _onLoadMembers(
    LoadGroupMembers event,
    Emitter<GroupMembersState> emit,
  ) async {
    emit(GroupMembersLoading());
    try {
      final membersJson = await _groupProvider.listMembers(
        groupId: event.groupId,
      );
      final members = membersJson.map(GroupMember.fromJson).toList();
      emit(GroupMembersLoaded(members));
    } on GroupApiException catch (e) {
      emit(GroupMembersError(e.message));
    } on Object catch (e) {
      emit(GroupMembersError(e.toString()));
    }
  }

  Future<void> _onUpdateRole(
    UpdateMemberRole event,
    Emitter<GroupMembersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GroupMembersLoaded) return;

    emit(MemberOperationInProgress());
    try {
      await _groupProvider.updateMemberRole(
        groupId: event.groupId,
        userId: event.userId,
        role: event.role.name,
      );

      // Refresh list
      final membersJson = await _groupProvider.listMembers(
        groupId: event.groupId,
      );
      final members = membersJson.map(GroupMember.fromJson).toList();

      emit(const MemberOperationSuccess('角色更新成功'));
      emit(GroupMembersLoaded(members));
    } on GroupApiException catch (e) {
      emit(MemberOperationFailure(e.message));
      emit(currentState);
    } on Object catch (e) {
      emit(MemberOperationFailure(e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onUpdatePermissions(
    UpdateMemberPermissions event,
    Emitter<GroupMembersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GroupMembersLoaded) return;

    emit(MemberOperationInProgress());
    try {
      await _groupProvider.updateMemberPermissions(
        groupId: event.groupId,
        userId: event.userId,
        permissions: event.permissions,
      );

      // Refresh list
      final membersJson = await _groupProvider.listMembers(
        groupId: event.groupId,
      );
      final members = membersJson.map(GroupMember.fromJson).toList();

      emit(const MemberOperationSuccess('权限更新成功'));
      emit(GroupMembersLoaded(members));
    } on GroupApiException catch (e) {
      emit(MemberOperationFailure(e.message));
      emit(currentState);
    } on Object catch (e) {
      emit(MemberOperationFailure(e.toString()));
      emit(currentState);
    }
  }
}
