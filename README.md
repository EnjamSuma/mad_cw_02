# Cloud Quest – CW-02

## Project Overview

Cloud Quest is a Flutter-based mobile application that uses Firebase services and Google's Genkit framework to provide an interactive learning experience.

Users can register, sign in, complete daily challenges, earn points and badges, and ask an AI-powered Quest Coach for educational hints.

## Technologies Used

- **Flutter and Dart** – Mobile application development
- **Firebase Authentication** – User registration and login
- **Cloud Firestore** – Challenge and progress storage
- **Firebase Cloud Functions** – Secure backend operations
- **Genkit** – AI integration framework
- **Google Gemini** – AI-powered educational hints
- **Firebase Emulator Suite** – Local development and testing
- **JavaScript and Node.js** – Backend implementation

## Features Implemented

### 1. User Authentication

Implemented Firebase Authentication with user registration, login, logout, and authentication-state handling.

### 2. Daily Challenges

The application retrieves the daily challenge from Cloud Firestore and displays its title and description.

### 3. Points and Badges

Users can complete challenges to earn points and badges. Cloud Functions manage reward updates securely and prevent duplicate rewards.

### 4. AI-Powered Quest Coach

Integrated Google's Genkit framework with Gemini to generate educational hints based on the current challenge and learner's question.

The implementation includes:

- Context-aware AI hint generation
- User authentication checks
- Input validation
- Prompt-injection protection
- Error handling
- Simulated AI service failure testing

### 5. Firestore Security

Implemented Firestore security rules to restrict access to authenticated users and prevent unauthorized modifications to progress and rewards.

### 6. Firebase Cloud Functions

Implemented two backend functions:

- **completeToday** – Processes challenge completion and rewards
- **askQuestCoach** – Processes learner questions and requests AI-generated hints

### 7. Firebase Emulator Integration

Configured Firebase Authentication, Firestore, and Cloud Functions Emulators for local development and testing.

## Testing

The application was tested using a physical Android device and Firebase Emulator Suite.

Implemented and previously tested functionality includes:

- User registration and login
- Daily challenge display
- Challenge completion
- Points and badge updates
- Duplicate reward prevention
- Firestore security rules
- Quest Coach input validation
- Unauthorized request handling
- Simulated AI service failures

The Genkit/Gemini integration is implemented. Final successful AI-response verification and the latest Firestore connectivity check remain pending.

## Running the Application

### Start Firebase Emulators

From the project directory:

```bash
firebase emulators:start --project cloud-quest-cw2 --only auth,firestore,functions
```

### Run Flutter

```bash
flutter pub get
flutter run
```

For a physical Android device connected through USB, configure ADB port forwarding for the local Firebase Emulator services.

### Gemini Configuration

Create a `functions/.env` file containing:

```dotenv
GEMINI_API_KEY=YOUR_API_KEY
```

Keep this file excluded from version control.

## Security Considerations

- Firebase Authentication is required for protected backend operations.
- User identity is obtained from verified authentication credentials.
- Reward updates are handled by Cloud Functions.
- Firestore security rules restrict unauthorized writes.
- AI questions are validated before processing.
- API credentials are stored outside source control.

## GitHub Repository

https://github.com/EnjamSuma/mad_cw_02

## Conclusion

Cloud Quest demonstrates the integration of Flutter, Firebase Authentication, Cloud Firestore, Cloud Functions, and Genkit with Gemini.

All major application features have been implemented, including authentication, daily challenges, rewards, security rules, and AI-powered hint generation. Final verification of the live Gemini response and current emulator connectivity is done.