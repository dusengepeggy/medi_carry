import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/profile/bloc/profile_cubit.dart';

/// A [UserRepository] over an in-memory Firestore — enough for trees that only
/// need [ProfileCubit] to resolve to "no profile document yet".
UserRepository fakeUserRepository([FakeFirebaseFirestore? firestore]) =>
    UserRepository(firestore: firestore ?? FakeFirebaseFirestore());

/// The blocs every authenticated screen expects to find above it: the signed-in
/// identity, and the profile document that drives avatars and greetings.
///
/// Kept here so a new app-wide bloc is added to the test trees in one place
/// rather than in every widget test.
Widget withMediBlocs({
  required AuthRepository authRepository,
  required UserRepository userRepository,
  required Widget child,
}) =>
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository: authRepository)),
        BlocProvider(
          create: (_) => ProfileCubit(
            authRepository: authRepository,
            userRepository: userRepository,
          ),
        ),
      ],
      child: child,
    );
