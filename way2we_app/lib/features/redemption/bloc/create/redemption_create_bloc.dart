import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';

part 'redemption_create_event.dart';
part 'redemption_create_state.dart';

class RedemptionCreateBloc
    extends Bloc<RedemptionCreateEvent, RedemptionCreateState> {
  RedemptionCreateBloc({required RedemptionProvider redemptionProvider})
    : _redemptionProvider = redemptionProvider,
      super(const RedemptionCreateState()) {
    on<SubmitRedemption>(_onSubmit);
  }

  final RedemptionProvider _redemptionProvider;

  Future<void> _onSubmit(
    SubmitRedemption event,
    Emitter<RedemptionCreateState> emit,
  ) async {
    emit(state.copyWith(status: RedemptionCreateStatus.submitting));

    try {
      final order = await _redemptionProvider.createRedemption(
        groupId: event.groupId,
        rewardId: event.rewardId,
        quantity: event.quantity,
      );
      emit(
        state.copyWith(
          status: RedemptionCreateStatus.success,
          order: order,
        ),
      );
    } on RedemptionApiException catch (e) {
      emit(
        state.copyWith(
          status: RedemptionCreateStatus.failure,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: RedemptionCreateStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }
}
