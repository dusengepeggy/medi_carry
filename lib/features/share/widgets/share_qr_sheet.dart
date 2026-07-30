import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// Full-screen sheet showing the generated QR plus the PIN the patient reads
/// aloud. The QR is always on white for scannability, regardless of theme.
class ShareQrSheet extends StatelessWidget {
  const ShareQrSheet({
    super.key,
    required this.code,
    required this.pin,
    required this.expiresLabel,
  });

  final String code;
  final String pin;
  final String expiresLabel;

  static Future<void> show(
    BuildContext context, {
    required String code,
    required String pin,
    required String expiresLabel,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            ShareQrSheet(code: code, pin: pin, expiresLabel: expiresLabel),
      );

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Share code copied')),
      );
  }

  Future<void> _sendCode() => SharePlus.instance.share(
        ShareParams(
          text: code,
          subject: 'MediCarry share code',
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Scan to share',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The recipient scans this and enters the PIN below. Works '
                'completely offline.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 20 / 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  // The payload is encrypted, so the code is dense. Medium
                  // correction keeps it readable when the screen is scanned at
                  // an angle without pushing it to a version that needs a
                  // bigger display.
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  errorStateBuilder: (context, error) => _QrTooLarge(
                    onCopy: () => _copy(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _AppOnlyNotice(),
              const SizedBox(height: 16),
              _PinBadge(pin: pin),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule,
                      size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    expiresLabel,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copy(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sendCode,
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Send code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
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

/// Explains why a phone's ordinary camera app reports nothing useful for this
/// code.
///
/// The payload is encrypted, not a link — a stock scanner sees an opaque
/// string and says it found "no information". That is correct behaviour, but
/// without saying so here it reads as a broken QR.
class _AppOnlyNotice extends StatelessWidget {
  const _AppOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Scan this from MediCarry (Share Records → Scan a shared code). '
              'A normal camera app will report no information, because the '
              'records inside are encrypted rather than a web link.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                height: 17 / 12,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback when the payload is too dense for any QR version — the patient can
/// still hand the code over as text.
class _QrTooLarge extends StatelessWidget {
  const _QrTooLarge({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_outlined, size: 36, color: AppColors.navy),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Too much selected to fit in one QR. Share fewer categories, or '
              'send the code as text.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                height: 18 / 13,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onCopy, child: const Text('Copy code')),
        ],
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'READ THIS PIN ALOUD',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pin.split('').join('  '),
            style: GoogleFonts.hankenGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: AppColors.limeFinal,
            ),
          ),
        ],
      ),
    );
  }
}
