part of 'reward_form_bloc.dart';

sealed class RewardFormEvent extends Equatable {
  const RewardFormEvent();

  @override
  List<Object?> get props => [];
}

final class InitializeForm extends RewardFormEvent {
  const InitializeForm({required this.groupId, this.reward});

  final int groupId;
  final Reward? reward;

  @override
  List<Object?> get props => [groupId, reward];
}

final class NameChanged extends RewardFormEvent {
  const NameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class DescriptionChanged extends RewardFormEvent {
  const DescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

final class CostPointsChanged extends RewardFormEvent {
  const CostPointsChanged(this.costPoints);

  final int costPoints;

  @override
  List<Object?> get props => [costPoints];
}

final class AutoFulfillChanged extends RewardFormEvent {
  const AutoFulfillChanged(this.autoFulfill);

  final bool autoFulfill;

  @override
  List<Object?> get props => [autoFulfill];
}

final class AutoCompleteChanged extends RewardFormEvent {
  const AutoCompleteChanged(this.autoComplete);

  final bool autoComplete;

  @override
  List<Object?> get props => [autoComplete];
}

final class CoverImageSelected extends RewardFormEvent {
  const CoverImageSelected(this.file);

  final XFile file;

  @override
  List<Object?> get props => [file];
}

final class CoverImageCleared extends RewardFormEvent {
  const CoverImageCleared();
}

final class SubmitReward extends RewardFormEvent {
  const SubmitReward({required this.groupId, this.rewardId});

  final int groupId;
  final int? rewardId;

  @override
  List<Object?> get props => [groupId, rewardId];
}
