import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/insurance_card.dart';

/// A wallet-style tile for one insurance / ID card: provider, number, validity.
///
/// Rendered in the provider's accent colour so the right card is recognisable
/// at a glance at a reception desk.
class InsuranceCardTile extends StatelessWidget {
  const InsuranceCardTile({super.key, required this.card, this.onTap});

  final InsuranceCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = card.isExpired ? AppColors.slateGray : card.provider.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.displayProvider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                _Pill(
                  label: card.type.label.toUpperCase(),
                  background: Colors.white.withValues(alpha: 0.2),
                  foreground: Colors.white,
                ),
              ],
            ),
            if (card.scheme.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                card.scheme,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'MEMBER NUMBER',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                card.memberNumber.isEmpty ? '—' : card.memberNumber,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.memberName.isEmpty ? '' : card.memberName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                if (card.validityLabel case final validity?)
                  _Pill(
                    label: validity,
                    background: card.isExpired
                        ? AppColors.warningSurface
                        : Colors.white.withValues(alpha: 0.15),
                    foreground: card.isExpired
                        ? AppColors.onWarningSurface
                        : Colors.white,
                  ),
              ],
            ),
            if (card.documents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${card.documents.length} '
                    '${card.documents.length == 1 ? 'document' : 'documents'}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: foreground,
        ),
      ),
    );
  }
}
