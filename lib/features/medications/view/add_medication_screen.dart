import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/widgets/medi_form_fields.dart';
import '../bloc/medications_cubit.dart';
import '../models/medication.dart';

/// Add / edit a medication, including the dose times its reminders fire at.
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key, this.existing});

  /// The medication being edited, or null when adding a new one.
  final Medication? existing;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _instructionsController;

  late List<DoseTime> _times;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _remindersEnabled;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _dosageController = TextEditingController(text: existing?.dosage ?? '');
    _instructionsController =
        TextEditingController(text: existing?.instructions ?? '');
    _times = [...?existing?.times];
    if (_times.isEmpty) _times = const [DoseTime(8, 0)];
    _startDate = existing?.startDate ?? DateTime.now();
    _endDate = existing?.endDate;
    _remindersEnabled = existing?.remindersEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Dose time',
    );
    if (picked == null) return;
    final time = DoseTime(picked.hour, picked.minute);
    if (_times.contains(time)) return;
    setState(() => _times = [..._times, time]..sort());
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: isStart ? 'Start date' : 'End date',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // An end date before the start would silently hide the course.
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_times.isEmpty) {
      _showMessage('Add at least one dose time so reminders can be set.');
      return;
    }

    setState(() => _saving = true);
    final cubit = context.read<MedicationsCubit>();
    // Captured before the screen pops, so the confirmation still shows.
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.existing;
    final medication = Medication(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      instructions: _instructionsController.text.trim(),
      times: _times,
      startDate: _startDate,
      endDate: _endDate,
      remindersEnabled: _remindersEnabled,
      active: existing?.active ?? true,
      lastTakenAt: existing?.lastTakenAt,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEditing) {
        await cubit.update(medication);
      } else {
        await cubit.add(medication);
      }
      // Asked for here, at the moment the patient has said they want to be
      // reminded — not at app start, where the request has no context. A
      // refusal is reported, because a medication saved with reminders on but
      // permission off would otherwise look armed and never fire.
      final remindersReady =
          !_remindersEnabled || await cubit.requestReminderPermission();

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              remindersReady
                  ? (_isEditing
                      ? 'Medication updated — reminders set'
                      : 'Medication added — reminders set')
                  : 'Saved, but notifications are off, so no reminder will '
                      'appear. Enable them for MediCarry in your phone '
                      'settings.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save the medication. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.close, color: colors.textPrimary),
        ),
        title: Text(
          _isEditing ? 'Edit Medication' : 'Add Medication',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const MediLabel('MEDICATION NAME'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _nameController,
                hint: 'e.g. Lisinopril',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the medication name'
                    : null,
              ),
              const SizedBox(height: 20),
              const MediLabel('DOSAGE'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _dosageController,
                hint: 'e.g. 10mg, 1 tablet',
              ),
              const SizedBox(height: 20),
              const MediLabel('INSTRUCTIONS'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _instructionsController,
                hint: 'e.g. Take with food',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const MediLabel('DOSE TIMES'),
              const SizedBox(height: 8),
              _DoseTimes(
                times: _times,
                onAdd: _addTime,
                onRemove: (t) =>
                    setState(() => _times = [..._times]..remove(t)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MediLabel('STARTS'),
                        const SizedBox(height: 8),
                        MediTapField(
                          value: _dateLabel(_startDate),
                          icon: Icons.calendar_today_outlined,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MediLabel('ENDS (OPTIONAL)'),
                        const SizedBox(height: 8),
                        MediTapField(
                          value: _endDate == null
                              ? null
                              : _dateLabel(_endDate!),
                          placeholder: 'Ongoing',
                          icon: Icons.calendar_today_outlined,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_endDate != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _endDate = null),
                    child: const Text('Clear end date'),
                  ),
                ),
              const SizedBox(height: 12),
              _ReminderToggle(
                value: _remindersEnabled,
                onChanged: (v) => setState(() => _remindersEnabled = v),
              ),
              const SizedBox(height: 28),
              MediPrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Add Medication',
                busy: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoseTimes extends StatelessWidget {
  const _DoseTimes({
    required this.times,
    required this.onAdd,
    required this.onRemove,
  });

  final List<DoseTime> times;
  final VoidCallback onAdd;
  final void Function(DoseTime time) onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final time in times)
          Container(
            padding: const EdgeInsets.only(left: 16, right: 4),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time.label,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: times.length == 1 ? null : () => onRemove(time),
                  tooltip: 'Remove dose time',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 16, color: colors.textMuted),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add time'),
          style: OutlinedButton.styleFrom(
            // Reads in both modes; navy disappeared against the dark canvas.
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.indigoFinal,
        title: Text(
          'Remind me',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          'A notification at each dose time. Works offline.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
