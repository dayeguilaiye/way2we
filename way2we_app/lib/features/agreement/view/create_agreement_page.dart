import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/bloc/form/agreement_form_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class CreateAgreementPage extends StatelessWidget {
  const CreateAgreementPage({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AgreementFormBloc(
        agreementProvider: context.read<AgreementProvider>(),
        groupProvider: context.read<GroupProvider>(),
      )..add(InitializeForm(groupId: groupId)),
      child: CreateAgreementView(groupId: groupId),
    );
  }
}

class CreateAgreementView extends StatefulWidget {
  const CreateAgreementView({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  State<CreateAgreementView> createState() => _CreateAgreementViewState();
}

class _CreateAgreementViewState extends State<CreateAgreementView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');

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

    return BlocListener<AgreementFormBloc, AgreementFormState>(
      listener: (context, state) {
        if (state.status == AgreementFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.agreementCreateSuccess),
              backgroundColor: colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == AgreementFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.agreementCreateError),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.agreementCreateButton),
        ),
        body: BlocBuilder<AgreementFormBloc, AgreementFormState>(
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
                children: [
                  W2WInput(
                    controller: _nameController,
                    label: l10n.agreementNameLabel,
                    hintText: l10n.agreementNamePlaceholder,
                    prefixIcon: Icons.rule_folder_outlined,
                    maxLength: 50,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.agreementRequireConfirmationLabel,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: AppTypography.bold,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.space1),
                              Text(
                                l10n.agreementRequireConfirmationHint,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMutedLight,
                                    ),
                              ),
                            ],
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
                                SubmitAgreement(groupId: widget.groupId),
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
