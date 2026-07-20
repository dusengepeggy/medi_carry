import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_shell.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../dashboard/widgets/medi_bottom_nav.dart' show MediTab;
import '../widgets/record_card.dart';
import '../widgets/record_filter_chips.dart';
import '../widgets/records_app_bar.dart';
import '../widgets/records_search_field.dart';

/// Medical Records — an implementation of the "Medical Records (Final)" Figma
/// frame (node 2:274).
///
/// The records are the design's sample content until the records feature is
/// built; search and filtering already operate on that list so the controls
/// behave rather than merely appear.
class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  /// Consecutive cards overlap to form the design's stacked deck.
  static const _overlap = 16.0;

  static const _filters = ['All', 'Diagnoses', 'Medications', 'Labs'];

  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _query = '';

  /// Placeholder records, mirroring the design's samples.
  static const _records = [
    RecordEntry(
      category: 'LAB RESULT',
      title: 'Comprehensive Metabolic Panel',
      subtitle: 'Nairobi Hospital Central Lab • Dr. J. Kamau',
      meta: 'Oct 24, 2023',
      icon: AppAssets.activityLab,
      iconSize: Size(18.057, 18),
      style: RecordCardStyle.lime,
    ),
    RecordEntry(
      category: 'MEDICATION',
      title: 'Amoxicillin 500mg',
      subtitle: '1 capsule every 8 hours for 7 days',
      meta: 'Active since Oct 10, 2023',
      icon: AppAssets.activityPrescription,
      iconSize: Size(20, 22),
      style: RecordCardStyle.navy,
      metaIcon: AppAssets.clock,
      metaIconSize: Size(15, 15),
    ),
    RecordEntry(
      category: 'DIAGNOSIS',
      title: 'Acute Bronchitis',
      subtitle: 'Aga Khan University Hospital',
      meta: 'Sep 15, 2023',
      icon: AppAssets.activityCheckup,
      style: RecordCardStyle.light,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Category each filter maps to, so the chips actually filter.
  static const _filterCategories = {
    'Diagnoses': 'DIAGNOSIS',
    'Medications': 'MEDICATION',
    'Labs': 'LAB RESULT',
  };

  List<RecordEntry> get _visibleRecords {
    final query = _query.trim().toLowerCase();
    return _records.where((r) {
      final category = _filterCategories[_selectedFilter];
      final matchesFilter = category == null || r.category == category;
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.subtitle.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
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
    final records = _visibleRecords;

    return Scaffold(
      backgroundColor: AppColors.indigoSurface,
      extendBody: true,
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppColors.indigoFinal,
          elevation: 8,
          shape: const CircleBorder(),
          child: SvgPicture.asset(AppAssets.fabAdd, width: 14, height: 14),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 136),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RecordsSearchField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RecordFilterChips(
                    filters: _filters,
                    selected: _selectedFilter,
                    onSelected: (f) => setState(() => _selectedFilter = f),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(),
                        const SizedBox(height: 16),
                        if (records.isEmpty)
                          const _EmptyState()
                        else
                          // Each card is pulled up over the previous one to
                          // form the design's stacked deck.
                          for (var i = 0; i < records.length; i++)
                            Transform.translate(
                              offset: Offset(0, -_overlap * i),
                              child: RecordCard(
                                record: records[i],
                                onTap: () => AppNav.openRecordDetails(context),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              color: AppColors.navy,
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

/// Not in the design, but the filters and search can empty the list.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'No records match your search.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.navy.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
