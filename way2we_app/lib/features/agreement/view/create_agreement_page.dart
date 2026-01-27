import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/bloc/form/agreement_form_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';

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
    final theme = Theme.of(context);

    return BlocListener<AgreementFormBloc, AgreementFormState>(
      listener: (context, state) {
        if (state.status == AgreementFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.agreementCreateSuccess),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == AgreementFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.agreementCreateError),
              backgroundColor: theme.colorScheme.error,
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
                padding: const EdgeInsets.all(16),
                children: [
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.agreementNameLabel,
                      hintText: l10n.agreementNamePlaceholder,
                      border: const OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.agreementDescriptionLabel,
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 200,
                    maxLines: 3,
                    onChanged: (value) {
                      context.read<AgreementFormBloc>().add(
                        DescriptionChanged(value),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Points field
                  TextFormField(
                    controller: _pointsController,
                    decoration: InputDecoration(
                      labelText: l10n.agreementPointsLabel,
                      border: const OutlineInputBorder(),
                      suffixText: 'pts',
                    ),
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
                  const SizedBox(height: 16),

                  // Require confirmation switch
                  SwitchListTile(
                    title: Text(l10n.agreementRequireConfirmationLabel),
                    subtitle: Text(l10n.agreementRequireConfirmationHint),
                    value: state.requireConfirmation,
                    onChanged: (value) {
                      context.read<AgreementFormBloc>().add(
                        RequireConfirmationChanged(value),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  FilledButton(
                    onPressed: state.canSubmit
                        ? () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AgreementFormBloc>().add(
                                SubmitAgreement(groupId: widget.groupId),
                              );
                            }
                          }
                        : null,
                    child: state.status == AgreementFormStatus.submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.agreementSaveButton),
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
