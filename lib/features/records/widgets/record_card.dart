import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';

.
enum RecordCardStyle {
  /// Vibrant lime — lab results.
  lime,

  /// Deep navy — medications.
  navy,

  /// Light surface — diagnoses.
  light,
}

/// A single medical record.
class RecordEntry {
  const RecordEntry({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.style,
    this.iconSize = const Size(20, 20),
    this.metaIcon = AppAssets.calendar,
    this.metaIconSize = const Size(13.5, 15),
  });

  /// e.g. "LAB RESULT".
  final String category;

  /// e.g. "Comprehensive Metabolic Panel".
  final String title;

  /// e.g. "Nairobi Hospital Central Lab • Dr. J. Kamau".
  final String subtitle;

  /// e.g. "Oct 24, 2023".
  final String meta;

  final String icon;
  final Size iconSize;
  final String metaIcon;
  final Size metaIconSize;
  final RecordCardStyle style;
}

/// A record card from the Medical Records
class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record, this.onTap});

  final RecordEntry record;
  final VoidCallback? onTap;

  bool get _isNavy => record.style == RecordCardStyle.navy;

  Color get _background => switch (record.style) {
    RecordCardStyle.lime => AppColors.limeFinal,
    RecordCardStyle.navy => AppColors.navy,
    RecordCardStyle.light => Colors.white,
  };

  Color get _foreground => _isNavy ? Colors.white : AppColors.navy;
  Color get _iconTint => _foreground;

  Color get _categoryColor => switch (record.style) {
    RecordCardStyle.lime => AppColors.navy.withValues(alpha: 0.8),
    RecordCardStyle.navy => Colors.white.withValues(alpha: 0.8),
    RecordCardStyle.light => AppColors.navy.withValues(alpha: 0.7),
  };

  Color get _chipBackground => switch (record.style) {
    RecordCardStyle.lime => Colors.white.withValues(alpha: 0.4),
    RecordCardStyle.navy => Colors.white.withValues(alpha: 0.2),
    RecordCardStyle.light => AppColors.indigoSurface,
  };

  Color get _subtitleColor => switch (record.style) {
    RecordCardStyle.lime => AppColors.navy.withValues(alpha: 0.8),
    RecordCardStyle.navy => Colors.white.withValues(alpha: 0.8),
    RecordCardStyle.light => AppColors.navy.withValues(alpha: 0.7),
  };

  Color get _metaColor => switch (record.style) {
    RecordCardStyle.lime => AppColors.navy.withValues(alpha: 0.7),
    RecordCardStyle.navy => Colors.white.withValues(alpha: 0.7),
    RecordCardStyle.light => AppColors.navy.withValues(alpha: 0.6),
  };

  BoxBorder? get _border => switch (record.style) {
    RecordCardStyle.lime => Border.all(
      color: AppColors.limeFinal.withValues(alpha: 0.2),
    ),
    RecordCardStyle.navy => null,
    RecordCardStyle.light => Border.all(color: AppColors.indigoSurface),
  };

  List<BoxShadow> get _shadow => switch (record.style) {
    RecordCardStyle.lime => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 6,
        offset: const Offset(0, 4),
      ),
    ],
    RecordCardStyle.navy => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 25,
        offset: const Offset(0, 20),
      ),
    ],
    RecordCardStyle.light => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 15,
        offset: const Offset(0, 10),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(_isNavy ? 24 : 25),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(32),
            border: _border,
            boxShadow: _shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _chipBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        record.icon,
                        width: record.iconSize.width,
                        height: record.iconSize.height,
                        colorFilter: ColorFilter.mode(
                          _iconTint,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      record.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                        color: _categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    AppAssets.recordArrow,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(_iconTint, BlendMode.srcIn),
                  ),
                ],
              ),
              const SizedBox(height: 24), // 8 pb + 16 gap
              Text(
                record.title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 28,
                  height: 35 / 28,
                  fontWeight: FontWeight.w700,
                  color: _foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record.subtitle,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  height: 24 / 16,
                  color: _subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SvgPicture.asset(
                    record.metaIcon,
                    width: record.metaIconSize.width,
                    height: record.metaIconSize.height,
                    colorFilter: ColorFilter.mode(_metaColor, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      record.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                        color: _metaColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
