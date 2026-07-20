import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/config/firebase_config.dart';
import 'core/services/biometric_service.dart';
import 'core/services/emergency_card_store.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/theme_mode_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration lives in the untracked .env (see .env.example).
  await Env.load();

  await Firebase.initializeApp(
    options: FirebaseConfig.currentPlatform,
  );

  // Offline-first: cache Firestore reads locally so records resolve with no
  // connectivity (enabled by default on mobile; set explicitly for clarity).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(
    MediCarryApp(
      authRepository: AuthRepository(),
      userRepository: UserRepository(),
      secureStorage: SecureStorageService(),
      biometricService: BiometricService(),
      emergencyCardStore: EmergencyCardStore(),
      themeModeStore: ThemeModeStore(),
    ),
  );
}
