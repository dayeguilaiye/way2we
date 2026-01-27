import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/reward/bloc/form/reward_form_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';

class EditRewardPage extends StatelessWidget {
  const EditRewardPage({
    required this.groupId,
    required this.reward,
    super.key,
  });

  final int groupId;
  final Reward reward;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RewardFormBloc(
        rewardProvider: context.read<RewardProvider>(),
        groupProvider: context.read<GroupProvider>(),
      )..add(InitializeForm(groupId: groupId, reward: reward)),
      child: EditRewardView(groupId: groupId, rewardId: reward.id),
    );
  }
}

class EditRewardView extends StatefulWidget {
  const EditRewardView({
    required this.groupId,
    required this.rewardId,
    super.key,
  });

  final int groupId;
  final int rewardId;

  @override
  State<EditRewardView> createState() => _EditRewardViewState();
}

class _EditRewardViewState extends State<EditRewardView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;
  final _picker = ImagePicker();
  bool _isInitialized = false;
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
    final theme = Theme.of(context);

    return BlocConsumer<RewardFormBloc, RewardFormState>(
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
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }

        if (state.status == RewardFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.rewardUpdateSuccess),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == RewardFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.rewardUpdateError),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (!_isInitialized && state.isEditMode) {
          _nameController = TextEditingController(text: state.name);
          _descriptionController = TextEditingController(text: state.description);
          _pointsController = TextEditingController(
            text: state.costPoints.toString(),
          );
          _isInitialized = true;
        }

        if (!_isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.rewardEditTitle),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.rewardNameLabel,
                    border: const OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.rewardDescriptionLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 200,
                  maxLines: 3,
                  onChanged: (value) {
                    context.read<RewardFormBloc>().add(
                      DescriptionChanged(value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsController,
                  decoration: InputDecoration(
                    labelText: l10n.rewardCostPointsLabel,
                    border: const OutlineInputBorder(),
                    suffixText: 'pts',
                  ),
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
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.rewardAutoFulfillLabel),
                  value: state.autoFulfill,
                  onChanged: (value) {
                    context.read<RewardFormBloc>().add(
                      AutoFulfillChanged(value),
                    );
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.rewardAutoCompleteLabel),
                  value: state.autoComplete,
                  onChanged: (value) {
                    context.read<RewardFormBloc>().add(
                      AutoCompleteChanged(value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(l10n.rewardCoverImageLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: state.coverImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                state.coverImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            )
                          : const Icon(Icons.image_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                state.isCoverUploading ? null : _pickCover,
                            icon: const Icon(Icons.upload),
                            label: Text(
                              state.isCoverUploading
                                  ? l10n.rewardCoverUploading
                                  : l10n.rewardCoverUploadAction,
                            ),
                          ),
                          if (state.coverImageUrl.isNotEmpty ||
                              state.coverUploadError != null)
                            TextButton(
                              onPressed: () {
                                context.read<RewardFormBloc>().add(
                                  const CoverImageCleared(),
                                );
                              },
                              child: Text(l10n.rewardCoverRemoveAction),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (state.coverUploadError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.coverUploadError ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.canSubmit
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            context.read<RewardFormBloc>().add(
                              SubmitReward(
                                groupId: widget.groupId,
                                rewardId: widget.rewardId,
                              ),
                            );
                          }
                        }
                      : null,
                  child: state.status == RewardFormStatus.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.rewardSaveButton),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
