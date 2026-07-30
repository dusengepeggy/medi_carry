import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/attachment_picker.dart';
import '../services/file_storage.dart';
import '../theme/app_semantic_colors.dart';

/// Asks where a document should come from. Shared by Add Record and My Cards.
abstract final class AttachmentSourceSheet {
  AttachmentSourceSheet._();

  static Future<AttachmentSource?> show(
    BuildContext context, {
    String title = 'Add a document',
  }) =>
      showModalBottomSheet<AttachmentSource>(
        context: context,
        backgroundColor: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    title,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: sheetContext.colors.textPrimary,
                    ),
                  ),
                ),
                _Option(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take a photo',
                  description: 'Scan a paper document with the camera',
                  onTap: () => Navigator.of(sheetContext)
                      .pop(AttachmentSource.camera),
                ),
                _Option(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from photos',
                  description: 'Pick an existing picture',
                  onTap: () => Navigator.of(sheetContext)
                      .pop(AttachmentSource.gallery),
                ),
                _Option(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Choose a file',
                  description:
                      'PDF or image, up to ${FileStorage.maxBytesLabel}',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(AttachmentSource.files),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: colors.textPrimary),
      ),
      title: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
