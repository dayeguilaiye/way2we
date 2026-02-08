import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/view/group_selection_page.dart';
import 'package:way2we_app/features/profile/bloc/profile_bloc.dart';
import 'package:way2we_app/features/profile/data/providers/profile_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/avatar_picker.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class OnboardingProfileSetupPage extends StatefulWidget {
  const OnboardingProfileSetupPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) {
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
    if (!mounted || image == null) return;
    setState(() => _selectedImage = image);
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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          Navigator.of(context).pushReplacement(GroupSelectionPage.route());
        } else if (state is ProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: theme.semantic.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePaddingH,
              AppSpacing.space8,
              AppSpacing.pagePaddingH,
              AppSpacing.pagePaddingV,
            ),
            children: [
              _OnboardingHeader(l10n: l10n),
              const SizedBox(height: AppSpacing.space8),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: AvatarPicker(
                        imageFile: _selectedImage,
                        onTap: _pickImage,
                        semanticLabel: l10n.onboardingWelcomeTitle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    W2WInput(
                      controller: _nicknameController,
                      label: l10n.authNicknameLabel,
                      hintText: l10n.authNicknamePlaceholder,
                      prefixIcon: Icons.edit_outlined,
                      maxLength: 20,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.onboardingNicknameRequired;
                        }
                        if (value.length > 20) {
                          return l10n.onboardingNicknameTooLong;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    BlocBuilder<ProfileBloc, ProfileState>(
                      buildWhen: (previous, current) =>
                          (previous is ProfileLoading) !=
                          (current is ProfileLoading),
                      builder: (context, state) {
                        final isLoading = state is ProfileLoading;
                        return W2WButton(
                          label: l10n.onboardingContinueButton,
                          icon: Icons.arrow_forward,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _onSubmit,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    W2WButton(
                      label: l10n.onboardingSkipButton,
                      variant: W2WButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushReplacement(GroupSelectionPage.route());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
}
