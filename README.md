# Firebase Cloud Quest – Signal Check

**Coursework:** CW-02 #03 – Firebase Cloud Services  
**Student:** Suma Enjam  
**Program:** M.S. Computer Science (Graduate)  
**Institution:** Georgia State University

## Project Overview

Cloud Quest is a Flutter application that integrates Firebase Authentication, Cloud Firestore, Cloud Functions, and a Quest Coach. Users sign in, view a daily challenge, request a hint, and complete the challenge to earn 10 points and the First Quest badge.

The reward system is controlled by a trusted Cloud Function to prevent duplicate rewards and unauthorized modifications.

## Technologies Used

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions (Node.js)
- Firebase Emulator Suite
- JavaScript
- Git and GitHub

## Setup and Execution

**Development platform:** Windows 11  
**Test device:** I2012 Android phone (Android 14)

Install dependencies:

```bash
flutter pub get
cd functions
npm install
cd ..
```

Start Firebase Emulators:

```bash
firebase emulators:start --only auth,firestore,functions
```

Run the Flutter application:

```bash
flutter run
```

For physical-device testing, the Firebase Emulators require a reachable network connection or USB port forwarding.

## Firebase Implementation

### Authentication

Firebase Authentication supports account registration, sign-in, and sign-out. The application uses an authentication-state listener to protect the challenge screen.

### Cloud Firestore

The application uses two main document paths:

- `challenges/today` – stores the daily challenge title and prompt.
- `users/{uid}/progress/today` – stores completion status, points, badge, and timestamp.

Firestore security rules prevent unauthorized reads and direct client modifications to reward records.

### Cloud Functions

**completeToday**

Validates the authenticated user and awards 10 points and the `first-quest` badge. A Firestore transaction ensures that completing the same challenge again does not award additional points.

**askQuestCoach**

Provides a hint based on the signed-in learner's challenge and progress. Its `readMyQuestState` tool retrieves only the current user's quest data.

The current implementation uses an emulator-safe mock hint generator rather than a live Genkit model.

## Security and Trust Boundaries

The Flutter client requests challenge information and completion, but it cannot directly modify reward records.

The Cloud Function verifies the user's identity and controls reward updates.

The Quest Coach reads the user's state without writing to Firestore or invoking the reward function. Its tool uses the verified authentication UID instead of accepting a user ID from the client.

## Testing and Results

### Graduate Automated Tests

Executed against the Firestore Emulator using:

```powershell
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
$env:GCLOUD_PROJECT = "demo-cloudquest"
npm --prefix functions test
```

**Result: 5 tests passed, 0 failed.**

| Test | Result |
|---|---|
| Signed-out user cannot read the challenge | Passed |
| Authenticated user can read the challenge | Passed |
| User cannot read another learner's progress | Passed |
| User cannot directly write reward data | Passed |
| User can read their own progress | Passed |

### Cloud Function Verification

| Test | Observed result |
|---|---|
| Unauthenticated reward request | HTTP 401 – UNAUTHENTICATED |
| First authenticated completion | 10 points and `first-quest` badge |
| Duplicate completion | `alreadyCompleted: true`; points remained 10 |
| Quest Coach normal request | Recognized completed challenge |
| Adversarial coach request | Refused to disclose another user's data or grant 500 points |

### Known Limitations

The physical Android app launched, but registration and sign-in encountered a Firebase Authentication network error. Backend functionality was therefore tested directly against the Firebase Emulators.

The Quest Coach currently uses a deterministic mock response rather than a live AI model. Full mobile integration and live model verification remain incomplete.

## Conclusion

Cloud Quest demonstrates authenticated backend access, private learner progress, server-controlled rewards, duplicate-completion protection, and a read-only Quest Coach. Automated security tests and direct Cloud Function tests verified the backend behavior.

The remaining work is to resolve the physical-device connection and verify the complete learner journey through the Flutter interface.