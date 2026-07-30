import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/stored_attachment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../bloc/cards_cubit.dart';
import '../models/insurance_card.dart';
import '../widgets/insurance_card_tile.dart';
import 'add_card_screen.dart';

/// One card in full: the wallet tile, every recorded field, and the scans of
/// the physical card.
class CardDetailsScreen extends StatelessWidget {
  const CardDetailsScreen({super.key, required this.cardId});

  /// Looked up from the cubit rather than passed by value, so edits made on
  /// this screen are reflected without popping back first.
  final String cardId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<CardsCubit, CardsState>(
      builder: (context, state) {
        final card =
            state.cards.where((c) => c.id == cardId).firstOrNull;
        if (card == null) {
          // The card was deleted (here or on another device).
          return Scaffold(
            backgroundColor: colors.canvas,
            appBar: AppBar(backgroundColor: colors.canvas),
            body: Center(
              child: Text(
                'This card is no longer saved.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: colors.canvas,
          appBar: AppBar(
            backgroundColor: colors.canvas,
            surfaceTintColor: Colors.transparent,
            title: Text(
              card.displayProvider,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _edit(context, card),
                tooltip: 'Edit card',
                icon: Icon(Icons.edit_outlined, color: colors.textPrimary),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, card),
                tooltip: 'Delete card',
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                InsuranceCardTile(card: card),
                const SizedBox(height: 24),
                _Details(card: card),
                if (card.documents.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Documents(documents: card.documents),
                ],
                if (card.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Notes(notes: card.notes),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _edit(BuildContext context, InsuranceCard card) {
    final cubit = context.read<CardsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AddCardScreen(existing: card),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, InsuranceCard card) async {
    final cubit = context.read<CardsCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${card.displayProvider} card?'),
        content: const Text(
          'The card and any scans of it are removed from MediCarry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await cubit.delete(card);
      navigator.pop();
    }
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.card});

  final InsuranceCard card;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = <(String, String)>[
      ('Card type', card.type.label),
      ('Provider', card.displayProvider),
      if (card.memberName.isNotEmpty) ('Member', card.memberName),
      ('Member number', card.memberNumber.isEmpty ? '—' : card.memberNumber),
      if (card.policyNumber.isNotEmpty) ('Policy number', card.policyNumber),
      if (card.scheme.isNotEmpty) ('Plan / category', card.scheme),
      if (card.validFrom != null)
        ('Valid from', InsuranceCard.formatDate(card.validFrom!)),
      if (card.validUntil != null)
        ('Valid until', InsuranceCard.formatDate(card.validUntil!)),
    ];

    return Container(
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
            'CARD DETAILS',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      label,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
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

class _Documents extends StatelessWidget {
  const _Documents({required this.documents});

  final List<StoredAttachment> documents;

  Future<void> _open(BuildContext context, StoredAttachment document) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(document.url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCANS OF THE CARD',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.55,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: documents.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final document = documents[i];
              return GestureDetector(
                onTap: () => _open(context, document),
                child: Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: document.isImage
                      ? Image.network(
                          document.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _DocumentFallback(document: document),
                        )
                      : _DocumentFallback(document: document),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DocumentFallback extends StatelessWidget {
  const _DocumentFallback({required this.document});

  final StoredAttachment document;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            document.isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            size: 36,
            color: AppColors.navy,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              document.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to open',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              height: 22 / 15,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
