import 'package:flutter/material.dart';

import '../../../core/theme/app_assets.dart';

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
