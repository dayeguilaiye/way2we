import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/create_group_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/home/view/home_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
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
          // Navigate to home page
          Navigator.of(context).pushAndRemoveUntil(
            HomePage.route(),
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
                  _buildNameInput(theme, l10n),
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
                  _buildSubmitButton(theme, l10n),
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

  Widget _buildNameInput(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space4,
            bottom: AppSpacing.space1 + 2,
          ),
          child: Text(
            l10n.createGroupNameLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: AppTypography.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        BlocBuilder<CreateGroupBloc, CreateGroupState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.name != current.name,
          builder: (context, state) {
            final hasError =
                state.name.isNotEmpty && state.name.length > 30;

            return Container(
              height: AppSpacing.inputHeight,
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: AppShadows.card,
                border: Border.all(
                  color: hasError ? AppColors.error : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
              ),
              child: Center(
                child: TextField(
                  controller: _nameController,
                  style: theme.textTheme.bodyLarge,
                  onChanged: (value) {
                    context
                        .read<CreateGroupBloc>()
                        .add(CreateGroupNameChanged(value));
                  },
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: l10n.createGroupNamePlaceholder,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPlaceholderLight,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.space2),
                      child: Icon(
                        Icons.group,
                        color: AppColors.textMutedLight,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n) {
    return BlocBuilder<CreateGroupBloc, CreateGroupState>(
      buildWhen: (previous, current) =>
          previous.canSubmit != current.canSubmit ||
          previous.status != current.status,
      builder: (context, state) {
        final isSubmitting = state.status == CreateGroupStatus.submitting;

        return Container(
          width: double.infinity,
          height: AppSpacing.inputHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: state.canSubmit && !isSubmitting
                ? const [
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: FilledButton(
            onPressed: state.canSubmit && !isSubmitting
                ? () {
                    context
                        .read<CreateGroupBloc>()
                        .add(const CreateGroupSubmitted());
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.inputHeight),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.createGroupSubmitButton),
                      const SizedBox(width: AppSpacing.space2),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
