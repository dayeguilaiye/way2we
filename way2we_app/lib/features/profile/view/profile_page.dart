import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/profile/bloc/profile_bloc.dart';
import 'package:way2we_app/features/profile/data/providers/profile_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/avatar_picker.dart';
import 'package:way2we_app/theme/theme.dart';

/// Profile settings page for viewing and editing user profile.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
    // Load profile on init
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
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
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
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profilePageTitle),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // Only show success toast for user-triggered updates
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.profileUpdateSuccess),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ProfileLoadSuccess) {
            // Update text controller on initial load, no toast
            if (_nicknameController.text.isEmpty && state.nickname.isNotEmpty) {
              _nicknameController.text = state.nickname;
            }
          } else if (state is ProfileFailure) {
            // Map error codes to localized messages
            final message =
                _mapErrorCodeToMessage(state.errorCode, l10n) ??
                state.errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && state.nickname.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingH,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.space8),

                  // Avatar picker
                  Center(
                    child: AvatarPicker(
                      imageFile: _selectedImage,
                      imageUrl: state.avatarUrl,
                      onTap: _pickImage,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Nickname input
                  _buildNicknameInput(theme, l10n),
                  const SizedBox(height: AppSpacing.space8),

                  // Save button
                  _buildSaveButton(theme, l10n, state),
                  const SizedBox(height: AppSpacing.space8),

                  // Logout button
                  _buildLogoutButton(theme, l10n),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Maps backend error codes to localized messages.
  /// Returns null if no mapping exists (fallback to raw message).
  String? _mapErrorCodeToMessage(String? code, AppLocalizations l10n) {
    if (code == null) return null;

    // Add error code mappings here
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
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(
    ThemeData theme,
    AppLocalizations l10n,
    ProfileState state,
  ) {
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
        onPressed: isLoading ? null : _onSave,
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
            : Text(l10n.profileSaveButton),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: AppSpacing.inputHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context, l10n),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.inputHeight),
          foregroundColor: Colors.red,
          side: BorderSide.none,
        ),
        icon: const Icon(Icons.logout),
        label: Text(l10n.profileLogoutButton),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    // Capture BLoC before async gap
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
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
