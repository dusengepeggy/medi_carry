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
import '../bloc/cards_cubit.dart';
import '../models/insurance_card.dart';

/// Add / edit an insurance or patient-ID card, including a photo or PDF of the
/// physical card.
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key, this.existing});

  final InsuranceCard? existing;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerNameController;
  late final TextEditingController _memberNameController;
  late final TextEditingController _memberNumberController;
  late final TextEditingController _policyNumberController;
  late final TextEditingController _schemeController;
  late final TextEditingController _notesController;

  late InsuranceProvider _provider;
  late CardType _type;
  DateTime? _validFrom;
  DateTime? _validUntil;
  late List<StoredAttachment> _documents;

  bool _saving = false;
  bool _uploading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _providerNameController =
        TextEditingController(text: existing?.providerName ?? '');
    _memberNameController =
        TextEditingController(text: existing?.memberName ?? '');
    _memberNumberController =
        TextEditingController(text: existing?.memberNumber ?? '');
    _policyNumberController =
        TextEditingController(text: existing?.policyNumber ?? '');
    _schemeController = TextEditingController(text: existing?.scheme ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _provider = existing?.provider ?? InsuranceProvider.rssb;
    _type = existing?.type ?? CardType.insurance;
    _validFrom = existing?.validFrom;
    _validUntil = existing?.validUntil;
    _documents = [...?existing?.documents];
  }

  @override
  void dispose() {
    _providerNameController.dispose();
    _memberNameController.dispose();
    _memberNumberController.dispose();
    _policyNumberController.dispose();
    _schemeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickProvider() async {
    final picked = await showModalBottomSheet<InsuranceProvider>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _ProviderPicker(selected: _provider),
    );
    if (picked != null) setState(() => _provider = picked);
  }

  Future<void> _addDocument() async {
    final source = await AttachmentSourceSheet.show(
      context,
      title: 'Add a picture of the card',
    );
    if (source == null || !mounted) return;

    final picker = AttachmentPicker(storage: context.read<FileStorage>());
    setState(() => _uploading = true);
    try {
      final picked = await picker.pick(source);
      for (final document in picked) {
        final stored = await picker.upload(document, folder: 'cards');
        if (!mounted) return;
        setState(() {
          _documents = [
            ..._documents,
            StoredAttachment.fromStoredFile(stored, document.name),
          ];
        });
      }
    } on FileStorageException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _validFrom : _validUntil) ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
      helpText: isFrom ? 'Valid from' : 'Valid until',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _validFrom = picked;
      } else {
        _validUntil = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final cubit = context.read<CardsCubit>();
    final existing = widget.existing;
    final card = InsuranceCard(
      id: existing?.id ?? '',
      provider: _provider,
      providerName: _providerNameController.text.trim(),
      type: _type,
      memberName: _memberNameController.text.trim(),
      memberNumber: _memberNumberController.text.trim(),
      policyNumber: _policyNumberController.text.trim(),
      scheme: _schemeController.text.trim(),
      validFrom: _validFrom,
      validUntil: _validUntil,
      notes: _notesController.text.trim(),
      documents: _documents,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEditing) {
        await cubit.update(card);
      } else {
        await cubit.add(card);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage(_isEditing ? 'Card updated' : 'Card added');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save the card. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final storageReady = context.read<FileStorage>().isConfigured;
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
          _isEditing ? 'Edit Card' : 'Add Card',
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
              const MediLabel('CARD TYPE'),
              const SizedBox(height: 8),
              MediChoiceChips<CardType>(
                values: CardType.values,
                selected: _type,
                labelOf: (t) => t.label,
                onSelected: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 20),
              const MediLabel('PROVIDER / SCHEME'),
              const SizedBox(height: 8),
              MediTapField(
                value: _provider.label,
                icon: Icons.expand_more,
                onTap: _pickProvider,
              ),
              if (_provider == InsuranceProvider.other) ...[
                const SizedBox(height: 12),
                MediTextField(
                  controller: _providerNameController,
                  hint: 'Name of the provider',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the provider name'
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              const MediLabel('MEMBER / CARD NUMBER'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _memberNumberController,
                hint: 'The number on the card',
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter the number on the card'
                    : null,
              ),
              const SizedBox(height: 20),
              const MediLabel('MEMBER NAME'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _memberNameController,
                hint: 'Whose card is this?',
              ),
              const SizedBox(height: 20),
              const MediLabel('POLICY NUMBER (OPTIONAL)'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _policyNumberController,
                hint: 'e.g. POL-4471',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 20),
              const MediLabel('PLAN / CATEGORY (OPTIONAL)'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _schemeController,
                hint: 'e.g. Category 3, Gold',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MediLabel('VALID FROM'),
                        const SizedBox(height: 8),
                        MediTapField(
                          value: _validFrom == null
                              ? null
                              : InsuranceCard.formatDate(_validFrom!),
                          placeholder: 'Not set',
                          icon: Icons.calendar_today_outlined,
                          onTap: () => _pickDate(isFrom: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MediLabel('VALID UNTIL'),
                        const SizedBox(height: 8),
                        MediTapField(
                          value: _validUntil == null
                              ? null
                              : InsuranceCard.formatDate(_validUntil!),
                          placeholder: 'Not set',
                          icon: Icons.calendar_today_outlined,
                          onTap: () => _pickDate(isFrom: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const MediLabel('NOTES (OPTIONAL)'),
              const SizedBox(height: 8),
              MediTextField(
                controller: _notesController,
                hint: 'Co-pay, covered facilities, anything worth remembering',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              DocumentsField(
                label: 'CARD DOCUMENTS (IMAGE / PDF)',
                documents: _documents,
                uploading: _uploading,
                enabled: storageReady,
                addLabel: 'Add card photo or PDF',
                onAdd: _addDocument,
                onRemove: (d) => setState(
                  () => _documents = [..._documents]..remove(d),
                ),
              ),
              const SizedBox(height: 28),
              MediPrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Save Card',
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

/// Scrollable provider list. A sheet rather than a dropdown because there are
/// fourteen options with second-line descriptions.
class _ProviderPicker extends StatelessWidget {
  const _ProviderPicker({required this.selected});

  final InsuranceProvider selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose your provider',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: InsuranceProvider.values.length,
              itemBuilder: (context, i) {
                final provider = InsuranceProvider.values[i];
                return ListTile(
                  onTap: () => Navigator.of(context).pop(provider),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: provider.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.badge_outlined,
                      size: 20,
                      color: provider.accent,
                    ),
                  ),
                  title: Text(
                    provider.label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    provider.description,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  trailing: provider == selected
                      ? const Icon(Icons.check, size: 20)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
