import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/attachments_section.dart';
import '../widgets/clinical_details_card.dart';
import '../widgets/doctor_notes_card.dart';

/// Record Details — an implementation of the "Record Details (Final)" Figma
/// frame (node 2:406).
///
/// The record shown is the design's sample content until the records feature
/// supplies real data.
class RecordDetailsScreen extends StatelessWidget {
  const RecordDetailsScreen({super.key});

  static const _attachments = [
    Attachment(
      name: 'Lab_Results_Pg1.pdf',
      size: '1.2 MB',
      preview: AppAssets.attachment1,
    ),
    Attachment(
      name: 'Imaging_Scan.jpg',
      size: '4.5 MB',
      preview: AppAssets.attachment2,
    ),
  ];

  static const _resultSummary =
      'Most metabolic markers are within normal reference ranges. However, '
      'fasting blood glucose is mildly elevated (108 mg/dL). Calcium levels '
      'are optimal. Recommend lifestyle modifications and a follow-up test in '
      '3 months.';

  static const _notes =
      '"Patient presents with mild fatigue over the last 3 weeks. Routine CMP '
      'ordered to rule out metabolic imbalances. Results indicate pre-diabetic '
      'glucose levels. We discussed dietary adjustments, specifically reducing '
      'processed carbohydrates, and integrating light daily exercise. Patient '
      'was receptive. Will monitor and re-test fasting glucose at next '
      'quarterly visit."';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailAppBar(
              onBack: () => Navigator.of(context).maybePop(),
              onOptions: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const _ContextualHeader(
                      title: 'Comprehensive Metabolic Panel',
                      status: 'REVIEW REQUIRED',
                      date: 'Oct 24, 2023 • 08:15 AM',
                      place: 'Nairobi Central Clinic',
                    ),
                    const SizedBox(height: 16),
                    const ClinicalDetailsCard(
                      physician: 'Dr. Amina Ochieng',
                      speciality: 'Endocrinology',
                      patientId: 'MC-8492-771',
                      resultSummary: _resultSummary,
                    ),
                    const SizedBox(height: 24),
                    AttachmentsSection(
                      attachments: _attachments,
                      onOpen: (_) {},
                    ),
                    const SizedBox(height: 32),
                    const DoctorNotesCard(notes: _notes),
                    const SizedBox(height: 24),
                    _ActionButtons(
                      onShare: () => AppNav.openShare(context),
                      onPrint: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({this.onBack, this.onOptions});

  final VoidCallback? onBack;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(
            onTap: onBack,
            child: SvgPicture.asset(
              AppAssets.detailBack,
              width: 9.813,
              height: 16.667,
            ),
          ),
          Text(
            'Record Details',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              height: 27 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          _CircleButton(
            onTap: onOptions,
            child: SvgPicture.asset(
              AppAssets.detailMore,
              width: 3.333,
              height: 13.333,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ContextualHeader extends StatelessWidget {
  const _ContextualHeader({
    required this.title,
    required this.status,
    required this.date,
    required this.place,
  });

  final String title;
  final String status;
  final String date;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 28,
            height: 35 / 28,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.detailAlert,
                  width: 2.333,
                  height: 10.5,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    height: 18 / 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.onWarningSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _MetaRow(icon: AppAssets.detailMetaDate, label: date, size: const Size(12, 13.333)),
        const SizedBox(height: 3.5),
        _MetaRow(icon: AppAssets.detailMetaPlace, label: place, size: const Size(12, 12)),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.size});

  final String icon;
  final String label;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: size.width, height: size.height),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              height: 21 / 14,
              color: AppColors.navy.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({this.onShare, this.onPrint});

  final VoidCallback? onShare;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onShare,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.indigoFinal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.detailShareRecord,
                  width: 15,
                  height: 16.667,
                ),
                const SizedBox(width: 8),
                Text(
                  'Share Record',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 22.5 / 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onPrint,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: AppColors.hairline),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.detailPrint,
                  width: 16.667,
                  height: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  'Print PDF',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 22.5 / 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
