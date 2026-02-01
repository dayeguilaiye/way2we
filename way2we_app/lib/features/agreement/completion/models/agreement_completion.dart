import 'package:equatable/equatable.dart';

enum AgreementCompletionStatus {
  pending,
  confirmed,
  rejected;

  static AgreementCompletionStatus fromString(String value) {
    return AgreementCompletionStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AgreementCompletionStatus.pending,
    );
  }
}

class AgreementCompletion extends Equatable {
  const AgreementCompletion({
    required this.id,
    required this.groupId,
    required this.agreementId,
    required this.completerId,
    required this.recorderId,
    required this.points,
    required this.requireConfirmation,
    required this.status,
    required this.createdAt,
    this.agreementName,
    this.completerNickname,
    this.recorderNickname,
    this.rejectedReason,
    this.confirmedBy,
    this.confirmedAt,
    this.rejectedAt,
  });

  factory AgreementCompletion.fromJson(Map<String, dynamic> json) {
    return AgreementCompletion(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      agreementId: json['agreement_id'] as int,
      agreementName: json['agreement_name'] as String?,
      completerId: json['completer_id'] as int,
      completerNickname: json['completer_nickname'] as String?,
      recorderId: json['recorder_id'] as int,
      recorderNickname: json['recorder_nickname'] as String?,
      points: json['points'] as int,
      requireConfirmation: json['require_confirmation'] as bool,
      status: AgreementCompletionStatus.fromString(
        json['status'] as String,
      ),
      rejectedReason: json['rejected_reason'] as String?,
      confirmedBy: json['confirmed_by'] as int?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int groupId;
  final int agreementId;
  final String? agreementName;
  final int completerId;
  final String? completerNickname;
  final int recorderId;
  final String? recorderNickname;
  final int points;
  final bool requireConfirmation;
  final AgreementCompletionStatus status;
  final String? rejectedReason;
  final int? confirmedBy;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    groupId,
    agreementId,
    agreementName,
    completerId,
    completerNickname,
    recorderId,
    recorderNickname,
    points,
    requireConfirmation,
    status,
    rejectedReason,
    confirmedBy,
    confirmedAt,
    rejectedAt,
    createdAt,
  ];
}
