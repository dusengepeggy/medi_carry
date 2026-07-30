import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// A scanned document attached to a record.
class Attachment {
  const Attachment({
    required this.name,
    required this.size,
    required this.preview,
  });

  /// e.g. "Lab_Results_Pg1.pdf".
  final String name;

  /// e.g. "1.2 MB".
  final String size;

  /// Asset path of the preview image.
  final String preview;
}

/// "Scanned Documents" section from the Record Details (Final) design: a
/// horizontally scrolling strip of document previews that bleeds to the screen
/// edges.
class AttachmentsSection extends StatelessWidget {
  const AttachmentsSection({
    super.key,
    required this.attachments,
    this.onOpen,
  });

  final List<Attachment> attachments;
  final void Function(Attachment attachment)? onOpen;

  /// The screen's horizontal padding, which this strip bleeds past.
  static const _bleed = 20.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flexible so a large text scale ellipsizes rather than
            // overflowing; unchanged at design width.
            Flexible(
              child: Text(
                'Scanned Documents',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  height: 27 / 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${attachments.length} '
                '${attachments.length == 1 ? 'File' : 'Files'}',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 268,
          child: OverflowBox(
            maxWidth: MediaQuery.sizeOf(context).width,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _bleed),
              itemCount: attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, i) => _AttachmentCard(
                attachment: attachments[i],
                onTap: onOpen == null ? null : () => onOpen!(attachments[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.attachment, this.onTap});

  final Attachment attachment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 200,
        height: 260,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(attachment.preview, fit: BoxFit.cover),
              // Scrim so the filename stays legible over any scan.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      context.colors.textPrimary,
                      AppColors.navy.withValues(alpha: 0.2),
                      AppColors.navy.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppAssets.detailEye,
                                width: 18.333,
                                height: 12.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        height: 21 / 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        attachment.size,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          height: 16.5 / 11,
                          letterSpacing: 0.55,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
