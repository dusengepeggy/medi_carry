import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../bloc/medications_cubit.dart';
import '../models/medication.dart';
import 'add_medication_screen.dart';

/// The patient's medication list — every course, its dose times, and whether
/// reminders are armed for it.
///
/// Reached from the dashboard's "next medication" card, which only ever shows
/// one dose; this is where the whole regimen lives.
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Medications',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        backgroundColor: AppColors.indigoFinal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: BlocBuilder<MedicationsCubit, MedicationsState>(
          builder: (context, state) {
            if (state.status == MedicationsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == MedicationsStatus.error) {
              return const _Message('Could not load your medications.');
            }
            if (state.medications.isEmpty) {
              return const _Message(
                'No medications yet.\nAdd one to get dose reminders.',
              );
            }
            final now = DateTime.now();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                if (!state.remindersPermitted) ...[
                  _PermissionBanner(
                    onEnable: () =>
                        context.read<MedicationsCubit>().requestReminderPermission(),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final medication in state.currentAt(now)) ...[
                  _MedicationTile(medication: medication, now: now),
                  const SizedBox(height: 12),
                ],
                ...() {
                  final past = state.medications
                      .where((m) => !m.isCurrentAt(now))
                      .toList();
                  if (past.isEmpty) return <Widget>[];
                  return <Widget>[
                    const SizedBox(height: 12),
                    Text(
                      'NOT CURRENTLY TAKING',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final medication in past) ...[
                      _MedicationTile(medication: medication, now: now),
                      const SizedBox(height: 12),
                    ],
                  ];
                }(),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _openEditor(BuildContext context, {Medication? existing}) {
    final cubit = context.read<MedicationsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AddMedicationScreen(existing: existing),
        ),
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.medication, required this.now});

  final Medication medication;
  final DateTime now;

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<MedicationsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${medication.name}?'),
        content: const Text(
          'This deletes the medication and cancels its reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.delete(medication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final next = medication.dueDose(now);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (medication.dosage.isNotEmpty ||
                        medication.instructions.isNotEmpty)
                      Text(
                        [
                          if (medication.dosage.isNotEmpty) medication.dosage,
                          if (medication.instructions.isNotEmpty)
                            medication.instructions,
                        ].join(' • '),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      MedicationsScreen._openEditor(context,
                          existing: medication);
                    case 'delete':
                      _confirmDelete(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Remove')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final time in medication.times)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    time.label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  next == null
                      ? 'No upcoming dose'
                      : 'Next dose ${_relative(next, now)}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: medication.remindersEnabled,
                activeThumbColor: AppColors.indigoFinal,
                onChanged: (v) => context
                    .read<MedicationsCubit>()
                    .setRemindersEnabled(medication, v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "in 2 hours" / "due now" / "tomorrow at 8:00 AM".
  static String _relative(DateTime when, DateTime now) {
    final delta = when.difference(now);
    if (delta.isNegative) return 'due now';
    if (delta.inMinutes < 1) return 'due now';
    if (delta.inMinutes < 60) return 'in ${delta.inMinutes} min';
    if (delta.inHours < 24) {
      final h = delta.inHours;
      return 'in $h ${h == 1 ? 'hour' : 'hours'}';
    }
    return 'tomorrow at ${DoseTime(when.hour, when.minute).label}';
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppColors.onWarningSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications are off, so dose reminders will not appear.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.onWarningSurface,
              ),
            ),
          ),
          TextButton(onPressed: onEnable, child: const Text('Enable')),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            text,
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
