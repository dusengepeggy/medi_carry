import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Horizontally scrolling category filters from the Medical Records (Final)
/// design. The design shows "All" selected and the row scrolling past "Labs".
class RecordFilterChips extends StatelessWidget {
  const RecordFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final isSelected = filter == selected;
          return _Chip(
            label: filter,
            isSelected: isSelected,
            onTap: onSelected == null ? null : () => onSelected!(filter),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 6 : 1,
              offset: Offset(0, isSelected ? 4 : 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: isSelected ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
