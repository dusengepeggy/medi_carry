import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/theme/app_theme.dart';
import 'package:medi_carry/features/auth/bloc/auth/auth_bloc.dart';
import 'package:medi_carry/features/auth/data/auth_repository.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/app_user.dart';
import 'package:medi_carry/features/records/data/records_repository.dart';
import 'package:medi_carry/features/share/data/shares_repository.dart';
import 'package:medi_carry/features/share/view/share_records_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockAuthRepository authRepository;
  late FakeFirebaseFirestore firestore;

  setUp(() {
    authRepository = MockAuthRepository();
    firestore = FakeFirebaseFirestore();
    when(() => authRepository.user).thenAnswer(
      (_) => Stream<AppUser>.value(
        const AppUser(uid: 'u1', displayName: 'Sarah Johnson'),
      ),
    );
  });

  Future<void> pumpShare(WidgetTester tester) async {
    // Match the design's 390pt-wide phone frame so overflow surfaces.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<UserRepository>.value(value: MockUserRepository()),
          RepositoryProvider<RecordsRepository>.value(
              value: RecordsRepository(firestore: firestore)),
          RepositoryProvider<SharesRepository>.value(
              value: SharesRepository(firestore: firestore)),
        ],
        child: BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ShareRecordsScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders the header and quick share QR card', (tester) async {
    await pumpShare(tester);

    expect(find.text('Hi, Sarah'), findsOneWidget);
    expect(find.text('Share Records'), findsOneWidget);
    expect(find.text('In-Person Quick Share'), findsOneWidget);
    expect(find.text('Show QR'), findsOneWidget);
    expect(find.text('Scan a shared code'), findsOneWidget);
  });

  testWidgets('shows the granular category selection', (tester) async {
    await pumpShare(tester);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('Customize Sharing Access'), findsOneWidget);
    expect(find.text('Basic Profile & Blood Type'), findsOneWidget);
    expect(find.text('Allergies'), findsOneWidget);
    expect(find.text('Current Medications'), findsOneWidget);
    expect(find.text('Full Medical History'), findsOneWidget);
  });

  testWidgets('active shares starts empty with an explanatory message',
      (tester) async {
    await pumpShare(tester);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1400));
    await tester.pump();

    expect(find.text('Active Shares'), findsOneWidget);
    expect(
      find.textContaining('No active shares'),
      findsOneWidget,
    );
  });
}
