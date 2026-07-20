import 'package:equatable/equatable.dart';

/// The authenticated patient identity, derived from Firebase Auth.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  /// Sentinel for "no authenticated user".
  static const empty = AppUser(uid: '');

  bool get isEmpty => uid.isEmpty;
  bool get isNotEmpty => uid.isNotEmpty;

  @override
  List<Object?> get props => [uid, email, displayName, emailVerified];
}
