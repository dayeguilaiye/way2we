// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_code_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationCodeRequest _$VerificationCodeRequestFromJson(
  Map<String, dynamic> json,
) => VerificationCodeRequest(
  type: json['type'] as String,
  target: json['target'] as String,
);

Map<String, dynamic> _$VerificationCodeRequestToJson(
  VerificationCodeRequest instance,
) => <String, dynamic>{'type': instance.type, 'target': instance.target};
