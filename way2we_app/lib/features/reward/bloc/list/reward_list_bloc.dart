import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';

part 'reward_list_event.dart';
part 'reward_list_state.dart';

class RewardListBloc extends Bloc<RewardListEvent, RewardListState> {
  RewardListBloc({required RewardProvider rewardProvider})
    : _rewardProvider = rewardProvider,
      super(const RewardListInitial()) {
    on<LoadRewards>(_onLoadRewards);
    on<RefreshRewards>(_onRefreshRewards);
    on<UpdateRewardStatus>(_onUpdateRewardStatus);
    on<PinRewardRequested>(_onPinRewardRequested);
    on<UnpinRewardRequested>(_onUnpinRewardRequested);
  }

  final RewardProvider _rewardProvider;
  int? _currentGroupId;
  String? _currentStatusFilter;
  bool _currentPinnedOnly = false;

  Future<void> _onLoadRewards(
    LoadRewards event,
    Emitter<RewardListState> emit,
  ) async {
    _currentGroupId = event.groupId;
    _currentStatusFilter = event.statusFilter;
    _currentPinnedOnly = event.pinnedOnly;

    emit(const RewardListLoading());

    try {
      final rewards = await _rewardProvider.listRewards(
        groupId: event.groupId,
        status: event.statusFilter,
        pinnedOnly: event.pinnedOnly,
      );

      emit(
        RewardListLoaded(
          rewards: _sortByPinned(rewards),
          groupId: event.groupId,
          statusFilter: event.statusFilter,
        ),
      );
    } on RewardApiException catch (e) {
      emit(RewardListError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(RewardListError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRewards(
    RefreshRewards event,
    Emitter<RewardListState> emit,
  ) async {
    if (_currentGroupId == null) return;

    try {
      final rewards = await _rewardProvider.listRewards(
        groupId: _currentGroupId!,
        status: _currentStatusFilter,
        pinnedOnly: _currentPinnedOnly,
      );

      emit(
        RewardListLoaded(
          rewards: _sortByPinned(rewards),
          groupId: _currentGroupId!,
          statusFilter: _currentStatusFilter,
        ),
      );
    } on RewardApiException catch (e) {
      emit(RewardListError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(RewardListError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRewardStatus(
    UpdateRewardStatus event,
    Emitter<RewardListState> emit,
  ) async {
    if (_currentGroupId == null) return;

    final currentState = state;
    if (currentState is! RewardListReadyState) return;

    try {
      final updated = await _rewardProvider.updateRewardStatus(
        groupId: _currentGroupId!,
        rewardId: event.rewardId,
        status: event.newStatus,
      );

      final updatedList = _applyStatusUpdate(
        currentState.rewards,
        updated,
        _currentStatusFilter,
      );

      emit(
        RewardListActionSuccess(
          rewards: _sortByPinned(updatedList),
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          updatedStatus: event.newStatus,
        ),
      );
    } on RewardApiException catch (e) {
      emit(
        RewardListActionFailure(
          rewards: currentState.rewards,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        RewardListActionFailure(
          rewards: currentState.rewards,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPinRewardRequested(
    PinRewardRequested event,
    Emitter<RewardListState> emit,
  ) async {
    if (_currentGroupId == null) return;

    final currentState = state;
    if (currentState is! RewardListReadyState) return;

    final optimistic = _applyPinnedUpdate(
      currentState.rewards,
      event.rewardId,
      true,
    );
    emit(
      RewardListLoaded(
        rewards: _sortByPinned(optimistic),
        groupId: currentState.groupId,
        statusFilter: currentState.statusFilter,
      ),
    );

    try {
      await _rewardProvider.pinReward(
        groupId: _currentGroupId!,
        rewardId: event.rewardId,
      );
    } on RewardApiException catch (e) {
      emit(
        RewardListActionFailure(
          rewards: currentState.rewards,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        RewardListActionFailure(
          rewards: currentState.rewards,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUnpinRewardRequested(
    UnpinRewardRequested event,
    Emitter<RewardListState> emit,
  ) async {
    if (_currentGroupId == null) return;

    final currentState = state;
    if (currentState is! RewardListReadyState) return;

    final optimistic = _applyPinnedUpdate(
      currentState.rewards,
      event.rewardId,
      false,
    );
    emit(
      RewardListLoaded(
        rewards: _sortByPinned(optimistic),
        groupId: currentState.groupId,
        statusFilter: currentState.statusFilter,
      ),
    );

    try {
      await _rewardProvider.unpinReward(
        groupId: _currentGroupId!,
        rewardId: event.rewardId,
      );
    } on RewardApiException catch (e) {
      emit(
        RewardListActionFailure(
          rewards: currentState.rewards,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        RewardListActionFailure(
          rewards: currentState.rewards,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.toString(),
        ),
      );
    }
  }

  List<Reward> _applyStatusUpdate(
    List<Reward> current,
    Reward updated,
    String? statusFilter,
  ) {
    final filter = statusFilter ?? 'active';
    if (filter == updated.status.name) {
      return current
          .map((reward) => reward.id == updated.id ? updated : reward)
          .toList();
    }
    return current.where((reward) => reward.id != updated.id).toList();
  }

  List<Reward> _applyPinnedUpdate(
    List<Reward> current,
    int rewardId,
    bool isPinned,
  ) {
    return current
        .map(
          (reward) => reward.id == rewardId
              ? reward.copyWith(isPinned: isPinned)
              : reward,
        )
        .toList();
  }

  List<Reward> _sortByPinned(List<Reward> rewards) {
    final indexed = rewards.asMap().entries.toList()
      ..sort((a, b) {
        if (a.value.isPinned == b.value.isPinned) {
          return a.key.compareTo(b.key);
        }
        return a.value.isPinned ? -1 : 1;
      });
    return indexed.map((entry) => entry.value).toList();
  }
}
