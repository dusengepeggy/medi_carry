import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/file_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
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

  static String _kindFor(String? extension) {
    final ext = (extension ?? '').toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) {
      return 'image';
    }
    if (ext == 'pdf') return 'pdf';
    return 'raw';
  }

  Future<void> _pickAttachments() async {
    final storage = context.read<FileStorage>();
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;
        final stored = await storage.upload(
          path,
          folder: 'records',
          kind: _kindFor(file.extension),
        );
        _attachments.add(RecordAttachment(
          url: stored.url,
          name: file.name,
          kind: stored.kind,
        ));
      }
    } on FileStorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
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
              _Label('CATEGORY'),
              const SizedBox(height: 8),
              _CategoryPicker(
                value: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 20),
              _Label('TITLE'),
              const SizedBox(height: 8),
              _Field(
                controller: _titleController,
                hint: 'e.g. Comprehensive Metabolic Panel',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 20),
              _Label('PROVIDER / FACILITY'),
              const SizedBox(height: 8),
              _Field(
                controller: _providerController,
                hint: 'e.g. Nairobi Hospital • Dr. J. Kamau',
              ),
              const SizedBox(height: 20),
              _Label('DETAIL'),
              const SizedBox(height: 8),
              _Field(
                controller: _detailController,
                hint: 'Dosage, result, or summary',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              _Label('DATE'),
              const SizedBox(height: 8),
              _DateField(date: _date, onTap: _pickDate),
              const SizedBox(height: 20),
              _Label('NOTES (OPTIONAL)'),
              const SizedBox(height: 8),
              _Field(
                controller: _notesController,
                hint: 'Clinician notes',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              _AttachmentsField(
                attachments: _attachments,
                uploading: _uploading,
                enabled: context.read<FileStorage>().isConfigured,
                onAdd: _pickAttachments,
                onRemove: (a) => setState(() => _attachments.remove(a)),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: (_saving || _uploading) ? null : _save,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Save Record',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final RecordCategory value;
  final ValueChanged<RecordCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in RecordCategory.values)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: c == value
                    ? AppColors.navy
                    : context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                c.title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c == value ? Colors.white : context.colors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                color: context.colors.textPrimary,
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 18, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AttachmentsField extends StatelessWidget {
  const _AttachmentsField({
    required this.attachments,
    required this.uploading,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<RecordAttachment> attachments;
  final bool uploading;
  final bool enabled;
  final VoidCallback onAdd;
  final void Function(RecordAttachment) onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('ATTACHMENTS (IMAGES / PDF)'),
        const SizedBox(height: 8),
        if (!enabled)
          Text(
            'File uploads are unavailable — Cloudinary is not configured.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: colors.textMuted,
            ),
          )
        else ...[
          for (final a in attachments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      a.isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(a),
                      icon: Icon(Icons.close, size: 18, color: colors.textMuted),
                    ),
                  ],
                ),
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
            label: Text(uploading ? 'Uploading…' : 'Add file'),
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.hankenGrotesk(fontSize: 16, color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          color: colors.textMuted,
        ),
        filled: true,
        fillColor: colors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.colors.textSecondary,
      ),
    );
  }
}
