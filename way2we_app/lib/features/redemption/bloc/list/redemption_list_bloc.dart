import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';

part 'redemption_list_event.dart';
part 'redemption_list_state.dart';

class RedemptionListBloc
    extends Bloc<RedemptionListEvent, RedemptionListState> {
  RedemptionListBloc({required RedemptionProvider redemptionProvider})
    : _redemptionProvider = redemptionProvider,
      super(const RedemptionListInitial()) {
    on<LoadOrders>(_onLoad);
    on<RefreshOrders>(_onRefresh);
  }

  final RedemptionProvider _redemptionProvider;

  int? _groupId;
  String? _status;
  String? _role;
  int? _limit;
  int? _offset;

  Future<void> _onLoad(
    LoadOrders event,
    Emitter<RedemptionListState> emit,
  ) async {
    _groupId = event.groupId;
    _status = event.status;
    _role = event.role;
    _limit = event.limit;
    _offset = event.offset;

    emit(const RedemptionListLoading());

    try {
      final orders = await _redemptionProvider.listOrders(
        groupId: event.groupId,
        status: event.status,
        role: event.role,
        limit: event.limit,
        offset: event.offset,
      );
      emit(
        RedemptionListLoaded(
          orders: orders,
          groupId: event.groupId,
          status: event.status,
          role: event.role,
        ),
      );
    } on RedemptionApiException catch (e) {
      emit(RedemptionListError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(RedemptionListError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshOrders event,
    Emitter<RedemptionListState> emit,
  ) async {
    if (_groupId == null) return;

    try {
      final orders = await _redemptionProvider.listOrders(
        groupId: _groupId!,
        status: _status,
        role: _role,
        limit: _limit,
        offset: _offset,
      );
      emit(
        RedemptionListLoaded(
          orders: orders,
          groupId: _groupId!,
          status: _status,
          role: _role,
        ),
      );
    } on RedemptionApiException catch (e) {
      emit(RedemptionListError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(RedemptionListError(message: e.toString()));
    }
  }
}
