import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/create_group_bloc.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/home/view/main_shell_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

/// Page for creating a new group.
///
/// Based on UX Design Specification:
/// - Pill-shaped inputs consistent with auth pages
/// - Clear validation feedback
/// - Smooth navigation on success
class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const CreateGroupPage());
  }

  @override
  Widget build(BuildContext context) {
    final dio = ServiceLocator.instance.dio;

    return RepositoryProvider(
      create: (_) => GroupProvider(dio: dio),
      child: BlocProvider(
        create: (context) => CreateGroupBloc(
          groupProvider: context.read<GroupProvider>(),
        ),
        child: const CreateGroupView(),
      ),
    );
  }
}

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocListener<CreateGroupBloc, CreateGroupState>(
      listener: (context, state) {
        if (state.status == CreateGroupStatus.success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.createGroupSuccess),
              backgroundColor: AppColors.success,
            ),
          );
          context.read<GroupControlBloc>().add(
            const GroupControlGroupsLoaded(),
          );
          // Navigate to home page (UX improvement: landing first)
          Navigator.of(context).pushAndRemoveUntil(
            MainShellPage.route(),
            (route) => false,
          );
        } else if (state.status == CreateGroupStatus.failure) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.createGroupError),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.createGroupTitle),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.space6),

                  // Hero illustration
                  _buildHeroIllustration(),
                  const SizedBox(height: AppSpacing.space6),

                  // Title
                  Text(
                    l10n.createGroupHeadline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),

                  // Subtitle
                  Text(
                    l10n.createGroupSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),

                  // Group name input
                  _buildNameInput(l10n),
                  const SizedBox(height: AppSpacing.space6),

                  // Character count
                  BlocBuilder<CreateGroupBloc, CreateGroupState>(
                    builder: (context, state) {
                      final count = state.name.length;
                      final isOverLimit = count > 30;
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.space4,
                        ),
                        child: Text(
                          '$count/30',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverLimit
                                ? AppColors.error
                                : AppColors.textMutedLight,
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Submit button
                  _buildSubmitButton(l10n),
                  const SizedBox(height: AppSpacing.space6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIllustration() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: const Icon(
          Icons.group_add,
          size: 56,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildNameInput(AppLocalizations l10n) {
    return BlocBuilder<CreateGroupBloc, CreateGroupState>(
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.name != current.name,
      builder: (context, state) {
        return W2WInput(
          controller: _nameController,
          label: l10n.createGroupNameLabel,
          hintText: l10n.createGroupNamePlaceholder,
          prefixIcon: Icons.group,
          onChanged: (value) {
            context.read<CreateGroupBloc>().add(
              CreateGroupNameChanged(value),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return BlocBuilder<CreateGroupBloc, CreateGroupState>(
      buildWhen: (previous, current) =>
          previous.canSubmit != current.canSubmit ||
          previous.status != current.status,
      builder: (context, state) {
        final isSubmitting = state.status == CreateGroupStatus.submitting;

        return W2WButton(
          label: l10n.createGroupSubmitButton,
          icon: Icons.arrow_forward,
          isLoading: isSubmitting,
          onPressed: state.canSubmit && !isSubmitting
              ? () {
                  context.read<CreateGroupBloc>().add(
                    const CreateGroupSubmitted(),
                  );
                }
              : null,
        );
      },
    );
  }
}
