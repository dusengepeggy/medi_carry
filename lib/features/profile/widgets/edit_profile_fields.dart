import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// The Edit Profile form appears on light cards and on the dark Emergency
/// Contact card, which flips the label, fill and text colours.
enum EditFieldStyle { light, dark }

/// Shared chrome for a labelled Edit Profile field: label above, then a
/// rounded row with a leading icon and the control.
class EditFieldShell extends StatelessWidget {
  const EditFieldShell({
    super.key,
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.child,
    this.style = EditFieldStyle.light,
  });

  final String label;
  final String icon;
  final Size iconSize;
  final Widget child;
  final EditFieldStyle style;

  bool get _isDark => style == EditFieldStyle.dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w500,
            color: _isDark ? AppColors.labelOnDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isDark ? 17 : 16,
            vertical: _isDark ? 13 : 12,
          ),
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: _isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.05))
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: SvgPicture.asset(
                  icon,
                  width: iconSize.width,
                  height: iconSize.height,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

/// A free-text field (Full Name, contact name, phone).
class EditTextField extends StatelessWidget {
  const EditTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.controller,
    this.style = EditFieldStyle.light,
    this.keyboardType,
    this.hintText,
  });

  final String label;
  final String icon;
  final Size iconSize;
  final TextEditingController controller;
  final EditFieldStyle style;
  final TextInputType? keyboardType;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final isDark = style == EditFieldStyle.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    return EditFieldShell(
      label: label,
      icon: icon,
      iconSize: iconSize,
      style: style,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        cursorColor: textColor,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          height: 24 / 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hintText,
          hintStyle: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            height: 24 / 16,
            color: textColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// A field that opens a date picker rather than accepting free text, so the
/// stored value stays a valid date.
class EditDateField extends StatelessWidget {
  const EditDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.style = EditFieldStyle.light,
  });

  final String label;

  /// The selected date, or null when the patient hasn't set one.
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final EditFieldStyle style;

  static String _format(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = style == EditFieldStyle.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    return GestureDetector(
      onTap: () => _pick(context),
      child: EditFieldShell(
        label: label,
        icon: AppAssets.editCalendar,
        iconSize: const Size(30, 20),
        style: style,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Not set' : _format(value!),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  height: 24 / 16,
                  color: value == null
                      ? textColor.withValues(alpha: 0.4)
                      : textColor,
                ),
              ),
            ),
            SvgPicture.asset(AppAssets.dropdownChevron, width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}

/// A select field (Blood Type, Gender).
class EditDropdownField extends StatelessWidget {
  const EditDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.value,
    required this.options,
    required this.onChanged,
    this.style = EditFieldStyle.light,
  });

  final String label;
  final String icon;
  final Size iconSize;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final EditFieldStyle style;

  @override
  Widget build(BuildContext context) {
    final isDark = style == EditFieldStyle.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    return EditFieldShell(
      label: label,
      icon: icon,
      iconSize: iconSize,
      style: style,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(16),
          hint: Text(
            'Select',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              height: 24 / 16,
              color: textColor.withValues(alpha: 0.4),
            ),
          ),
          icon: SvgPicture.asset(
            AppAssets.dropdownChevron,
            width: 20,
            height: 20,
          ),
          dropdownColor: isDark ? AppColors.ink : Colors.white,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            height: 24 / 16,
            color: textColor,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

/// The group heading above each form card ("PERSONAL INFORMATION", etc).
class EditSectionHeading extends StatelessWidget {
  const EditSectionHeading(this.text, {super.key, this.onDark = false});

  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: onDark ? AppColors.lime : AppColors.olive,
      ),
    );
  }
}
