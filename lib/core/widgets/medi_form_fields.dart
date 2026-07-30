import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_semantic_colors.dart';

/// Small uppercase field label, e.g. "CATEGORY".
class MediLabel extends StatelessWidget {
  const MediLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: context.colors.textSecondary,
        ),
      );
}

/// The filled, borderless text field used across every create/edit form.
class MediTextField extends StatelessWidget {
  const MediTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: GoogleFonts.hankenGrotesk(fontSize: 16, color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.hankenGrotesk(fontSize: 16, color: colors.textMuted),
        filled: true,
        fillColor: colors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
        ),
      ),
    );
  }
}

/// A read-only field that opens a picker when tapped — dates, times, choices.
class MediTapField extends StatelessWidget {
  const MediTapField({
    super.key,
    required this.value,
    required this.icon,
    required this.onTap,
    this.placeholder,
  });

  /// The current value, or null to show [placeholder].
  final String? value;
  final String? placeholder;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text ?? placeholder ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  color: text == null ? colors.textMuted : colors.textPrimary,
                ),
              ),
            ),
            Icon(icon, size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// A row of single-select pills.
class MediChoiceChips<T> extends StatelessWidget {
  const MediChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onSelected(value),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: value == selected
                    ? AppColors.navy
                    : context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                labelOf(value),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == selected
                      ? Colors.white
                      : context.colors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The full-width primary action at the foot of a form.
class MediPrimaryButton extends StatelessWidget {
  const MediPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: busy ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
