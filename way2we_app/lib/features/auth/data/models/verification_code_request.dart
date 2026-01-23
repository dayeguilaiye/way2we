import 'package:json_annotation/json_annotation.dart';

part 'verification_code_request.g.dart';

/// Request model for sending verification code.
@JsonSerializable()
class VerificationCodeRequest {
  const VerificationCodeRequest({
    required this.type,
    required this.target,
  });

  /// Creates a [VerificationCodeRequest] from JSON.
  factory VerificationCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$VerificationCodeRequestFromJson(json);

  /// Type of verification: 'phone' or 'email'.
  final String type;

  /// Target phone number or email address.
  final String target;

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => _$VerificationCodeRequestToJson(this);
}
