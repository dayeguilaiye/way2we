part of 'reward_form_bloc.dart';

enum RewardFormStatus { initial, submitting, success, failure }

class RewardFormState extends Equatable {
  const RewardFormState({
    this.name = '',
    this.description = '',
    this.costPoints = 10,
    this.autoFulfill = false,
    this.autoComplete = false,
    this.coverImageUrl = '',
    this.isEditMode = false,
    this.status = RewardFormStatus.initial,
    this.errorMessage,
    this.errorCode,
    this.isCoverUploading = false,
    this.coverUploadError,
  });

  final String name;
  final String description;
  final int costPoints;
  final bool autoFulfill;
  final bool autoComplete;
  final String coverImageUrl;
  final bool isEditMode;
  final RewardFormStatus status;
  final String? errorMessage;
  final String? errorCode;
  final bool isCoverUploading;
  final String? coverUploadError;

  bool get canSubmit {
    final nameValid = name.trim().isNotEmpty;
    final pointsValid = costPoints >= 1 && costPoints <= 99999;
    return nameValid &&
        pointsValid &&
        status != RewardFormStatus.submitting &&
        !isCoverUploading &&
        coverUploadError == null;
  }

  RewardFormState copyWith({
    String? name,
    String? description,
    int? costPoints,
    bool? autoFulfill,
    bool? autoComplete,
    String? coverImageUrl,
    bool? isEditMode,
    RewardFormStatus? status,
    String? errorMessage,
    String? errorCode,
    bool? isCoverUploading,
    String? coverUploadError,
  }) {
    return RewardFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      costPoints: costPoints ?? this.costPoints,
      autoFulfill: autoFulfill ?? this.autoFulfill,
      autoComplete: autoComplete ?? this.autoComplete,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isEditMode: isEditMode ?? this.isEditMode,
      status: status ?? this.status,
      errorMessage: errorMessage,
      errorCode: errorCode,
      isCoverUploading: isCoverUploading ?? this.isCoverUploading,
      coverUploadError: coverUploadError,
    );
  }

  @override
  List<Object?> get props => [
    name,
    description,
    costPoints,
    autoFulfill,
    autoComplete,
    coverImageUrl,
    isEditMode,
    status,
    errorMessage,
    errorCode,
    isCoverUploading,
    coverUploadError,
  ];
}
