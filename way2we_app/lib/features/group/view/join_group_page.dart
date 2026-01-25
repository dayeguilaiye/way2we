import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/bloc/join_group_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/home/view/home_page.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

/// Page for joining a group via invitation code.
///
/// Features:
/// - 6-digit code input
/// - Group preview before joining
/// - Confirmation to join
/// - Error handling for invalid codes
class JoinGroupPage extends StatelessWidget {
  const JoinGroupPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const JoinGroupPage());
  }

  @override
  Widget build(BuildContext context) {
    final dio = ServiceLocator.instance.dio;

    return RepositoryProvider(
      create: (_) => GroupProvider(dio: dio),
      child: BlocProvider(
        create: (context) => JoinGroupBloc(
          groupProvider: context.read<GroupProvider>(),
        ),
        child: const JoinGroupView(),
      ),
    );
  }
}

class JoinGroupView extends StatefulWidget {
  const JoinGroupView({super.key});

  @override
  State<JoinGroupView> createState() => _JoinGroupViewState();
}

class _JoinGroupViewState extends State<JoinGroupView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocListener<JoinGroupBloc, JoinGroupState>(
      listener: (context, state) {
        if (state.status == JoinGroupStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.joinGroupSuccess(state.groupName ?? '')),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            HomePage.route(),
            (route) => false,
          );
        } else if (state.status == JoinGroupStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _mapErrorToMessage(state.errorCode, state.errorMessage, l10n),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.joinGroupTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space6),

                // Hero illustration
                _buildHeroIllustration(),
                const SizedBox(height: AppSpacing.space6),

                // Title
                Text(
                  l10n.joinGroupHeadline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),

                // Subtitle
                Text(
                  l10n.joinGroupSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),

                // Code input
                _buildCodeInput(theme, l10n),
                const SizedBox(height: AppSpacing.space6),

                // Group preview
                _buildGroupPreview(context, theme, l10n),

                const Spacer(),

                // Action button
                _buildActionButton(context, theme, l10n),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _mapErrorToMessage(
    String? errorCode,
    String? errorMessage,
    AppLocalizations l10n,
  ) {
    switch (errorCode) {
      case 'ERR_INVITATION_CODE_INVALID':
        return l10n.joinGroupErrorInvalidCode;
      case 'ERR_ALREADY_MEMBER':
        return l10n.joinGroupErrorAlreadyMember;
      default:
        return errorMessage ?? l10n.joinGroupError;
    }
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

  Widget _buildCodeInput(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space4,
            bottom: AppSpacing.space1 + 2,
          ),
          child: Text(
            l10n.joinGroupCodeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: AppTypography.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        BlocBuilder<JoinGroupBloc, JoinGroupState>(
          builder: (context, state) {
            return Container(
              height: AppSpacing.inputHeight,
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: AppShadows.card,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
              ),
              child: Center(
                child: TextField(
                  controller: _codeController,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    letterSpacing: 4,
                    fontWeight: AppTypography.bold,
                  ),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(6),
                    UpperCaseTextFormatter(),
                  ],
                  onChanged: (value) {
                    context
                        .read<JoinGroupBloc>()
                        .add(JoinGroupCodeChanged(value));
                  },
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: l10n.joinGroupCodePlaceholder,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPlaceholderLight,
                      letterSpacing: 4,
                    ),
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

  Widget _buildGroupPreview(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<JoinGroupBloc, JoinGroupState>(
      builder: (context, state) {
        if (state.status == JoinGroupStatus.loadingPreview) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              boxShadow: AppShadows.card,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!state.hasPreview) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: AppShadows.card,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.groupName ?? '',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.joinGroupMemberCount(state.memberCount ?? 0),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<JoinGroupBloc, JoinGroupState>(
      builder: (context, state) {
        final isLoading = state.isLoading;

        // Show different button based on state
        if (state.hasPreview) {
          // Join button
          return Container(
            width: double.infinity,
            height: AppSpacing.inputHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: state.canJoin
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
              onPressed: state.canJoin
                  ? () {
                      context
                          .read<JoinGroupBloc>()
                          .add(const JoinGroupConfirmed());
                    }
                  : null,
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, AppSpacing.inputHeight),
              ),
              child: isLoading
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
                        Text(l10n.joinGroupConfirmButton),
                        const SizedBox(width: AppSpacing.space2),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          );
        }

        // Preview button
        return Container(
          width: double.infinity,
          height: AppSpacing.inputHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: state.canPreview
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
            onPressed: state.canPreview
                ? () {
                    context
                        .read<JoinGroupBloc>()
                        .add(const JoinGroupPreviewRequested());
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.inputHeight),
            ),
            child: isLoading
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
                      Text(l10n.joinGroupPreviewButton),
                      const SizedBox(width: AppSpacing.space2),
                      const Icon(Icons.search, size: 20),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Text input formatter that converts input to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
