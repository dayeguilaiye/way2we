import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';

part 'verification_code_event.dart';
part 'verification_code_state.dart';

/// BLoC for handling verification code sending with countdown.
class VerificationCodeBloc
    extends Bloc<VerificationCodeEvent, VerificationCodeState> {
  VerificationCodeBloc({
    required AuthProvider authProvider,
    this.cooldownDuration = 60,
  }) : _authProvider = authProvider,
       super(const VerificationCodeState()) {
    on<SendVerificationCode>(_onSendVerificationCode);
    on<CountdownTick>(_onCountdownTick);
    on<ResetCooldown>(_onResetCooldown);
  }

  final AuthProvider _authProvider;

  /// Duration of the cooldown countdown in seconds.
  final int cooldownDuration;

  Timer? _countdownTimer;

  Future<void> _onSendVerificationCode(
    SendVerificationCode event,
    Emitter<VerificationCodeState> emit,
  ) async {
    // Prevent sending if countdown is active
    if (state.isCountdownActive) return;

    emit(state.copyWith(status: VerificationCodeStatus.sending));

    try {
      await _authProvider.sendVerificationCode(
        type: event.type,
        target: event.target,
      );

      // Start countdown
      emit(
        state.copyWith(
          status: VerificationCodeStatus.sent,
          countdown: cooldownDuration,
        ),
      );

      _startCountdown();
    } on AuthApiException catch (e) {
      emit(
        state.copyWith(
          status: VerificationCodeStatus.failure,
          errorMessage: e.message,
        ),
      );
    } on Exception {
      emit(
        state.copyWith(
          status: VerificationCodeStatus.failure,
          errorMessage: '发送验证码失败，请稍后重试',
        ),
      );
    }
  }

  void _onCountdownTick(
    CountdownTick event,
    Emitter<VerificationCodeState> emit,
  ) {
    if (state.countdown > 0) {
      emit(state.copyWith(countdown: state.countdown - 1));
    } else {
      _countdownTimer?.cancel();
    }
  }

  void _onResetCooldown(
    ResetCooldown event,
    Emitter<VerificationCodeState> emit,
  ) {
    _countdownTimer?.cancel();
    emit(
      state.copyWith(
        status: VerificationCodeStatus.initial,
        countdown: 0,
      ),
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const CountdownTick());
    });
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
