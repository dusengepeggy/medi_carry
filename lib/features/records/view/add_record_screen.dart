import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Add Record — the centre nav button's destination.
///
/// Placeholder: no Figma frame exists and the records feature has no write
/// path yet. It lists the record types the flow will support so the button is
/// not a silent no-op, and is explicit that nothing can be saved yet.
class AddRecordScreen extends StatelessWidget {
  const AddRecordScreen({super.key});

  static const _types = [
    (Icons.science_outlined, 'Lab result', 'Upload or enter test results'),
    (Icons.medication_outlined, 'Medication', 'Track a prescription'),
    (Icons.local_hospital_outlined, 'Diagnosis', 'Record a diagnosis'),
    (Icons.image_outlined, 'Imaging', 'Attach a scan or photo'),
    (Icons.favorite_outline, 'Vitals', 'Log a manual reading'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close, color: AppColors.navy),
        ),
        title: Text(
          'Add New Record',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.indigoSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.construction_outlined,
                      size: 20, color: AppColors.navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adding records is not available yet.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final (icon, title, subtitle) in _types) ...[
              Opacity(
                opacity: 0.5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.indigoSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, size: 20, color: AppColors.navy),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 16,
                                height: 24 / 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: AppColors.navy.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
