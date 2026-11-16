# Firebase Cloud Quest – Signal Check

**Coursework:** CW-02 #03 – Firebase Cloud Services  
**Student:** Suma Enjam  
**Program:** M.S. Computer Science (Graduate)  
**Institution:** Georgia State University  
**GitHub:** https://github.com/EnjamSuma/mad_cw_02

## Project Overview

Cloud Quest is a Flutter application that integrates Firebase Authentication, Cloud Firestore, Cloud Functions, and a Quest Coach.

Users can register, sign in, view a daily challenge, request hints, and complete the challenge to earn 10 points and the `first-quest` badge.

Rewards are managed by a trusted Cloud Function to prevent duplicate rewards and unauthorized modifications.

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

Start the Firebase Emulators:

```bash
firebase emulators:start --project cloud-quest-cw2 --only auth,firestore,functions
```

For physical Android testing over USB, forward the emulator ports using ADB:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:9099 tcp:9099
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:5001 tcp:5001
```

Run the application:

```bash
flutter run
```

The application connects to the local Firebase Emulators in debug mode. The Firestore Emulator must contain the `challenges/today` document with a title and prompt.

## Firebase Implementation

### Authentication

Firebase Authentication supports account registration, sign-in, and sign-out. An authentication-state listener ensures that only signed-in users can access the challenge screen.

### Cloud Firestore

The application uses two main document paths:

- `challenges/today` – stores the daily challenge title and prompt.
- `users/{uid}/progress/today` – stores completion status, points, badge, and timestamp.

Firestore security rules restrict access to authenticated users and prevent direct client modifications to reward records.

### Cloud Functions

**completeToday**

Validates the authenticated user and awards 10 points and the `first-quest` badge. A Firestore transaction prevents duplicate rewards when the same challenge is completed again.

**askQuestCoach**

Provides a hint based on the authenticated learner's challenge and progress. The `readMyQuestState` tool reads the current learner's information without modifying Firestore.

The current implementation uses an emulator-safe mock hint generator rather than a live Genkit model.

## Security and Trust Boundaries

- The Flutter client cannot directly modify reward records.
- Cloud Functions validate authenticated requests.
- Firestore rules prevent users from accessing another learner's progress.
- Reward updates are handled by the trusted backend.
- Quest Coach uses the verified authentication UID rather than accepting a user ID from the client.
- Quest Coach refuses requests to manipulate points, badges, or access another learner's data.

## Testing and Results

### Graduate Automated Tests

Firestore security rules were tested using:

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

| Test | Result |
|---|---|
| Unauthenticated reward request | HTTP 401 – UNAUTHENTICATED |
| First authenticated completion | 10 points and `first-quest` badge |
| Duplicate completion | No additional points awarded |
| Quest Coach normal request | Hint generated successfully |
| Adversarial coach request | Unauthorized reward modification refused |

### Android Application Testing

The Flutter application was tested on a physical Android device connected to the Firebase Emulator Suite.

The following functionality was verified:

- User registration and sign-in
- Display of today's challenge
- Successful Quest Coach hint generation
- Challenge completion and reward display
- Firestore storage of learner progress

Additional test cases include duplicate-completion protection, adversarial prompts, and simulated Quest Coach failure.

Screenshots and supporting test evidence are stored in the `submission_evidence` directory.

## Known Limitations

- Quest Coach uses a deterministic mock hint generator rather than a live Genkit-powered AI model.
- The application currently