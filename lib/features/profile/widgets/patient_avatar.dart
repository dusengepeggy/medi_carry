import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_assets.dart';
import '../bloc/profile_cubit.dart';

/// The patient's photo (a Cloudinary URL) with a graceful fallback to the
/// bundled placeholder — used wherever an avatar appears.
class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, this.photoUrl, required this.size});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url.isEmpty
            ? Image.asset(AppAssets.avatarPlaceholder, fit: BoxFit.cover)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    Image.asset(AppAssets.avatarPlaceholder, fit: BoxFit.cover),
              ),
      ),
    );
  }
}

/// [PatientAvatar] wired to the app-wide [ProfileCubit], so it follows the
/// signed-in patient's photo the moment it changes.
///
/// Use this anywhere the avatar is decoration on a chrome surface (app bars,
/// nav); pass an explicit URL to [PatientAvatar] only where the photo being
/// shown is not the signed-in user's, or is still being edited.
class LivePatientAvatar extends StatelessWidget {
  const LivePatientAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = context.select((ProfileCubit c) => c.state.photoUrl);
    return PatientAvatar(photoUrl: photoUrl, size: size);
  }
}
