import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_shell.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../dashboard/widgets/medi_bottom_nav.dart' show MediTab;
import '../bloc/records_cubit.dart';
import '../data/records_repository.dart';
import '../widgets/record_card.dart';
import '../widgets/record_filter_chips.dart';
import '../widgets/records_app_bar.dart';
import '../widgets/records_search_field.dart';

/// Medical Records — an implementation of the "Medical Records (Final)" Figma
/// frame (node 2:274), backed by the patient's real records in Firestore via
/// [RecordsCubit].
class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthBloc b) => b.state.user.uid);
    return BlocProvider(
      // Keyed on uid so the cubit is recreated once auth resolves the user
      // (its stream starts empty), rather than staying subscribed to '' .
      key: ValueKey(uid),
      create: (_) => RecordsCubit(
        repository: context.read<RecordsRepository>(),
        uid: uid,
      ),
      child: const _RecordsView(),
    );
  }
}

class _RecordsView extends StatefulWidget {
  const _RecordsView();

  @override
  State<_RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends State<_RecordsView> {
  /// Consecutive cards overlap to form the design's stacked deck.
  static const _overlap = 16.0;
  static const _filters = ['All', 'Diagnoses', 'Medications', 'Labs'];

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  String? _firstName(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = context.select((AuthBloc b) => b.state.user.displayName);
    final cubit = context.read<RecordsCubit>();

    return Scaffold(
      backgroundColor: context.colors.surfaceMuted,
      extendBody: true,
      // Labelled rather than an icon-only FAB: "add a record" is the primary
      // job on this screen, and a bare glyph left patients hunting for it.
      // Lifted clear of the shell's bottom bar, which is drawn over this
      // screen rather than inside it.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: AppShell.bottomBarClearance(context)),
        child: FloatingActionButton.extended(
          onPressed: () => AppNav.openAddRecord(context),
          backgroundColor: AppColors.indigoFinal,
          foregroundColor: Colors.white,
          elevation: 8,
          icon: SvgPicture.asset(AppAssets.fabAdd, width: 14, height: 14),
          label: Text(
            'Add Record',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          RecordsAppBar(
            greeting: _greeting,
            name: _firstName(displayName),
            onAvatarTap: () => AppShell.of(context)?.goToTab(MediTab.profile),
            onSearch: () {},
          ),
          Expanded(
            child: BlocBuilder<RecordsCubit, RecordsState>(
              builder: (context, state) => SingleChildScrollView(
                // Clears the bottom bar and the FAB sitting above it, so the
                // last record can always be scrolled into view.
                padding: EdgeInsets.only(
                  top: 16,
                  bottom: AppShell.bottomBarClearance(context) + 88,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RecordsSearchField(
                        controller: _searchController,
                        onChanged: cubit.search,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RecordFilterChips(
                      filters: _filters,
                      selected: state.filter,
                      onSelected: cubit.selectFilter,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(),
                          const SizedBox(height: 16),
                          _RecordsBody(state: state, overlap: _overlap),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsBody extends StatelessWidget {
  const _RecordsBody({required this.state, required this.overlap});

  final RecordsState state;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (state.status == RecordsStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.status == RecordsStatus.error) {
      return const _MessageState('Could not load your records.');
    }
    if (state.records.isEmpty) {
      return const _MessageState(
        'No records yet. Tap + to add your first record.',
      );
    }
    final records = state.visibleRecords;
    if (records.isEmpty) {
      return const _MessageState('No records match your search.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Each card is pulled up over the previous one to form the design's
        // stacked deck.
        for (var i = 0; i < records.length; i++)
          Transform.translate(
            offset: Offset(0, -overlap * i),
            child: RecordCard(
              record: records[i].toEntry(),
              onTap: () => AppNav.openRecordDetails(context, records[i]),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Activity',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'See All',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: AppColors.indigoFinal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty / no-match / error message (none of these are in the design, but the
/// list can be empty, filtered to nothing, or fail to load).
class _MessageState extends StatelessWidget {
  const _MessageState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            height: 24 / 16,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
