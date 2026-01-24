import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/auth/bloc/verification_code_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

/// Auth page with Register/Login tabs based on UX Design Specification.
///
/// Design features per example:
/// - Hero illustration with brand colors
/// - Register/Login segmented control
/// - Pill-shaped inputs with labels above
/// - Primary button with brand shadow
/// - Social login options
/// - Terms agreement footer
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use global Dio instance from ServiceLocator
    final dio = ServiceLocator.instance.dio;

    return RepositoryProvider(
      create: (_) => AuthProvider(dio: dio),
      child: BlocProvider(
        create: (context) => VerificationCodeBloc(
          authProvider: context.read<AuthProvider>(),
        ),
        child: const AuthView(),
      ),
    );
  }
}

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  /// Current auth mode: true = register, false = login
  bool _isRegisterMode = false;

  /// Login mode: true = password, false = code
  bool _isPasswordLogin = true;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingH,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.space6),

                // Hero Illustration
                _buildHeroIllustration(),

                // Headline
                _buildHeadline(theme, l10n),
                const SizedBox(height: AppSpacing.space6),

                // Register/Login Toggle
                _buildAuthToggle(theme, l10n),
                const SizedBox(height: AppSpacing.space8),

                // Form Fields
                _buildFormFields(theme, l10n),
                const SizedBox(height: AppSpacing.space6),

                // Primary Action Button
                _buildPrimaryButton(theme, l10n),
                const SizedBox(height: AppSpacing.space8),

                // Divider
                _buildDivider(theme, l10n),
                const SizedBox(height: AppSpacing.space6),

                // Social Login
                _buildSocialLogins(theme),
                const SizedBox(height: AppSpacing.space8),

                // Terms Agreement
                _buildTermsAgreement(theme, l10n),
                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIllustration() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background gradient circle
            Container(
              width: 160,
              height: 160,
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
            ),

            // Favorite icon floating element
            Positioned(
              right: 20,
              bottom: 50,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    boxShadow: AppShadows.card,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
            ),

            // Handshake icon floating element
            Positioned(
              left: 20,
              top: 40,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: AppShadows.card,
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadline(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.authPageTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: AppTypography.extraBold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          l10n.authPageSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthToggle(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: l10n.authLoginTab,
              isSelected: !_isRegisterMode,
              onTap: () => setState(() => _isRegisterMode = false),
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: l10n.authRegisterTab,
              isSelected: _isRegisterMode,
              onTap: () => setState(() => _isRegisterMode = true),
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: isSelected ? AppShadows.card : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textMutedLight,
              fontWeight: isSelected
                  ? AppTypography.bold
                  : AppTypography.medium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Email/Phone Input (Always valid)
        _buildLabeledInput(
          key: const Key('auth_email_input'),
          label: l10n.authEmailOrPhoneLabel,
          icon: Icons.mail_outline,
          placeholder: l10n.authEmailPlaceholder,
          controller: _emailOrPhoneController,
          keyboardType: TextInputType.emailAddress,
          theme: theme,
          validator: (value) => (value == null || value.isEmpty)
              ? l10n.authValidationEmailRequired
              : null,
        ),

        if (_isRegisterMode) ...[
          // Register: Code + Password + Confirm
          const SizedBox(height: AppSpacing.space4),
          _buildCodeInputRow(theme, l10n),

          const SizedBox(height: AppSpacing.space4),
          _buildLabeledInput(
            key: const Key('auth_register_password_input'),
            label: l10n.authPasswordLabel,
            icon: Icons.lock_outline,
            placeholder: l10n.authPasswordPlaceholder,
            controller: _passwordController,
            theme: theme,
            obscureText: true,
            showVisibilityToggle: true,
            validator: (val) {
              if (val == null || val.length < 6) {
                return l10n.authValidationPasswordTooShort;
              }
              if (val.length > 20) {
                return l10n.authValidationPasswordTooLong;
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.space4),
          _buildLabeledInput(
            key: const Key('auth_register_confirm_password_input'),
            label: l10n.authPasswordConfirmLabel,
            icon: Icons.lock_outline,
            placeholder: l10n.authPasswordConfirmPlaceholder,
            controller: _confirmPasswordController,
            theme: theme,
            obscureText: true,
            showVisibilityToggle: true,
            validator: (val) => val != _passwordController.text
                ? l10n.authValidationPasswordsDoNotMatch
                : null,
          ),
        ] else ...[
          // Login: Select Mode
          const SizedBox(height: AppSpacing.space4),
          _buildLoginModeToggle(theme, l10n),

          const SizedBox(height: AppSpacing.space4),
          if (_isPasswordLogin)
            _buildLabeledInput(
              key: const Key('auth_login_password_input'),
              label: l10n.authPasswordLabel,
              icon: Icons.lock_outline,
              placeholder: l10n.authPasswordPlaceholder,
              controller: _passwordController,
              theme: theme,
              obscureText: true,
              showVisibilityToggle: true,
            )
          else
            _buildCodeInputRow(theme, l10n),
        ],
      ],
    );
  }

  Widget _buildCodeInputRow(ThemeData theme, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildLabeledInput(
            key: const Key('auth_code_input'),
            label: l10n.authVerificationCodeLabel,
            icon: Icons.numbers,
            placeholder: l10n.authVerificationCodePlaceholder,
            controller: _codeController,
            theme: theme,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildGetCodeButton(theme, l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGetCodeButton(ThemeData theme, AppLocalizations l10n) {
    return BlocBuilder<VerificationCodeBloc, VerificationCodeState>(
      builder: (context, state) {
        final isSending = state.status == VerificationCodeStatus.sending;
        final isCountdown = state.isCountdownActive;

        return Container(
          height: AppSpacing.inputHeight,
          width: 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceMutedLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: TextButton(
            onPressed: (isSending || isCountdown)
                ? null
                : () {
                    context.read<VerificationCodeBloc>().add(
                      SendVerificationCode(
                        type: _emailOrPhoneController.text.contains('@')
                            ? 'email'
                            : 'phone',
                        target: _emailOrPhoneController.text.trim(),
                      ),
                    );
                  },
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isCountdown
                        ? l10n.authResendButton(state.countdown)
                        : l10n.authGetVerificationCodeButton,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginModeToggle(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        _buildModeChip(
          l10n.authPasswordLogin,
          _isPasswordLogin,
          () => setState(() => _isPasswordLogin = true),
        ),
        const SizedBox(width: 12),
        _buildModeChip(
          l10n.authCodeLogin,
          !_isPasswordLogin,
          () => setState(() => _isPasswordLogin = false),
        ),
      ],
    );
  }

  Widget _buildModeChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtleLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMutedLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledInput({
    Key? key,
    required String label,
    required IconData icon,
    required String placeholder,
    required TextEditingController controller,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    bool showVisibilityToggle = false,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space4,
            bottom: AppSpacing.space1 + 2,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: AppTypography.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _AuthInputField(
          controller: controller,
          icon: icon,
          placeholder: placeholder,
          theme: theme,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          showVisibilityToggle: showVisibilityToggle,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(ThemeData theme, AppLocalizations l10n) {
    // Determine button text
    final buttonText = _isRegisterMode
        ? l10n.authCreateAccountButton
        : l10n.authLoginTab;

    return Container(
      width: double.infinity,
      height: AppSpacing.inputHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: !_isSubmitting
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
        onPressed: _isSubmitting ? null : _onSubmit,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.inputHeight),
        ),
        child: _isSubmitting
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
                  Text(buttonText),
                  const SizedBox(width: AppSpacing.space2),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderSubtleLight,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Text(
            l10n.authOrContinueWith,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMutedLight,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderSubtleLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogins(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(Icons.g_mobiledata, 'Google'),
        const SizedBox(width: AppSpacing.space4),
        _buildSocialButton(Icons.apple, 'Apple'),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderSubtleLight),
        boxShadow: AppShadows.card,
      ),
      child: IconButton(
        onPressed: () {
          // TODO(social): Implement social login - https://github.com/way2we/way2we/issues/4
        },
        icon: Icon(
          icon,
          size: 24,
          color: AppColors.textMainLight,
        ),
      ),
    );
  }

  Widget _buildTermsAgreement(ThemeData theme, AppLocalizations l10n) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textMutedLight,
        ),
        children: [
          TextSpan(text: '${l10n.authTermsAgreement} '),
          TextSpan(
            text: l10n.authTermsOfService,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO(legal): Open Terms of Service - https://github.com/way2we/way2we/issues/5
              },
          ),
          TextSpan(text: ' ${l10n.authAnd} '),
          TextSpan(
            text: l10n.authPrivacyPolicy,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO(legal): Open Privacy Policy - https://github.com/way2we/way2we/issues/6
              },
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final l10n = context.l10n;
    final target = _emailOrPhoneController.text.trim();
    final type = target.contains('@') ? 'email' : 'phone';

    try {
      if (_isRegisterMode) {
        await auth.register(
          type: type,
          target: target,
          code: _codeController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.authRegistrationSuccess),
            ),
          );
          // Notify AuthenticationBloc of successful login
          context.read<AuthenticationBloc>().add(
            const AppLoginSucceeded(needsOnboarding: true),
          );
          // Navigation is handled by App's BlocListener
        }
      } else {
        await auth.login(
          type: type,
          target: target,
          mode: _isPasswordLogin ? 'password' : 'code',
          credential: _isPasswordLogin
              ? _passwordController.text
              : _codeController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authLoginSuccess)),
          );
          // Notify AuthenticationBloc of successful login
          context.read<AuthenticationBloc>().add(const AppLoginSucceeded());
          // Navigation is handled by App's BlocListener
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e
                  .toString()
                  .replaceAll('AuthApiException: ', '')
                  .split('(code')[0],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// A focus-aware input field that invokes [FormField] to manage state,
/// allowing error messages to be rendered *outside* the decorative container.
class _AuthInputField extends StatefulWidget {
  const _AuthInputField({
    required this.controller,
    required this.icon,
    required this.placeholder,
    required this.theme,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.showVisibilityToggle = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String placeholder;
  final ThemeData theme;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool showVisibilityToggle;

  @override
  State<_AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<_AuthInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use a FormField to integrate with the parent Form, but render
    // the error message outside the input container.
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.controller.text,
      builder: (FormFieldState<String> field) {
        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _focusNode.requestFocus,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: AppSpacing.inputHeight,
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: AppShadows.card,
                  border: Border.all(
                    color: hasError
                        ? AppColors.error
                        : (_isFocused
                              ? AppColors.borderFocus
                              : Colors.transparent),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                ),
                child: Center(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText && _isObscured,
                    style: widget.theme.textTheme.bodyLarge,
                    // Sync TextField changes to FormField state
                    onChanged: (value) {
                      field.didChange(value);
                    },
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: widget.placeholder,
                      hintStyle: widget.theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPlaceholderLight,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.space2,
                        ),
                        child: Icon(
                          widget.icon,
                          color: AppColors.textMutedLight,
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                      ),
                      suffixIcon: widget.showVisibilityToggle
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                              child: Icon(
                                _isObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMutedLight,
                                size: 20,
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
            // Render error message outside the container
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.space4,
                  top: AppSpacing.space2,
                ),
                child: Text(
                  field.errorText!,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
