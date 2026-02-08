import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/reward/bloc/form/reward_form_bloc.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class CreateRewardPage extends StatelessWidget {
  const CreateRewardPage({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RewardFormBloc(
        rewardProvider: context.read<RewardProvider>(),
        groupProvider: context.read<GroupProvider>(),
      )..add(InitializeForm(groupId: groupId)),
      child: CreateRewardView(groupId: groupId),
    );
  }
}

class CreateRewardView extends StatefulWidget {
  const CreateRewardView({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  State<CreateRewardView> createState() => _CreateRewardViewState();
}

class _CreateRewardViewState extends State<CreateRewardView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  final _picker = ImagePicker();
  String? _lastCoverError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    context.read<RewardFormBloc>().add(CoverImageSelected(file));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<RewardFormBloc, RewardFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.coverUploadError != current.coverUploadError,
      listener: (context, state) {
        if (state.coverUploadError != null &&
            state.coverUploadError != _lastCoverError) {
          _lastCoverError = state.coverUploadError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.coverUploadError ?? l10n.rewardCoverUploadError,
              ),
              backgroundColor: colorScheme.error,
            ),
          );
        }

        if (state.status == RewardFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.rewardCreateSuccess),
              backgroundColor: colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == RewardFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.rewardCreateError),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.rewardCreateButton),
        ),
        body: BlocBuilder<RewardFormBloc, RewardFormState>(
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
                children: [
                  W2WInput(
                    controller: _nameController,
                    label: l10n.rewardNameLabel,
                    hintText: l10n.rewardNamePlaceholder,
                    prefixIcon: Icons.card_giftcard_outlined,
                    maxLength: 50,
                    onChanged: (value) {
                      context.read<RewardFormBloc>().add(NameChanged(value));
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.rewardNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  W2WInput(
                    controller: _descriptionController,
                    label: l10n.rewardDescriptionLabel,
                    maxLength: 200,
                    maxLines: 3,
                    onChanged: (value) {
                      context.read<RewardFormBloc>().add(
                        DescriptionChanged(value),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  W2WInput(
                    controller: _pointsController,
                    label: l10n.rewardCostPointsLabel,
                    suffixText: l10n.commonPointsUnit,
                    prefixIcon: Icons.stars_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final points = int.tryParse(value) ?? 0;
                      context.read<RewardFormBloc>().add(
                        CostPointsChanged(points),
                      );
                    },
                    validator: (value) {
                      final points = int.tryParse(value ?? '') ?? 0;
                      if (points < 1 || points > 99999) {
                        return l10n.rewardCostPointsInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  W2WCard(
                    showBorder: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.rewardAutoFulfillLabel,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Switch(
                          value: state.autoFulfill,
                          onChanged: (value) {
                            context.read<RewardFormBloc>().add(
                              AutoFulfillChanged(autoFulfill: value),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  W2WCard(
                    showBorder: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.rewardAutoCompleteLabel,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Switch(
                          value: state.autoComplete,
                          onChanged: (value) {
                            context.read<RewardFormBloc>().add(
                              AutoCompleteChanged(autoComplete: value),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  W2WSectionHeader(title: l10n.rewardCoverImageLabel),
                  const SizedBox(height: AppSpacing.space3),
                  W2WCard(
                    showBorder: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RewardCoverPreview(coverImageUrl: state.coverImageUrl),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              W2WButton(
                                label: state.isCoverUploading
                                    ? l10n.rewardCoverUploading
                                    : l10n.rewardCoverUploadAction,
                                icon: Icons.upload_outlined,
                                variant: W2WButtonVariant.ghost,
                                expanded: false,
                                isLoading: state.isCoverUploading,
                                onPressed: state.isCoverUploading
                                    ? null
                                    : _pickCover,
                              ),
                              if (state.coverImageUrl.isNotEmpty ||
                                  state.coverUploadError != null) ...[
                                const SizedBox(height: AppSpacing.space2),
                                W2WButton(
                                  label: l10n.rewardCoverRemoveAction,
                                  variant: W2WButtonVariant.secondary,
                                  expanded: false,
                                  onPressed: () {
                                    context.read<RewardFormBloc>().add(
                                      const CoverImageCleared(),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.coverUploadError != null) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      state.coverUploadError ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space8),
                  W2WButton(
                    label: l10n.rewardSaveButton,
                    icon: Icons.check_circle_outline,
                    isLoading: state.status == RewardFormStatus.submitting,
                    onPressed: state.canSubmit
                        ? () {
                            if (_formKey.currentState!.validate()) {
                              context.read<RewardFormBloc>().add(
                                SubmitReward(groupId: widget.groupId),
                              );
                            }
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RewardCoverPreview extends StatelessWidget {
  const _RewardCoverPreview({required this.coverImageUrl});

  final String coverImageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: coverImageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Image.network(
                coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                ),
              ),
            )
          : const Icon(Icons.image_outlined),
    );
  }
}
