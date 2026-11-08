import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: TextStyle(color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.prefixIcon, color: AppColors.secondaryText, size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.secondaryText,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
