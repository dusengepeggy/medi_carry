import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/config/firebase_config.dart';
import 'core/services/biometric_service.dart';
import 'core/services/cloudinary_storage.dart';
import 'core/services/emergency_card_store.dart';
import 'core/services/notification_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/theme_mode_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'features/cards/data/cards_repository.dart';
import 'features/medications/data/medications_repository.dart';
import 'features/records/data/records_repository.dart';
import 'features/share/data/shares_repository.dart';

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

  // Reminders are scheduled on-device, so the plugin has to be ready before
  // any medication stream emits. A failure here is swallowed by the service
  // itself — a phone that cannot post notifications must still run the app.
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MediCarryApp(
      authRepository: AuthRepository(),
      userRepository: UserRepository(),
      secureStorage: SecureStorageService(),
      biometricService: BiometricService(),
      emergencyCardStore: EmergencyCardStore(),
      themeModeStore: ThemeModeStore(),
      recordsRepository: RecordsRepository(),
      sharesRepository: SharesRepository(),
      medicationsRepository: MedicationsRepository(),
      cardsRepository: CardsRepository(),
      fileStorage: CloudinaryStorage(),
      notificationService: notificationService,
    ),
  );
}
