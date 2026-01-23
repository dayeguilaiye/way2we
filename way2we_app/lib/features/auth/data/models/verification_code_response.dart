import 'package:json_annotation/json_annotation.dart';

part 'verification_code_response.g.dart';

/// Response model for sending verification code.
@JsonSerializable()
class VerificationCodeResponse {
  const VerificationCodeResponse({
    required this.success,
    required this.message,
  });

  /// Creates a [VerificationCodeResponse] from JSON.
  factory VerificationCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$VerificationCodeResponseFromJson(json);

  /// Whether the verification code was sent successfully.
  final bool success;

  /// Message from the server.
  final String message;

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => _$VerificationCodeResponseToJson(this);
}
