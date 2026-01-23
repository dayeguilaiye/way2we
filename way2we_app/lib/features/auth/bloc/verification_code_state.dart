part of 'verification_code_bloc.dart';

/// Status of the verification code operation.
enum VerificationCodeStatus {
  /// Initial state, ready to send code.
  initial,

  /// Sending verification code in progress.
  sending,

  /// Verification code sent successfully, countdown active.
  sent,

  /// Failed to send verification code.
  failure,
}

/// State for verification code BLoC.
final class VerificationCodeState extends Equatable {
  const VerificationCodeState({
    this.status = VerificationCodeStatus.initial,
    this.countdown = 0,
    this.errorMessage,
  });

  /// Current status of the verification code operation.
  final VerificationCodeStatus status;

  /// Remaining seconds in the cooldown countdown.
  /// 0 means no countdown active.
  final int countdown;

  /// Error message if status is failure.
  final String? errorMessage;

  /// Whether the send button should be enabled.
  bool get canSend =>
      status == VerificationCodeStatus.initial ||
      (status == VerificationCodeStatus.sent && countdown == 0) ||
      status == VerificationCodeStatus.failure;

  /// Whether the countdown is active.
  bool get isCountdownActive => countdown > 0;

  VerificationCodeState copyWith({
    VerificationCodeStatus? status,
    int? countdown,
    String? errorMessage,
  }) {
    return VerificationCodeState(
      status: status ?? this.status,
      countdown: countdown ?? this.countdown,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, countdown, errorMessage];
}
