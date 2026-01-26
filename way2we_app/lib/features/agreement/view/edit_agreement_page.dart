import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/agreement/bloc/form/agreement_form_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';

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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => AgreementProvider(dio: ServiceLocator.instance.dio),
        ),
        RepositoryProvider(
          create: (_) => GroupProvider(dio: ServiceLocator.instance.dio),
        ),
      ],
      child: BlocProvider(
        create: (context) => AgreementFormBloc(
          agreementProvider: context.read<AgreementProvider>(),
          groupProvider: context.read<GroupProvider>(),
        )..add(InitializeForm(groupId: groupId, agreement: agreement)),
        child: EditAgreementView(groupId: groupId, agreementId: agreement.id),
      ),
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
    final theme = Theme.of(context);

    return BlocConsumer<AgreementFormBloc, AgreementFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AgreementFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.agreementUpdateSuccess),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == AgreementFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.agreementUpdateError),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // Initialize controllers once when state is loaded
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
              padding: const EdgeInsets.all(16),
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.agreementNameLabel,
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
                              SubmitAgreement(
                                groupId: widget.groupId,
                                agreementId: widget.agreementId,
                              ),
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
          ),
        );
      },
    );
  }
}
