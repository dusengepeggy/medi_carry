import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/models/patient_profile.dart';
import '../widgets/edit_profile_fields.dart';

/// Edit Profile — an implementation of the "Edit Profile" Figma frame
/// (node 25:447).
///
/// Loads the signed-in patient's profile, lets them edit it, and persists the
/// result to Firestore. Emergency contact details live here because the
/// Emergency Info feature surfaces them.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  /// The profile being edited. Callers pass the already-loaded document so the
  /// form can be populated without a second fetch.
  final PatientProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _genders = ['Female', 'Male', 'Other', 'Prefer not to say'];

  late final TextEditingController _nameController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;

  DateTime? _dateOfBirth;
  String? _bloodType;
  String? _gender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.fullName);
    _contactNameController =
        TextEditingController(text: p.emergencyContactName ?? '');
    _contactPhoneController =
        TextEditingController(text: p.emergencyContactPhone ?? '');
    _dateOfBirth = p.dateOfBirth == null ? null : DateTime.tryParse(p.dateOfBirth!);
    _bloodType = _bloodTypes.contains(p.bloodType) ? p.bloodType : null;
    _gender = _genders.contains(p.gender) ? p.gender : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  /// ISO-8601 date (`yyyy-MM-dd`), matching how the profile stores it.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter your name.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final p = widget.profile;
    final updated = PatientProfile(
      uid: p.uid,
      fullName: name,
      email: p.email,
      patientId: p.patientId,
      allergies: p.allergies,
      chronicConditions: p.chronicConditions,
      bloodType: _bloodType,
      dateOfBirth: _dateOfBirth == null ? null : _isoDate(_dateOfBirth!),
      gender: _gender,
      emergencyContactName: _trimmedOrNull(_contactNameController.text),
      emergencyContactPhone: _trimmedOrNull(_contactPhoneController.text),
    );

    try {
      await context.read<UserRepository>().updateProfile(updated);
      if (!mounted) return;
      _showMessage('Profile saved');
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Could not save your profile. Please try again.',
          isError: true);
    }
  }

  /// The design's success toast, as a themed SnackBar.
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.danger : AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isError) ...[
                SvgPicture.asset(AppAssets.editCheck, width: 20, height: 20),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  message,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _EditAppBar(
              isSaving: _isSaving,
              onBack: () => Navigator.of(context).maybePop(),
              onSave: _isSaving ? null : _save,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 56),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      children: [
                        _PictureSection(
                          name: _nameController.text.trim().isEmpty
                              ? widget.profile.fullName
                              : _nameController.text.trim(),
                          patientId: widget.profile.patientId,
                          onChangePhoto: () {},
                        ),
                        const SizedBox(height: 32),
                        _FormCard(
                          heading: 'PERSONAL INFORMATION',
                          children: [
                            EditTextField(
                              label: 'Full Name',
                              icon: AppAssets.profilePerson,
                              iconSize: const Size(16, 16),
                              controller: _nameController,
                              hintText: 'Your full name',
                            ),
                            const SizedBox(height: 16),
                            EditDateField(
                              label: 'Date of Birth',
                              value: _dateOfBirth,
                              onChanged: (d) =>
                                  setState(() => _dateOfBirth = d),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FormCard(
                          heading: 'HEALTH DATA',
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: EditDropdownField(
                                    label: 'Blood Type',
                                    icon: AppAssets.editBlood,
                                    iconSize: const Size(28, 20),
                                    value: _bloodType,
                                    options: _bloodTypes,
                                    onChanged: (v) =>
                                        setState(() => _bloodType = v),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: EditDropdownField(
                                    label: 'Gender',
                                    icon: AppAssets.editGender,
                                    iconSize: const Size(29, 20),
                                    value: _gender,
                                    options: _genders,
                                    onChanged: (v) =>
                                        setState(() => _gender = v),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _EmergencyContactCard(
                          nameController: _contactNameController,
                          phoneController: _contactPhoneController,
                        ),
                        const SizedBox(height: 16),
                        const _DeleteAccountButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAppBar extends StatelessWidget {
  const _EditAppBar({required this.isSaving, this.onBack, this.onSave});

  final bool isSaving;
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.canvas,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onBack,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  icon: SvgPicture.asset(
                    AppAssets.editBack,
                    width: 16,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'Edit Profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onSave,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.saveButton,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.saveButtonText),
                    ),
                  )
                : Text(
                    'SAVE',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.saveButtonText,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PictureSection extends StatelessWidget {
  const _PictureSection({
    required this.name,
    required this.patientId,
    this.onChangePhoto,
  });

  final String name;
  final String patientId;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  // Stand-in until patient profile photos are wired up.
                  child: Image.asset(
                    AppAssets.avatarPlaceholder,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onChangePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.indigo,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      AppAssets.editCamera,
                      width: 16.667,
                      height: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'MediCarry ID: $patientId',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w500,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.heading, required this.children});

  final String heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1F36).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditSectionHeading(heading),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.nameController,
    required this.phoneController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EditSectionHeading('EMERGENCY CONTACT', onDark: true),
          const SizedBox(height: 16),
          EditTextField(
            label: 'Primary Contact Name',
            icon: AppAssets.editContact,
            iconSize: const Size(28, 20),
            controller: nameController,
            style: EditFieldStyle.dark,
            hintText: 'Who should we call?',
          ),
          const SizedBox(height: 16),
          EditTextField(
            label: 'Emergency Phone',
            icon: AppAssets.editPhone,
            iconSize: const Size(30, 18),
            controller: phoneController,
            style: EditFieldStyle.dark,
            keyboardType: TextInputType.phone,
            hintText: '+254 700 000 000',
          ),
        ],
      ),
    );
  }
}

/// The design reserves a 48px slot for this but specifies no styling, so it is
/// rendered as a restrained destructive action with a confirmation step —
/// deleting medical records is irreversible.
class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all medical records '
          'stored in MediCarry. This cannot be undone.',
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
      if (!context.mounted) return;
      // Account deletion needs a re-authentication flow and a cascading
      // records wipe; not implemented yet, so say so rather than pretend.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion is not available yet.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () => _confirm(context),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Delete Account',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
