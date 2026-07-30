import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/attachment_picker.dart';
import '../../../core/services/file_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../auth/data/user_repository.dart';

/// What the patient chose to do with their photo.
enum _PhotoChoice { camera, gallery, remove }

/// Changing the patient's profile photo, in one place.
///
/// Persists the new photo **as soon as it is picked** rather than waiting for
/// a Save elsewhere on the screen: the photo lives in its own Firestore field,
/// and a patient who picks a picture and then backs out has every reason to
/// expect it to have stuck.
abstract final class ProfilePhotoActions {
  ProfilePhotoActions._();

  /// Prompts for a source, uploads, and writes the result to the profile.
  ///
  /// Returns the new photo URL, null if the photo was removed, or
  /// [currentPhotoUrl] unchanged if the patient backed out or it failed.
  static Future<String?> change(
    BuildContext context, {
    required String uid,
    required String? currentPhotoUrl,
  }) async {
    if (uid.isEmpty) return currentPhotoUrl;

    final storage = context.read<FileStorage>();
    if (!storage.isConfigured) {
      _tell(context, 'Photo uploads are unavailable — storage is not '
          'configured.');
      return currentPhotoUrl;
    }

    final choice = await _ask(
      context,
      hasPhoto: (currentPhotoUrl ?? '').trim().isNotEmpty,
    );
    if (choice == null || !context.mounted) return currentPhotoUrl;

    final users = context.read<UserRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (choice == _PhotoChoice.remove) {
      try {
        await users.updatePhotoUrl(uid, null);
        _show(messenger, 'Profile photo removed');
        return null;
      } catch (_) {
        _show(messenger, 'Could not remove the photo. Please try again.');
        return currentPhotoUrl;
      }
    }

    final picker = AttachmentPicker(storage: storage);
    final picked = await picker.pick(
      choice == _PhotoChoice.camera
          ? AttachmentSource.camera
          : AttachmentSource.gallery,
      allowMultiple: false,
    );
    if (picked.isEmpty || !context.mounted) return currentPhotoUrl;

    // The upload blocks, so the patient gets a spinner rather than a screen
    // that looks like it ignored the tap.
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(_showBusy(context));
    try {
      final stored = await picker.upload(picked.single, folder: 'avatars');
      await users.updatePhotoUrl(uid, stored.url);
      navigator.pop();
      _show(messenger, 'Profile photo updated');
      return stored.url;
    } on FileStorageException catch (e) {
      navigator.pop();
      _show(messenger, e.message);
      return currentPhotoUrl;
    } catch (_) {
      navigator.pop();
      _show(messenger, 'Could not update the photo. Please try again.');
      return currentPhotoUrl;
    }
  }

  static Future<void> _showBusy(BuildContext context) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

  static void _show(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void _tell(BuildContext context, String message) =>
      _show(ScaffoldMessenger.of(context), message);

  static Future<_PhotoChoice?> _ask(
    BuildContext context, {
    required bool hasPhoto,
  }) =>
      showModalBottomSheet<_PhotoChoice>(
        context: context,
        backgroundColor: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profile photo',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: sheetContext.colors.textPrimary,
                    ),
                  ),
                ),
              ),
              _Option(
                icon: Icons.photo_camera_outlined,
                label: 'Take a photo',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoChoice.camera),
              ),
              _Option(
                icon: Icons.photo_library_outlined,
                label: 'Choose from photos',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoChoice.gallery),
              ),
              if (hasPhoto)
                _Option(
                  icon: Icons.delete_outline,
                  label: 'Remove photo',
                  destructive: true,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PhotoChoice.remove),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = destructive ? AppColors.danger : colors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.danger.withValues(alpha: 0.1)
              : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: tint),
      ),
      title: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: tint,
        ),
      ),
    );
  }
}
