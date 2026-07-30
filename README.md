# MediCarry

A secure, offline-first personal health record (PHR) mobile application built with Flutter
and Firebase.

MediCarry lets patients consolidate their medical records, track medication schedules with
on-device reminders, carry digital insurance cards, keep life-saving emergency information
available without a network connection, and share selected records with clinicians through
PIN-encrypted QR codes or PDF summaries.

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
  - [1. Prerequisites](#1-prerequisites)
  - [2. Clone the repository](#2-clone-the-repository)
  - [3. Create the Firebase project](#3-create-the-firebase-project)
  - [4. Enable authentication providers](#4-enable-authentication-providers)
  - [5. Create the Firestore database](#5-create-the-firestore-database)
  - [6. Register the Android SHA-1 fingerprint](#6-register-the-android-sha-1-fingerprint)
  - [7. Set up Cloudinary](#7-set-up-cloudinary)
  - [8. Create your .env file](#8-create-your-env-file)
  - [9. Deploy the security rules](#9-deploy-the-security-rules)
  - [10. Run the app](#10-run-the-app)
- [Building a release APK](#building-a-release-apk)
- [Running the tests](#running-the-tests)
- [Project structure](#project-structure)
- [Database structure](#database-structure)
- [Security rules](#security-rules)
- [Troubleshooting](#troubleshooting)

---

## Features

- **Three-step onboarding** — account credentials, medical profile with a generated Patient
  ID (e.g. `MC-8829-41`), and app-lock setup.
- **Two authentication methods** — email/password with verification and password reset, plus
  Google Sign-In.
- **App lock** — biometric (Face ID / Touch ID / fingerprint) or 4-digit PIN, with the PIN
  stored only as a salted hash.
- **Medical records** — create, browse, search and filter across five categories (lab result,
  medication, diagnosis, imaging, vitals) with image and PDF attachments.
- **Medication tracker** — multiple daily dose times, automatic next-dose computation and
  scheduled local notifications.
- **Insurance cards wallet** — Rwandan schemes (RSSB, Mutuelle de Santé / CBHI, RAMA, MMI)
  and private insurers, with card photos and validity tracking.
- **Emergency info** — blood type, allergies, chronic conditions and emergency contacts
  cached on-device and readable with no connectivity.
- **Encrypted sharing** — AES-GCM encryption with PBKDF2 key derivation from a 4-digit PIN,
  delivered as a QR code or a generated PDF, with revocable share grants.
- **Offline-first** — Firestore local persistence means records, medications and cards all
  resolve without a network connection.
- **Theming** — light, dark and system modes, persisted across restarts.


## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.41 · Dart 3.11 |
| State management | BLoC / Cubit (`flutter_bloc`, `equatable`) |
| Authentication | Firebase Authentication (email/password + Google) |
| Database | Cloud Firestore with offline persistence |
| File storage | Cloudinary (unsigned uploads) |
| Local secure storage | `flutter_secure_storage` (Android KeyStore / iOS Keychain) |
| Cryptography | `pointycastle`, `encrypt`, `crypto` (AES-GCM + PBKDF2) |
| Notifications | `flutter_local_notifications` |
| Testing | `flutter_test`, `bloc_test`, `mocktail`, `fake_cloud_firestore` |

---

## Getting started

Follow these steps in order. Steps 3–9 are one-time setup; after that you only need
step 10 to run the app.

### 1. Prerequisites

Install the following, then verify your toolchain:

| Tool | Version used |
|---|---|
| Flutter SDK | 3.41.9 (stable) |
| Dart SDK | 3.11.5 (bundled with Flutter) |
| Android SDK | 36.1 (build-tools 36.1.0) |
| JDK | 21.0.4 |
| Firebase CLI | latest |
| IDE | VS Code or Android Studio |

```bash
flutter doctor -v
```

Resolve anything `flutter doctor` flags before continuing. You also need an Android
emulator or a physical device with USB debugging enabled:

```bash
flutter devices
```

> MediCarry is a **mobile** application. Do not run it as a web or desktop build.

### 2. Clone the repository

```bash
git clone https://github.com/dusengepeggy/Medi-carry.git
cd Medi-carry
flutter pub get
```

### 3. Create the Firebase project

1. Go to the [Firebase console](https://console.firebase.google.com/) and click
   **Add project**.
2. Name it (for example `medicarry`) and finish the wizard.
3. Inside the project, register an **Android** app:
   - Package name: `com.example.medi_carry` (or your own — it must match the
     `applicationId` in `android/app/build.gradle.kts`).
   - Register the app, then **skip** downloading `google-services.json`. This project reads
     its Firebase configuration from `.env` instead (see step 8), so that file is not
     required and is git-ignored.
4. If you are also targeting iOS, register an **iOS** app the same way and note the bundle
   ID.

Leave the console open — you will copy values from **Project settings → Your apps** in
step 8.

### 4. Enable authentication providers

In **Build → Authentication → Sign-in method**, enable **both**:

- **Email/Password**
- **Google** — set a project support email when prompted.

Enabling the Google provider automatically creates the OAuth client IDs you will need in
step 8. Find them in the
[Google Cloud console](https://console.cloud.google.com/apis/credentials) under
**APIs & Services → Credentials**:

- the **Web application** client ID → `GOOGLE_WEB_CLIENT_ID`
- the **iOS** client ID (iOS/macOS only) → `GOOGLE_IOS_CLIENT_ID`

> On **Android**, the *web* client ID is the one you need — it is passed as the
> `serverClientId` that mints the ID token Firebase exchanges for a credential. Without it,
> Google sign-in returns a null ID token and fails.

### 5. Create the Firestore database

In **Build → Firestore Database → Create database**, start in **production mode** and pick a
region (`eur3` or `nam5` are both fine). The security rules you deploy in step 9 will
replace the defaults.

You do not need to create any collections by hand — the app creates `users/{uid}` and its
subcollections on first use.

### 6. Register the Android SHA-1 fingerprint

Google sign-in on Android will **not** work until your signing certificate fingerprint is
registered. Generate it:

```bash
cd android
./gradlew signingReport      # Windows: .\gradlew.bat signingReport
cd ..
```

Copy the **SHA-1** (and **SHA-256**) from the `debug` variant, then in the Firebase console
go to **Project settings → Your apps → Android app → Add fingerprint** and paste it in.

> Repeat this for your **release** keystore before distributing an APK — the debug and
> release certificates have different fingerprints.

### 7. Set up Cloudinary

Attachments (record documents, card photos, profile pictures) are hosted on Cloudinary
because Firebase Storage requires a paid plan.

1. Create a free account at [cloudinary.com](https://cloudinary.com/).
2. Note your **cloud name** from the dashboard.
3. Go to **Settings → Upload → Upload presets → Add upload preset**.
4. Set **Signing mode** to **Unsigned** and save.
5. Note the **preset name**.

> Unsigned uploads deliver public (but unguessable) URLs. This is acceptable for this
> project and is recorded under [Known limitations](#known-limitations).

### 8. Create your .env file

All configuration lives in a git-ignored `.env` file. A fully documented template is
committed as [`.env.example`](.env.example):

```bash
cp .env.example .env          # Windows PowerShell: Copy-Item .env.example .env
```

Now open `.env` and fill in the values. The Firebase values come from
**Project settings → Your apps** in the Firebase console:

```dotenv
# ---- Shared across platforms ----
FIREBASE_PROJECT_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_STORAGE_BUCKET=

# ---- Android ----
FIREBASE_ANDROID_API_KEY=
FIREBASE_ANDROID_APP_ID=

# ---- iOS ----
FIREBASE_IOS_API_KEY=
FIREBASE_IOS_APP_ID=
FIREBASE_IOS_BUNDLE_ID=com.example.mediCarry

# ---- Web ----
FIREBASE_WEB_API_KEY=
FIREBASE_WEB_APP_ID=
FIREBASE_WEB_AUTH_DOMAIN=
FIREBASE_WEB_MEASUREMENT_ID=

# ---- Google Sign-In (from step 4) ----
GOOGLE_WEB_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=
GOOGLE_IOS_REVERSED_CLIENT_ID=

# ---- Cloudinary (from step 7) ----
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_UPLOAD_PRESET=
```

**Which keys are mandatory?** The `FIREBASE_*` keys for the platform you are running on are
required — the app throws a clear `EnvException` at startup naming any missing key. The
Google and Cloudinary keys are optional at startup: the app boots without them, and only the
sign-in or upload path reports that it is unconfigured. To exercise every feature, fill in
all of them.

> **iOS only:** `GOOGLE_IOS_REVERSED_CLIENT_ID` must *also* be added by hand to
> `ios/Runner/Info.plist` as a `CFBundleURLSchemes` entry. iOS reads URL schemes from the
> plist before any Dart code runs, so the `.env` value alone is not enough.

### 9. Deploy the security rules

The rules in [`firestore.rules`](firestore.rules) restrict every patient to their own
document tree. Deploy them:

```bash
npm install -g firebase-tools     # if you don't have the CLI
firebase login
firebase use --add                # select your project
firebase deploy --only firestore:rules
```

Verify in **Firestore → Rules** that the published rules match the file.

### 10. Run the app

Start an emulator or connect a device, then:

```bash
flutter devices                   # confirm your device is listed
flutter run -d <device-id>
```

Or simply `flutter run` if only one device is connected.

**First launch walkthrough:**

1. Tap **Sign Up** and complete step 1 (name, email, password) — or tap **Continue with
   Google**.
2. Complete step 2 (blood type, allergies, chronic conditions, date of birth, gender,
   emergency contact). A Patient ID is generated for you.
3. Complete step 3 (4-digit PIN, optional biometric unlock).
4. You land on the dashboard. Add a medical record, a medication and an insurance card to
   see the data appear live in the Firebase console.

---

## Building a release APK

```bash
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

Install it on a connected device with:

```bash
flutter install
```

> Register your **release** keystore's SHA-1 in Firebase (step 6) first, or Google sign-in
> will fail in the release build while working fine in debug.

---

## Running the tests

```bash
flutter test                              # full suite — 130 tests
flutter test --coverage                   # also writes coverage/lcov.info
flutter test test/features/auth           # a single directory
flutter analyze                           # static analysis — expect 0 issues
dart format --set-exit-if-changed .       # formatting check
```

Current status: **130 tests passing**, **51.1 % line coverage**, `flutter analyze` clean.

Read the coverage percentage out of the generated report:

```bash
awk -F, '/^DA:/ {t++; if ($2+0 > 0) h++} \
  END {printf "Coverage: %.1f%%\n", h*100/t}' coverage/lcov.info
```

The suite uses `fake_cloud_firestore` and `mocktail`, so **no Firebase project or network
connection is needed to run the tests**.

---

## Project structure

MediCarry uses a feature-first architecture with a shared core layer. Each feature owns four
layers, and the dependency direction only ever points inward: views depend on blocs, blocs
depend on repositories, repositories depend on Firebase. No widget touches Firestore
directly, and no repository imports Flutter.

```
lib/
├── app/             App shell, routing
├── core/
│   ├── config/      .env loading, Firebase options
│   ├── models/      Shared models (StoredAttachment)
│   ├── services/    Biometrics, secure storage, Cloudinary, notifications, crypto
│   ├── theme/       Colours, typography, ThemeCubit
│   └── widgets/     Shared form fields and attachment pickers
├── features/
│   ├── auth/        Sign-up flow, login, app lock, biometrics
│   ├── cards/       Insurance cards wallet
│   ├── dashboard/   Home screen and its widgets
│   ├── emergency/   Offline emergency info screen
│   ├── medications/ Medication tracker and dose scheduling
│   ├── profile/     Profile view and editing
│   ├── records/     Medical records CRUD, search and filtering
│   └── share/       Encrypted sharing, QR codes, PDF export
├── app.dart         Dependency injection (repositories + global blocs)
└── main.dart        Entry point — env, Firebase, notifications, runApp
```

Each feature folder contains `data/` (repositories), `models/` (domain entities), `bloc/`
(state management) and `view/` + `widgets/` (presentation).

## Database structure

All data is rooted at a single `users` collection, so one security rule protects the whole
tree:

```
users/{uid}                          ← patient profile
├── records/{recordId}               ← medical records
├── medications/{medId}              ← medication schedules
├── cards/{cardId}                   ← insurance / ID cards
└── shares/{shareId}                 ← share grants (audit + revoke)
```

The parent UID is encoded in the document path rather than stored as a field, so the path
itself acts as the foreign key. A full entity-relationship diagram with all fields, keys and
cardinalities is in [`docs/erd.puml`](docs/erd.puml).

## Security rules

```javascript
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;

  match /{document=**} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
  }
}
```

Firestore denies by default, so only these paths are reachable. The check is on
**ownership**, not merely authentication: the UID in the caller's verified ID token must
equal the UID in the document path, so a signed-in patient cannot read another patient's
records. The recursive `{document=**}` wildcard extends the same check to every
subcollection, including any added later.

---

## Troubleshooting

| Problem | Cause and fix |
|---|---|
| `EnvException: Missing "FIREBASE_..." in .env` | A required key is blank. Copy the value from Firebase console → Project settings → Your apps. |
| Google sign-in fails with `DEVELOPER_ERROR` / `ApiException: 10` | Your SHA-1 fingerprint is not registered, or the package name does not match. Redo step 6. |
| Google sign-in returns a null ID token | `GOOGLE_WEB_CLIENT_ID` is missing or wrong. On Android it must be the **web** client ID, not the Android one. |
| `Google sign-in was cancelled` immediately | Usually a fingerprint or package-name mismatch rather than a real cancellation. Check step 6. |
| `PERMISSION_DENIED` when reading or writing | Security rules are not deployed. Run step 9. |
| Attachments fail to upload | `CLOUDINARY_CLOUD_NAME` or `CLOUDINARY_UPLOAD_PRESET` is missing, or the preset is not set to **Unsigned**. Redo step 7. |
| Notifications never fire | Grant the notification permission on first launch. On Android 13+ it is requested at runtime; check the app's system settings if you dismissed it. |
| Build fails after switching branches | `flutter clean && flutter pub get` |

---

## Known limitations

- Security rules enforce ownership but do not yet validate document shape.
- Cloudinary uploads are unsigned; delivery URLs are unguessable but not access-controlled.
- Search and filtering happen client-side, which keeps them working offline but would not
  scale to thousands of records.
- Medication reminders are device-local and do not follow the patient to a new device.
- Revoking a share removes it from the active list but cannot retract an already-scanned QR
  code; the embedded `expiresAt` timestamp bounds the exposure window.
- The interface is currently English-only.

A fuller discussion is in section 7 of the project report.