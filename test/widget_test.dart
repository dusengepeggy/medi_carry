// Smoke test: with no authenticated user, MediCarry boots to the Login screen.
// All external dependencies (Firebase-backed repositories, secure storage,
// biometrics) are mocked so the test needs no live Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/app.dart';
import 'package:medi_carry/core/services/biometric_service.dart';
import 'package:medi_carry/core/services/emergency_card_store.dart';
import 'package:medi_carry/core/services/secure_storage_service.dart';
import 'package:medi_carry/core/services/theme_mode_store.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockSecureStorage extends Mock implements SecureStorageService {}

class MockBiometricService extends Mock implements BiometricService {}

class MockEmergencyCardStore extends Mock implements EmergencyCardStore {}

class MockThemeModeStore extends Mock implements ThemeModeStore {}

void main() {
  testWidgets('boots to the Login screen when signed out', (tester) async {
    final authRepository = MockAuthRepository();
    final secureStorage = MockSecureStorage();
    final emergencyCardStore = MockEmergencyCardStore();
    final themeModeStore = MockThemeModeStore();
    when(() => themeModeStore.read()).thenAnswer((_) async => ThemeMode.system);

    when(() => authRepository.user)
        .thenAnswer((_) => Stream<AppUser>.value(AppUser.empty));
    when(() => secureStorage.clear()).thenAnswer((_) async {});
    when(() => emergencyCardStore.clear()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MediCarryApp(
        authRepository: authRepository,
        userRepository: MockUserRepository(),
        secureStorage: secureStorage,
        biometricService: MockBiometricService(),
        emergencyCardStore: emergencyCardStore,
        themeModeStore: themeModeStore,
      ),
    );
    // Let the auth stream emit and the gate resolve to unauthenticated.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Secure Health Portfolio Access'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
