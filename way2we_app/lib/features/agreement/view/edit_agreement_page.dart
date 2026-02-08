import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/bloc/form/agreement_form_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class EditAgreementPage extends StatelessWidget {
  const EditAgreementPage({
    required this.groupId,
    required this.agreement,
    super.key,
  });

  final int groupId;
  final Agreement agreement;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AgreementFormBloc(
        agreementProvider: context.read<AgreementProvider>(),
        groupProvider: context.read<GroupProvider>(),
      )..add(InitializeForm(groupId: groupId, agreement: agreement)),
      child: EditAgreementView(groupId: groupId, agreementId: agreement.id),
    );
  }
}

class EditAgreementView extends StatefulWidget {
  const EditAgreementView({
    required this.groupId,
    required this.agreementId,
    super.key,
  });

  final int groupId;
  final int agreementId;

  @override
  State<EditAgreementView> createState() => _EditAgreementViewState();
}

class _EditAgreementViewState extends State<EditAgreementView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AgreementFormBloc, AgreementFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AgreementFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.agreementUpdateSuccess),
              backgroundColor: colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == AgreementFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.agreementUpdateError),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (!_isInitialized && state.isEditMode) {
          _nameController = TextEditingController(text: state.name);
          _descriptionController = TextEditingController(
            text: state.description,
          );
          _pointsController = TextEditingController(
            text: state.points.toString(),
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
            title: Text(l10n.agreementEditTitle),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
              children: [
                W2WInput(
                  controller: _nameController,
                  label: l10n.agreementNameLabel,
                  maxLength: 50,
                  prefixIcon: Icons.rule_folder_outlined,
                  onChanged: (value) {
                    context.read<AgreementFormBloc>().add(NameChanged(value));
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.agreementNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space4),
                W2WInput(
                  controller: _descriptionController,
                  label: l10n.agreementDescriptionLabel,
                  maxLength: 200,
                  maxLines: 3,
                  onChanged: (value) {
                    context.read<AgreementFormBloc>().add(
                      DescriptionChanged(value),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space4),
                W2WInput(
                  controller: _pointsController,
                  label: l10n.agreementPointsLabel,
                  suffixText: l10n.commonPointsUnit,
                  prefixIcon: Icons.stars_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final points = int.tryParse(value) ?? 0;
                    context.read<AgreementFormBloc>().add(
                      PointsChanged(points),
                    );
                  },
                  validator: (value) {
                    final points = int.tryParse(value ?? '') ?? 0;
                    if (points < 1 || points > 99999) {
                      return l10n.agreementPointsInvalid;
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
                          l10n.agreementRequireConfirmationLabel,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Switch(
                        value: state.requireConfirmation,
                        onChanged: (value) {
                          context.read<AgreementFormBloc>().add(
                            RequireConfirmationChanged(
                              requireConfirmation: value,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                W2WButton(
                  label: l10n.agreementSaveButton,
                  icon: Icons.check_circle_outline,
                  isLoading: state.status == AgreementFormStatus.submitting,
                  onPressed: state.canSubmit
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AgreementFormBloc>().add(
                              SubmitAgreement(
                                groupId: widget.groupId,
                                agreementId: widget.agreementId,
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
