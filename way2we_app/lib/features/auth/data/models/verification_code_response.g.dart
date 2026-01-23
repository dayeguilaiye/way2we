// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_code_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationCodeResponse _$VerificationCodeResponseFromJson(
  Map<String, dynamic> json,
) => VerificationCodeResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
);

Map<String, dynamic> _$VerificationCodeResponseToJson(
  VerificationCodeResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
};
