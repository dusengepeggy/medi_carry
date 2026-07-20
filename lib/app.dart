import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/biometric_service.dart';
import 'core/services/emergency_card_store.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/theme_mode_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/bloc/app_lock/app_lock_cubit.dart';
import 'features/auth/bloc/auth/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/view/auth_gate.dart';

/// Root widget. Repositories/services are injected so tests can supply fakes
/// without touching Firebase; `main.dart` supplies the real implementations.
class MediCarryApp extends StatelessWidget {
  const MediCarryApp({
    super.key,
    required this.authRepository,
    required this.userRepository,
    required this.secureStorage,
    required this.biometricService,
    required this.emergencyCardStore,
    required this.themeModeStore,
  });

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final SecureStorageService secureStorage;
  final BiometricService biometricService;
  final EmergencyCardStore emergencyCardStore;
  final ThemeModeStore themeModeStore;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: userRepository),
        RepositoryProvider.value(value: secureStorage),
        RepositoryProvider.value(value: biometricService),
        RepositoryProvider.value(value: emergencyCardStore),
        RepositoryProvider.value(value: themeModeStore),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(authRepository: authRepository)),
          BlocProvider(
            create: (_) => ThemeCubit(store: themeModeStore)..load(),
          ),
          BlocProvider(
            create: (_) => AppLockCubit(
              secureStorage: secureStorage,
              biometric: biometricService,
              emergencyCardStore: emergencyCardStore,
            ),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final themeMode = context.watch<ThemeCubit>().state;
    return MaterialApp(
      title: 'MediCarry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      scaffoldMessengerKey: messengerKey,
      home: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage ||
            prev.infoMessage != curr.infoMessage,
        listener: (context, state) {
          final message = state.errorMessage ?? state.infoMessage;
          if (message != null) {
            messengerKey.currentState
              ?..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<AuthBloc>().add(const AuthMessageCleared());
          }
        },
        child: const AuthGate(),
      ),
    );
  }
}
