import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/stored_attachment.dart';
import '../../../core/services/attachment_picker.dart';
import '../../../core/services/file_storage.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/widgets/attachment_source_sheet.dart';
import '../../../core/widgets/documents_field.dart';
import '../../../core/widgets/medi_form_fields.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../data/records_repository.dart';
import '../models/medical_record.dart';

/// Add Record — a real create form writing to `users/{uid}/records`.
///
/// Designed in the established system (no Figma frame exists for the form).
class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _providerController = TextEditingController();
  final _detailController = TextEditingController();
  final _notesController = TextEditingController();

  RecordCategory _category = RecordCategory.labResult;
  DateTime _date = DateTime.now();
  final List<RecordAttachment> _attachments = [];
  bool _saving = false;
  bool _uploading = false;

  /// Camera, gallery or file, then upload each pick to storage. Attachments
  /// appear as they finish so a slow connection still shows progress.
  Future<void> _pickAttachments() async {
    final source = await AttachmentSourceSheet.show(
      context,
      title: 'Attach to this record',
    );
    if (source == null || !mounted) return;

    final picker = AttachmentPicker(storage: context.read<FileStorage>());
    setState(() => _uploading = true);
    try {
      final picked = await picker.pick(source);
      for (final document in picked) {
        final stored = await picker.upload(document, folder: 'records');
        if (!mounted) return;
        setState(() {
          _attachments.add(
            StoredAttachment.fromStoredFile(stored, document.name),
          );
        });
      }
    } on FileStorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _providerController.dispose();
    _detailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Record date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  static String _dateLabel(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = context.read<AuthBloc>().state.user.uid;
    if (uid.isEmpty) return;

    setState(() => _saving = true);
    final record = MedicalRecord(
      id: '',
      category: _category,
      title: _titleController.text.trim(),
      provider: _providerController.text.trim(),
      detail: _detailController.text.trim(),
      notes: _notesController.text.trim(),
      date: _date,
      createdAt: DateTime.now(),
      attachments: List.of(_attachments),
    );
    try {
      await context.read<RecordsRepository>().add(uid, record);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record added')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the record.')),
      );
    }
  }

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
          'Add New Record',
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
              const MediLabel('CATEGORY'),
              const SizedBox(height: 8),
              MediChoiceChips<RecordCategory>(
                values: RecordCategory.values,
                selected: _category,
                labelOf: (c) => c.title,
                onSelected: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 20),
              const MediLabel('TITLE'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _titleController,
                hint: 'e.g. Comprehensive Metabolic Panel',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 20),
              const MediLabel('PROVIDER / FACILITY'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _providerController,
                hint: 'e.g. Nairobi Hospital • Dr. J. Kamau',
              ),
              const SizedBox(height: 20),
              const MediLabel('DETAIL'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _detailController,
                hint: 'Dosage, result, or summary',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const MediLabel('DATE'),
              const SizedBox(height: 8),
              MediTapField(
                value: _dateLabel(_date),
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),
              const MediLabel('NOTES (OPTIONAL)'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _notesController,
                hint: 'Clinician notes',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              DocumentsField(
                label: 'ATTACHMENTS (IMAGES / PDF)',
                documents: _attachments,
                uploading: _uploading,
                enabled: context.read<FileStorage>().isConfigured,
                addLabel: 'Add file',
                onAdd: _pickAttachments,
                onRemove: (a) => setState(() => _attachments.remove(a)),
              ),
              const SizedBox(height: 28),
              MediPrimaryButton(
                label: 'Save Record',
                busy: _saving || _uploading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
