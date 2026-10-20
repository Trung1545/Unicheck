import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// UniCheck Standard Mobile Input Field
/// Based on Google Stitch Form Input Components (Screen: e33ee574d1d84c8a8c5a65c09d27f83c)
class UniTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool isPassword;
  final bool showClearButton;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool autofocus;
  final int maxLines;

  const UniTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.isPassword = false,
    this.showClearButton = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
  });

  @override
  State<UniTextField> createState() => _UniTextFieldState();
}

class _UniTextFieldState extends State<UniTextField> {
  late bool _obscureText;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _hasContent = widget.controller?.text.isNotEmpty ?? false;
    widget.controller?.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    final hasContent = widget.controller?.text.isNotEmpty ?? false;
    if (hasContent != _hasContent && mounted) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: UniTypography.labelMedium.copyWith(
              color: UniColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: UniSpacing.spaceXs + 2),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          style: UniTypography.bodyMedium,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: UniColors.textSecondary,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffix != null) {
      return widget.suffix;
    }

    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20,
          color: UniColors.textSecondary,
        ),
        tooltip: _obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    if (widget.showClearButton && _hasContent && widget.enabled) {
      return IconButton(
        icon: const Icon(
          Icons.cancel_rounded,
          size: 18,
          color: UniColors.textMuted,
        ),
        tooltip: 'Xóa nội dung',
        onPressed: () {
          widget.controller?.clear();
          widget.onChanged?.call('');
        },
      );
    }

    return null;
  }
}
