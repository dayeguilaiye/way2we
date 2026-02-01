import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';

part 'redemption_detail_event.dart';
part 'redemption_detail_state.dart';

class RedemptionDetailBloc
    extends Bloc<RedemptionDetailEvent, RedemptionDetailState> {
  RedemptionDetailBloc({required RedemptionProvider redemptionProvider})
    : _redemptionProvider = redemptionProvider,
      super(const RedemptionDetailInitial()) {
    on<LoadOrderDetail>(_onLoad);
    on<RefreshOrderDetail>(_onRefresh);
    on<FulfillOrderRequested>(_onFulfill);
    on<ConfirmOrderRequested>(_onConfirm);
    on<MarkUnsatisfiedRequested>(_onUnsatisfied);
  }

  final RedemptionProvider _redemptionProvider;

  int? _groupId;
  int? _orderId;

  Future<void> _onLoad(
    LoadOrderDetail event,
    Emitter<RedemptionDetailState> emit,
  ) async {
    _groupId = event.groupId;
    _orderId = event.orderId;

    emit(const RedemptionDetailLoading());
    try {
      final order = await _redemptionProvider.getOrderDetail(
        groupId: event.groupId,
        orderId: event.orderId,
      );
      emit(RedemptionDetailLoaded(order: order, groupId: event.groupId));
    } on RedemptionApiException catch (e) {
      emit(RedemptionDetailError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(RedemptionDetailError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshOrderDetail event,
    Emitter<RedemptionDetailState> emit,
  ) async {
    if (_groupId == null || _orderId == null) return;

    try {
      final order = await _redemptionProvider.getOrderDetail(
        groupId: _groupId!,
        orderId: _orderId!,
      );
      emit(RedemptionDetailLoaded(order: order, groupId: _groupId!));
    } on RedemptionApiException catch (e) {
      emit(RedemptionDetailError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(RedemptionDetailError(message: e.toString()));
    }
  }

  Future<void> _onFulfill(
    FulfillOrderRequested event,
    Emitter<RedemptionDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RedemptionDetailReadyState) return;

    try {
      await _redemptionProvider.fulfillOrder(
        groupId: currentState.groupId,
        orderId: currentState.order.id,
      );
      final order = await _redemptionProvider.getOrderDetail(
        groupId: currentState.groupId,
        orderId: currentState.order.id,
      );
      emit(
        RedemptionDetailActionSuccess(
          order: order,
          groupId: currentState.groupId,
          action: RedemptionDetailAction.fulfill,
        ),
      );
    } on RedemptionApiException catch (e) {
      emit(
        RedemptionDetailActionFailure(
          order: currentState.order,
          groupId: currentState.groupId,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        RedemptionDetailActionFailure(
          order: currentState.order,
          groupId: currentState.groupId,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onConfirm(
    ConfirmOrderRequested event,
    Emitter<RedemptionDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RedemptionDetailReadyState) return;

    try {
      await _redemptionProvider.confirmOrder(
        groupId: currentState.groupId,
        orderId: currentState.order.id,
      );
      final order = await _redemptionProvider.getOrderDetail(
        groupId: currentState.groupId,
        orderId: currentState.order.id,
      );
      emit(
        RedemptionDetailActionSuccess(
          order: order,
          groupId: currentState.groupId,
          action: RedemptionDetailAction.confirm,
        ),
      );
    } on RedemptionApiException catch (e) {
      emit(
        RedemptionDetailActionFailure(
          order: currentState.order,
          groupId: currentState.groupId,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        RedemptionDetailActionFailure(
          order: currentState.order,
          groupId: currentState.groupId,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUnsatisfied(
    MarkUnsatisfiedRequested event,
    Emitter<RedemptionDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RedemptionDetailReadyState) return;

    try {
      await _redemptionProvider.markUnsatisfied(
        groupId: currentState.groupId,
        orderId: currentState.order.id,
        reason: event.reason,
      );
      final order = await _redemptionProvider.getOrderDetail(
        groupId: currentState.groupId,
        orderId: currentState.order.id,
      );
      emit(
        RedemptionDetailActionSuccess(
          order: order,
          groupId: currentState.groupId,
          action: RedemptionDetailAction.unsatisfied,
        ),
      );
    } on RedemptionApiException catch (e) {
      emit(
        RedemptionDetailActionFailure(
          order: currentState.order,
          groupId: currentState.groupId,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        RedemptionDetailActionFailure(
          order: currentState.order,
          groupId: currentState.groupId,
          message: e.toString(),
        ),
      );
    }
  }
}
