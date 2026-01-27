import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';

part 'reward_form_event.dart';
part 'reward_form_state.dart';

class RewardFormBloc extends Bloc<RewardFormEvent, RewardFormState> {
  RewardFormBloc({
    required RewardProvider rewardProvider,
    required GroupProvider groupProvider,
  }) : _rewardProvider = rewardProvider,
       _groupProvider = groupProvider,
       super(const RewardFormState()) {
    on<InitializeForm>(_onInitializeForm);
    on<NameChanged>(_onNameChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<CostPointsChanged>(_onCostPointsChanged);
    on<AutoFulfillChanged>(_onAutoFulfillChanged);
    on<AutoCompleteChanged>(_onAutoCompleteChanged);
    on<CoverImageSelected>(_onCoverImageSelected);
    on<CoverImageCleared>(_onCoverImageCleared);
    on<SubmitReward>(_onSubmitReward);
  }

  final RewardProvider _rewardProvider;
  final GroupProvider _groupProvider;

  Future<void> _onInitializeForm(
    InitializeForm event,
    Emitter<RewardFormState> emit,
  ) async {
    if (event.reward != null) {
      final reward = event.reward!;
      emit(
        RewardFormState(
          name: reward.name,
          description: reward.description ?? '',
          costPoints: reward.costPoints,
          autoFulfill: reward.autoFulfill,
          autoComplete: reward.autoComplete,
          coverImageUrl: reward.coverImageUrl ?? '',
          isEditMode: true,
        ),
      );
      return;
    }

    try {
      final settings = await _groupProvider.getGroupSettings(
        groupId: event.groupId,
      );
      emit(
        RewardFormState(
          autoFulfill: settings.autoFulfillRedemptionDefault,
          autoComplete: settings.autoCompleteRedemptionDefault,
          costPoints: 10,
        ),
      );
    } catch (_) {
      emit(const RewardFormState());
    }
  }

  void _onNameChanged(NameChanged event, Emitter<RewardFormState> emit) {
    emit(state.copyWith(name: event.name));
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<RewardFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onCostPointsChanged(
    CostPointsChanged event,
    Emitter<RewardFormState> emit,
  ) {
    emit(state.copyWith(costPoints: event.costPoints));
  }

  void _onAutoFulfillChanged(
    AutoFulfillChanged event,
    Emitter<RewardFormState> emit,
  ) {
    emit(state.copyWith(autoFulfill: event.autoFulfill));
  }

  void _onAutoCompleteChanged(
    AutoCompleteChanged event,
    Emitter<RewardFormState> emit,
  ) {
    emit(state.copyWith(autoComplete: event.autoComplete));
  }

  Future<void> _onCoverImageSelected(
    CoverImageSelected event,
    Emitter<RewardFormState> emit,
  ) async {
    emit(
      state.copyWith(
        isCoverUploading: true,
        coverUploadError: null,
      ),
    );

    try {
      final url = await _rewardProvider.uploadRewardCover(event.file);
      emit(
        state.copyWith(
          coverImageUrl: url,
          isCoverUploading: false,
          coverUploadError: null,
        ),
      );
    } on RewardApiException catch (e) {
      emit(
        state.copyWith(
          isCoverUploading: false,
          coverUploadError: e.message,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          isCoverUploading: false,
          coverUploadError: e.toString(),
        ),
      );
    }
  }

  void _onCoverImageCleared(
    CoverImageCleared event,
    Emitter<RewardFormState> emit,
  ) {
    emit(state.copyWith(coverImageUrl: '', coverUploadError: null));
  }

  Future<void> _onSubmitReward(
    SubmitReward event,
    Emitter<RewardFormState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: RewardFormStatus.submitting));

    try {
      if (event.rewardId != null) {
        await _rewardProvider.updateReward(
          groupId: event.groupId,
          rewardId: event.rewardId!,
          input: UpdateRewardInput(
            name: state.name,
            description: state.description.isEmpty ? null : state.description,
            costPoints: state.costPoints,
            autoFulfill: state.autoFulfill,
            autoComplete: state.autoComplete,
            coverImageUrl: state.coverImageUrl,
          ),
        );
      } else {
        await _rewardProvider.createReward(
          groupId: event.groupId,
          input: CreateRewardInput(
            name: state.name,
            description: state.description.isEmpty ? null : state.description,
            costPoints: state.costPoints,
            autoFulfill: state.autoFulfill,
            autoComplete: state.autoComplete,
            coverImageUrl: state.coverImageUrl.isEmpty
                ? null
                : state.coverImageUrl,
          ),
        );
      }

      emit(state.copyWith(status: RewardFormStatus.success));
    } on RewardApiException catch (e) {
      emit(
        state.copyWith(
          status: RewardFormStatus.failure,
          errorMessage: e.message,
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: RewardFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
