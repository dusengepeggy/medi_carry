import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_assets.dart';
import '../../../app/app_routes.dart';
import '../../../core/services/emergency_card_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/models/patient_profile.dart';
import '../widgets/appearance_toggle.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_option_card.dart';

/// User Profile — an implementation of the "User Profile" Figma frame
/// (node 25:339).
///
/// The name and patient ID come from the signed-in patient's Firestore
/// profile rather than the design's sample values. The four settings
/// destinations do not exist yet, so their rows are inert for now.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);

    return Scaffold(
      backgroundColor: context.colors.canvas,
      extendBody: true,
      body: Column(
        children: [
          const _ProfileAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: StreamBuilder<PatientProfile?>(
                    stream: user.isEmpty
                        ? const Stream<PatientProfile?>.empty()
                        : context.read<UserRepository>().watchProfile(user.uid),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      // Keep the offline emergency snapshot current, so it is
                      // readable while locked and without a network.
                      if (profile != null) {
                        context.read<EmergencyCardStore>().save(profile);
                      }
                      final name = profile?.fullName.isNotEmpty ?? false
                          ? profile!.fullName
                          : (user.displayName?.trim().isNotEmpty ?? false)
                              ? user.displayName!
                              : 'MediCarry Patient';
                      return Column(
                        children: [
                          ProfileHeader(
                            name: name,
                            patientId: profile?.patientId,
                            photoUrl: profile?.photoUrl,
                            onEditPhoto: profile == null
                                ? null
                                : () => _openEditProfile(context, profile),
                          ),
                          const SizedBox(height: 32),
                          _OptionsGrid(
                            onPersonalInformation: profile == null
                                ? null
                                : () => _openEditProfile(context, profile),
                          ),
                          const SizedBox(height: 16),
                          const AppearanceToggle(),
                          const SizedBox(height: 16),
                          const _SignOutButton(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The profile stream refreshes this screen after a save, so the result of
  /// the edit does not need to be applied by hand.
  void _openEditProfile(BuildContext context, PatientProfile profile) {
    AppNav.openEditProfile(context, profile);
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.canvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.avatarBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.avatarRing, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppAssets.avatarPlaceholder,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MediCarry',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  icon: SvgPicture.asset(
                    AppAssets.notifications,
                    width: 18,
                    height: 18,
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

class _OptionsGrid extends StatelessWidget {
  const _OptionsGrid({this.onPersonalInformation});

  /// Null until the patient's profile has loaded, since Edit Profile needs it.
  final VoidCallback? onPersonalInformation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileOptionCard(
          icon: AppAssets.profilePerson,
          iconSize: const Size(16, 16),
          accent: AppColors.olive,
          title: 'Personal Information',
          description: 'Update your name, age, and records',
          onTap: onPersonalInformation,
        ),
        const SizedBox(height: 16),
        const ProfileOptionCard(
          icon: AppAssets.profileInsurance,
          iconSize: Size(16, 20),
          accent: AppColors.indigo,
          title: 'Health Insurance',
          description: 'Manage providers and policy details',
        ),
        const SizedBox(height: 16),
        const ProfileOptionCard(
          icon: AppAssets.profileBell,
          iconSize: Size(16, 20),
          accent: AppColors.slateGray,
          title: 'Notification Settings',
          description: 'Alerts for medication and appointments',
        ),
        const SizedBox(height: 16),
        const ProfileOptionCard(
          icon: AppAssets.profileSecurity,
          iconSize: Size(16, 21),
          accent: AppColors.danger,
          title: 'Security',
          description: 'Password, FaceID, and data privacy',
        ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () =>
            context.read<AuthBloc>().add(const AuthSignOutRequested()),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppAssets.profileLogout, width: 18, height: 18),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w700,
                color: context.colors.canvas,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
