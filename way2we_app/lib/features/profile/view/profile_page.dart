import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/profile/bloc/profile_bloc.dart';
import 'package:way2we_app/features/profile/data/providers/profile_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/avatar_picker.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
            child: const ProfilePage(),
          ),
        );
      },
    );
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileLoadRequested());
  }

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

  void _onSave() {
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profilePageTitle)),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.profileUpdateSuccess),
                backgroundColor: theme.semantic.success,
              ),
            );
          } else if (state is ProfileLoadSuccess) {
            if (_nicknameController.text.isEmpty && state.nickname.isNotEmpty) {
              _nicknameController.text = state.nickname;
            }
          } else if (state is ProfileFailure) {
            final message =
                _mapErrorCodeToMessage(state.errorCode, l10n) ??
                state.errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: theme.semantic.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && state.nickname.isEmpty) {
            return const _ProfileLoadingState();
          }

          final isLoading = state is ProfileLoading;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.space2),
                    Semantics(
                      button: true,
                      label: l10n.profilePageTitle,
                      child: Center(
                        child: AvatarPicker(
                          imageFile: _selectedImage,
                          imageUrl: state.avatarUrl,
                          onTap: _pickImage,
                          semanticLabel: l10n.profilePageTitle,
                        ),
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
                    W2WButton(
                      label: l10n.profileSaveButton,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onSave,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    W2WButton(
                      label: l10n.profileLogoutButton,
                      icon: Icons.logout,
                      variant: W2WButtonVariant.destructive,
                      onPressed: () => _showLogoutConfirmation(context, l10n),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _mapErrorCodeToMessage(String? code, AppLocalizations l10n) {
    if (code == null) return null;
    switch (code) {
      case 'ERR_NICKNAME_TOO_LONG':
        return l10n.onboardingNicknameTooLong;
      case 'ERR_UNAUTHORIZED':
        return l10n.profileUpdateError;
      case 'ERR_INVALID_FILE':
        return l10n.profileUpdateError;
      default:
        return null;
    }
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final authBloc = context.read<AuthenticationBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileLogoutConfirmTitle),
        content: Text(l10n.profileLogoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).semantic.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      authBloc.add(const AppLogoutRequested());
    }
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingH),
      children: const [
        SizedBox(height: AppSpacing.space8),
        Center(
          child: W2WSkeleton(
            width: 120,
            height: 120,
            radius: AppSpacing.radiusFull,
          ),
        ),
        SizedBox(height: AppSpacing.space6),
        W2WSkeleton(width: 120, height: 12),
        SizedBox(height: AppSpacing.space2),
        W2WSkeleton(height: AppSpacing.inputHeight),
        SizedBox(height: AppSpacing.space6),
        W2WSkeleton(height: AppSpacing.inputHeight),
      ],
    );
  }
}
