import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/stored_attachment.dart';
import '../theme/app_colors.dart';
import '../theme/app_semantic_colors.dart';
import 'medi_form_fields.dart';

/// The attach-a-document control shared by Add Record and Add Card: the list of
/// files already uploaded, plus the button that adds another.
class DocumentsField extends StatelessWidget {
  const DocumentsField({
    super.key,
    required this.label,
    required this.documents,
    required this.uploading,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    this.disabledMessage =
        'File uploads are unavailable — storage is not configured.',
    this.addLabel = 'Add document',
  });

  final String label;
  final List<StoredAttachment> documents;

  /// True while an upload is in flight.
  final bool uploading;

  /// False when storage is not configured, so the control explains itself
  /// instead of failing on tap.
  final bool enabled;

  final VoidCallback onAdd;
  final void Function(StoredAttachment document) onRemove;
  final String disabledMessage;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediLabel(label),
        const SizedBox(height: 8),
        if (!enabled)
          Text(
            disabledMessage,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: colors.textMuted,
            ),
          )
        else ...[
          for (final document in documents)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DocumentRow(
                document: document,
                onRemove: () => onRemove(document),
              ),
            ),
          OutlinedButton.icon(
            onPressed: uploading ? null : onAdd,
            icon: uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file, size: 18),
            label: Text(uploading ? 'Uploading…' : addLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.onRemove});

  final StoredAttachment document;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = document.sizeLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 36,
              height: 36,
              child: document.isImage
                  ? Image.network(
                      document.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.image_outlined, color: colors.textMuted),
                    )
                  : Container(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 20,
                        color: AppColors.navy,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (size != null)
                  Text(
                    size,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove',
            icon: Icon(Icons.close, size: 18, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
