import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/features/auth/data/user_repository.dart';
import 'package:medi_carry/features/auth/models/patient_profile.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepository users;

  const profile = PatientProfile(
    uid: 'u1',
    fullName: 'Sarah Johnson',
    email: 'sarah@example.com',
    patientId: 'MC-8829-41',
    bloodType: 'O+',
    allergies: ['Penicillin'],
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    users = UserRepository(firestore: firestore);
    await users.createProfile(profile);
  });

  test('updatePhotoUrl writes the photo on its own', () async {
    await users.updatePhotoUrl('u1', 'https://cdn/avatar.jpg');

    final saved = await users.fetchProfile('u1');
    expect(saved!.photoUrl, 'https://cdn/avatar.jpg');
  });

  test('updatePhotoUrl leaves every other field untouched', () async {
    await users.updatePhotoUrl('u1', 'https://cdn/avatar.jpg');

    final saved = await users.fetchProfile('u1');
    expect(saved!.fullName, 'Sarah Johnson');
    expect(saved.patientId, 'MC-8829-41');
    expect(saved.bloodType, 'O+');
    expect(saved.allergies, ['Penicillin']);
  });

  test('passing null clears the photo', () async {
    await users.updatePhotoUrl('u1', 'https://cdn/avatar.jpg');
    await users.updatePhotoUrl('u1', null);

    final saved = await users.fetchProfile('u1');
    expect(saved!.photoUrl, isNull);
    // Clearing the photo must not take the rest of the profile with it.
    expect(saved.fullName, 'Sarah Johnson');
  });

  test(
      'REGRESSION: a photo set on its own survives a later whole-profile save '
      'that did not know about it', () async {
    // The photo used to be held in Edit Profile's local state and only written
    // on Save, so picking one and backing out lost it. It is now written
    // immediately — and a subsequent profile save must not clobber it.
    await users.updatePhotoUrl('u1', 'https://cdn/avatar.jpg');

    final current = await users.fetchProfile('u1');
    await users.updateProfile(current!.copyWith(fullName: 'Sarah J'));

    final saved = await users.fetchProfile('u1');
    expect(saved!.fullName, 'Sarah J');
    expect(saved.photoUrl, 'https://cdn/avatar.jpg');
  });
}
