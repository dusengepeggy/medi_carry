import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../models/share_payload.dart';

/// "Customize Sharing Access" — the granular record-selection control from the
/// dark Modern frame (node 16:2). This is the patient-facing half of the
/// brief's granular sharing non-negotiable: they choose exactly which
/// categories a share carries.
class AccessSelectionCard extends StatelessWidget {
  const AccessSelectionCard({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<ShareCategory> selected;
  final ValueChanged<ShareCategory> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize Sharing Access',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Select records to share',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (final category in ShareCategory.values)
            _CategoryRow(
              label: category.label,
              checked: selected.contains(category),
              onTap: () => onToggle(category),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppColors.limeFinal : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? AppColors.limeFinal : colors.border,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check,
                      size: 16, color: AppColors.limeOnSurface)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  height: 22 / 15,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
