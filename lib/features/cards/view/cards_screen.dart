import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../bloc/cards_cubit.dart';
import '../data/cards_repository.dart';
import '../models/insurance_card.dart';
import '../widgets/insurance_card_tile.dart';
import 'add_card_screen.dart';
import 'card_details_screen.dart';

/// "My Cards" — the insurance / patient-ID wallet, backed by the patient's
/// real cards in Firestore and readable offline.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthBloc b) => b.state.user.uid);
    return BlocProvider(
      // Keyed on uid so the cubit is recreated once auth resolves the user.
      key: ValueKey(uid),
      create: (_) => CardsCubit(
        repository: context.read<CardsRepository>(),
        uid: uid,
      ),
      child: const _CardsView(),
    );
  }
}

class _CardsView extends StatelessWidget {
  const _CardsView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.canvas,
      extendBody: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        backgroundColor: AppColors.indigoFinal,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'Add Card',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CardsCubit, CardsState>(
          builder: (context, state) {
            if (state.status == CardsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == CardsStatus.error) {
              return const _EmptyState(
                icon: Icons.cloud_off,
                title: 'Could not load your cards',
                body: 'Check your connection and try again.',
              );
            }
            if (state.cards.isEmpty) {
              return _EmptyState(
                icon: Icons.badge_outlined,
                title: 'My Cards',
                body: 'Add your RSSB, Mutuelle de Santé, RAMA, MMI or private '
                    'insurance card — with a photo or PDF of the card itself — '
                    'and it stays available offline.',
                actionLabel: 'Add your first card',
                onAction: () => _openEditor(context),
              );
            }

            final expiring = state.valid.where((c) => c.expiresSoon).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              children: [
                Text(
                  'My Cards',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your insurance and patient ID cards, available offline.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                if (expiring.isNotEmpty) ...[
                  _ExpiryBanner(cards: expiring),
                  const SizedBox(height: 16),
                ],
                for (final card in state.valid) ...[
                  InsuranceCardTile(
                    card: card,
                    onTap: () => _openDetails(context, card),
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.expired.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'EXPIRED',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final card in state.expired) ...[
                    InsuranceCardTile(
                      card: card,
                      onTap: () => _openDetails(context, card),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _openEditor(BuildContext context) {
    final cubit = context.read<CardsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const AddCardScreen(),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, InsuranceCard card) {
    final cubit = context.read<CardsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CardDetailsScreen(cardId: card.id),
        ),
      ),
    );
  }
}

class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner({required this.cards});

  final List<InsuranceCard> cards;

  @override
  Widget build(BuildContext context) {
    final names = cards.map((c) => c.displayProvider).join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.onWarningSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cards.length == 1
                  ? '$names expires within 30 days.'
                  : 'These cards expire within 30 days: $names.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.onWarningSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Offered on the empty wallet, where the FAB is easy to miss against a
  /// mostly blank screen. Omitted for the error state, which has no action.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: colors.textPrimary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24,
                height: 32 / 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                height: 24 / 16,
                color: colors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                label: Text(
                  actionLabel!,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
