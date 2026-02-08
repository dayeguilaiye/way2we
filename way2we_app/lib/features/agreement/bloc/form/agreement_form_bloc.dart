import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

part 'agreement_form_event.dart';
part 'agreement_form_state.dart';

class AgreementFormBloc extends Bloc<AgreementFormEvent, AgreementFormState> {
  AgreementFormBloc({
    required AgreementProvider agreementProvider,
    required GroupProvider groupProvider,
  }) : _agreementProvider = agreementProvider,
       _groupProvider = groupProvider,
       super(const AgreementFormState()) {
    on<InitializeForm>(_onInitializeForm);
    on<NameChanged>(_onNameChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<PointsChanged>(_onPointsChanged);
    on<RequireConfirmationChanged>(_onRequireConfirmationChanged);
    on<CoverImageUrlChanged>(_onCoverImageUrlChanged);
    on<ApplicableMembersChanged>(_onApplicableMembersChanged);
    on<SubmitAgreement>(_onSubmitAgreement);
  }

  final AgreementProvider _agreementProvider;
  final GroupProvider _groupProvider;

  Future<void> _onInitializeForm(
    InitializeForm event,
    Emitter<AgreementFormState> emit,
  ) async {
    if (event.agreement != null) {
      final agreement = event.agreement!;
      emit(
        AgreementFormState(
          name: agreement.name,
          description: agreement.description ?? '',
          points: agreement.points,
          requireConfirmation: agreement.requireConfirmation,
          coverImageUrl: agreement.coverImageUrl ?? '',
          applicableMemberIds: agreement.applicableMemberIds,
          isEditMode: true,
        ),
      );
    } else {
      // Create mode: fetch group settings for defaults
      try {
        final settings = await _groupProvider.getGroupSettings(
          groupId: event.groupId,
        );
        emit(
          AgreementFormState(
            requireConfirmation: settings.requireConfirmationDefault,
          ),
        );
      } on Object {
        // Fallback to defaults on error
        emit(const AgreementFormState());
      }
    }
  }

  void _onNameChanged(
    NameChanged event,
    Emitter<AgreementFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<AgreementFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onPointsChanged(
    PointsChanged event,
    Emitter<AgreementFormState> emit,
  ) {
    emit(state.copyWith(points: event.points));
  }

  void _onRequireConfirmationChanged(
    RequireConfirmationChanged event,
    Emitter<AgreementFormState> emit,
  ) {
    emit(state.copyWith(requireConfirmation: event.requireConfirmation));
  }

  void _onCoverImageUrlChanged(
    CoverImageUrlChanged event,
    Emitter<AgreementFormState> emit,
  ) {
    emit(state.copyWith(coverImageUrl: event.coverImageUrl));
  }

  void _onApplicableMembersChanged(
    ApplicableMembersChanged event,
    Emitter<AgreementFormState> emit,
  ) {
    emit(state.copyWith(applicableMemberIds: event.memberIds));
  }

  Future<void> _onSubmitAgreement(
    SubmitAgreement event,
    Emitter<AgreementFormState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: AgreementFormStatus.submitting));

    try {
      Agreement result;

      if (event.agreementId != null) {
        // Edit mode
        result = await _agreementProvider.updateAgreement(
          groupId: event.groupId,
          agreementId: event.agreementId!,
          input: UpdateAgreementInput(
            name: state.name,
            description: state.description.isEmpty ? null : state.description,
            points: state.points,
            requireConfirmation: state.requireConfirmation,
            coverImageUrl: state.coverImageUrl.isEmpty
                ? null
                : state.coverImageUrl,
            applicableMemberIds: state.applicableMemberIds.isEmpty
                ? null
                : state.applicableMemberIds,
          ),
        );
      } else {
        // Create mode
        result = await _agreementProvider.createAgreement(
          groupId: event.groupId,
          input: CreateAgreementInput(
            name: state.name,
            description: state.description.isEmpty ? null : state.description,
            points: state.points,
            requireConfirmation: state.requireConfirmation,
            coverImageUrl: state.coverImageUrl.isEmpty
                ? null
                : state.coverImageUrl,
            applicableMemberIds: state.applicableMemberIds.isEmpty
                ? null
                : state.applicableMemberIds,
          ),
        );
      }

      emit(
        state.copyWith(
          status: AgreementFormStatus.success,
          createdAgreement: result,
        ),
      );
    } on AgreementApiException catch (e) {
      emit(
        state.copyWith(
          status: AgreementFormStatus.failure,
          errorMessage: e.message,
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: AgreementFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
