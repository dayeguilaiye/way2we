import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/view/group_selection_page.dart';
import 'package:way2we_app/features/profile/bloc/profile_bloc.dart';
import 'package:way2we_app/features/profile/data/providers/profile_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/avatar_picker.dart';
import 'package:way2we_app/theme/theme.dart';

/// Onboarding-specific profile setup page shown after registration.
///
/// This is NOT the general settings page used in the app.
/// It's designed to guide new users through initial profile setup
/// (nickname + avatar) before entering the main app.
class OnboardingProfileSetupPage extends StatefulWidget {
  const OnboardingProfileSetupPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) {
        // Use global Dio instance from ServiceLocator
        final dio = ServiceLocator.instance.dio;

        return RepositoryProvider(
          create: (_) => ProfileProvider(dio: dio),
          child: BlocProvider(
            create: (context) => ProfileBloc(
              profileProvider: context.read<ProfileProvider>(),
            ),
            child: const OnboardingProfileSetupPage(),
          ),
        );
      },
    );
  }

  @override
  State<OnboardingProfileSetupPage> createState() =>
      _OnboardingProfileSetupPageState();
}

class _OnboardingProfileSetupPageState
    extends State<OnboardingProfileSetupPage> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _selectedImage;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        nickname: _nicknameController.text.trim(),
        avatarFile: _selectedImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          Navigator.of(context).pushReplacement(GroupSelectionPage.route());
        } else if (state is ProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingH,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.space10),

                  // Welcome illustration / icon
                  _buildWelcomeHeader(theme, l10n),
                  const SizedBox(height: AppSpacing.space8),

                  // Avatar picker
                  _buildAvatarPicker(theme),
                  const SizedBox(height: AppSpacing.space6),

                  // Nickname input
                  _buildNicknameInput(theme, l10n),
                  const SizedBox(height: AppSpacing.space8),

                  // Submit button
                  _buildSubmitButton(theme, l10n),
                  const SizedBox(height: AppSpacing.space4),

                  // Skip button
                  _buildSkipButton(theme, l10n),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.4),
              ],
            ),
          ),
          child: const Icon(
            Icons.celebration_outlined,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          l10n.onboardingWelcomeTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: AppTypography.extraBold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          l10n.onboardingWelcomeSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textMutedLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAvatarPicker(ThemeData theme) {
    return AvatarPicker(
      imageFile: _selectedImage,
      onTap: _pickImage,
    );
  }

  Widget _buildNicknameInput(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space4,
            bottom: AppSpacing.space1 + 2,
          ),
          child: Text(
            l10n.authNicknameLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: AppTypography.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          height: AppSpacing.inputHeight,
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Center(
            child: TextFormField(
              controller: _nicknameController,
              style: theme.textTheme.bodyLarge,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.onboardingNicknameRequired;
                }
                if (value.length > 20) {
                  return l10n.onboardingNicknameTooLong;
                }
                return null;
              },
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: l10n.authNicknamePlaceholder,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPlaceholderLight,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.space2),
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppColors.textMutedLight,
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          (previous is ProfileLoading) != (current is ProfileLoading),
      builder: (context, state) {
        final isLoading = state is ProfileLoading;

        return Container(
          width: double.infinity,
          height: AppSpacing.inputHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: !isLoading
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
            onPressed: isLoading ? null : _onSubmit,
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
                      Text(l10n.onboardingContinueButton),
                      const SizedBox(width: AppSpacing.space2),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSkipButton(ThemeData theme, AppLocalizations l10n) {
    return TextButton(
      onPressed: () async {
        await Navigator.of(context)
            .pushReplacement(GroupSelectionPage.route());
      },
      child: Text(
        l10n.onboardingSkipButton,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textMutedLight,
        ),
      ),
    );
  }
}
