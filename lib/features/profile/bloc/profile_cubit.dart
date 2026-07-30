import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/models/app_user.dart';
import '../../auth/models/patient_profile.dart';

part 'profile_state.dart';

/// The signed-in patient's profile document, streamed app-wide.
///
/// Every avatar and name in the app reads from this one cubit, so changing the
/// photo on Edit Profile updates the dashboard, records and share headers
/// immediately — previously each of those rendered a bundled placeholder and
/// only the Profile tab knew the real photo.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _users = userRepository,
        super(const ProfileState()) {
    _authSubscription = authRepository.user.listen(_onUserChanged);
  }

  final UserRepository _users;

  late final StreamSubscription<AppUser> _authSubscription;
  StreamSubscription<PatientProfile?>? _profileSubscription;
  String _uid = '';

  void _onUserChanged(AppUser user) {
    if (user.uid == _uid) return;
    _uid = user.uid;
    _profileSubscription?.cancel();
    _profileSubscription = null;

    if (user.isEmpty) {
      emit(const ProfileState(status: ProfileStatus.signedOut));
      return;
    }

    // A fresh state rather than copyWith, so the previous account's photo is
    // never briefly shown to the next one.
    emit(const ProfileState(status: ProfileStatus.loading));
    _profileSubscription = _users.watchProfile(user.uid).listen(
          (profile) => emit(
            ProfileState(status: ProfileStatus.ready, profile: profile),
          ),
          onError: (_) => emit(state.copyWith(status: ProfileStatus.error)),
        );
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _profileSubscription?.cancel();
    return super.close();
  }
}
