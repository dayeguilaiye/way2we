import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:way2we_app/theme/theme.dart';

class W2WInput extends StatelessWidget {
  const W2WInput({
    required this.label,
    this.controller,
    this.hintText,
    this.suffixText,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.errorText,
    this.maxLength,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? suffixText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final String? errorText;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space4,
            bottom: AppSpacing.space1,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          inputFormatters: inputFormatters,
          textAlign: textAlign,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          maxLines: obscureText ? 1 : maxLines,
          minLines: 1,
          style: style ?? theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            suffixText: suffixText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            constraints: maxLines == 1
                ? const BoxConstraints(minHeight: AppSpacing.inputHeight)
                : null,
          ),
        ),
      ],
    );
  }
}
