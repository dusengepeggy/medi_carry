import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_assets.dart';
import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/models/patient_profile.dart';
import '../../share/data/records_pdf.dart';
import '../models/medical_record.dart';
import '../widgets/clinical_details_card.dart';
import '../widgets/doctor_notes_card.dart';

/// Record Details — an implementation of the "Record Details (Final)" Figma
/// frame (node 2:406), populated from a real [MedicalRecord].
class RecordDetailsScreen extends StatelessWidget {
  const RecordDetailsScreen({super.key, required this.record});

  final MedicalRecord record;

  /// Renders this single record as a one-page PDF and hands it to the OS
  /// print/share sheet — which is what "Print" means on a phone.
  Future<void> _printRecord(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = context.read<AuthBloc>().state.user.uid;
    try {
      final profile = uid.isEmpty
          ? null
          : await context.read<UserRepository>().fetchProfile(uid);
      final bytes = await RecordsPdf.build(
        profile: profile ??
            const PatientProfile(
              uid: '',
              fullName: '',
              email: '',
              patientId: '—',
            ),
        records: [record],
      );
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not prepare the printout.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
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
                    _ContextualHeader(
                      title: record.title,
                      status: record.category.label,
                      date: record.formattedDate,
                      place: record.provider.isEmpty
                          ? 'No facility recorded'
                          : record.provider,
                    ),
                    const SizedBox(height: 16),
                    ClinicalDetailsCard(
                      physician: record.provider.isEmpty
                          ? '—'
                          : record.provider,
                      speciality: record.category.title,
                      resultSummary: record.detail.isEmpty
                          ? 'No summary recorded.'
                          : record.detail,
                    ),
                    if (record.attachments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _Attachments(attachments: record.attachments),
                    ],
                    if (record.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 32),
                      DoctorNotesCard(notes: record.notes),
                    ],
                    const SizedBox(height: 24),
                    _ActionButtons(
                      onShare: () => AppNav.openShare(context),
                      onPrint: () => _printRecord(context),
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
              color: context.colors.textPrimary,
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
          color: context.colors.surface,
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
            color: context.colors.textPrimary,
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
              color: context.colors.textSecondary,
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
              // Was hardcoded white while the label followed the theme, so in
              // dark mode this was light text on a white pill.
              backgroundColor: context.colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(color: context.colors.border),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.detailPrint,
                  width: 16.667,
                  height: 15,
                  // The exported glyph is dark ink; tinted so it survives the
                  // dark surface too.
                  colorFilter: ColorFilter.mode(
                    context.colors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Print PDF',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 22.5 / 15,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
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

/// Real attachments (Cloudinary images/PDFs) for the record, tappable to open.
class _Attachments extends StatelessWidget {
  const _Attachments({required this.attachments});

  final List<RecordAttachment> attachments;

  Future<void> _open(BuildContext context, RecordAttachment a) async {
    final uri = Uri.tryParse(a.url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the attachment.')),
      );
    }
  }

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
            'ATTACHMENTS',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < attachments.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _AttachmentRow(
              attachment: attachments[i],
              onTap: () => _open(context, attachments[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment, required this.onTap});

  final RecordAttachment attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: attachment.isImage
                    ? Image.network(
                        attachment.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.broken_image_outlined),
                      )
                    : Container(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        child: const Icon(Icons.picture_as_pdf_outlined,
                            color: AppColors.navy),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
