import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// Search input from the Medical Records (Final) design.
class RecordsSearchField extends StatelessWidget {
  const RecordsSearchField({super.key, this.controller, this.onChanged});

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          color: context.colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search records by name or doctor...',
          hintStyle: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            color: context.colors.textMuted,
          ),
          filled: true,
          fillColor: context.colors.surface,
          contentPadding: const EdgeInsets.fromLTRB(0, 17, 16, 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 14),
            child: SvgPicture.asset(AppAssets.search, width: 18, height: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: context.colors.textPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
