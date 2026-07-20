import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// "Clinical Details" white card from the Record Details (Final) design.
class ClinicalDetailsCard extends StatelessWidget {
  const ClinicalDetailsCard({
    super.key,
    required this.physician,
    required this.speciality,
    required this.patientId,
    required this.resultSummary,
  });

  final String physician;
  final String speciality;
  final String patientId;
  final String resultSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.indigoSurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.detailClinical,
                    width: 12,
                    height: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Clinical Details',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _FieldLabel('REFERRING PHYSICIAN'),
          const SizedBox(height: 4),
          Text(
            physician,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              height: 27 / 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          Text(
            speciality,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              height: 21 / 14,
              color: AppColors.navy.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('PATIENT ID'),
          const SizedBox(height: 4),
          Text(
            patientId,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              height: 27 / 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 17),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.hairline),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('RESULT SUMMARY'),
                const SizedBox(height: 7.44),
                Text(
                  resultSummary,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 24.38 / 15,
                    color: AppColors.navy.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        height: 16.5 / 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.55,
        color: AppColors.navy.withValues(alpha: 0.5),
      ),
    );
  }
}
