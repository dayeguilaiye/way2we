part of 'verification_code_bloc.dart';

/// Events for verification code BLoC.
sealed class VerificationCodeEvent extends Equatable {
  const VerificationCodeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to send verification code.
final class SendVerificationCode extends VerificationCodeEvent {
  const SendVerificationCode({
    required this.type,
    required this.target,
  });

  /// Type of verification: 'phone' or 'email'.
  final String type;

  /// Target phone number or email address.
  final String target;

  @override
  List<Object?> get props => [type, target];
}

/// Event triggered when countdown tick occurs.
final class CountdownTick extends VerificationCodeEvent {
  const CountdownTick();
}

/// Event to reset the countdown and allow resending.
final class ResetCooldown extends VerificationCodeEvent {
  const ResetCooldown();
}
