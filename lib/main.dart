
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/challenge_screen.dart';
import 'screens/sign_in_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect to local Firebase Emulators in debug mode.
  if (kDebugMode) {
    // USB port forwarding through adb reverse.
    // Use 127.0.0.1 instead of localhost.
    const host = '127.0.0.1';

    // Firebase Authentication Emulator.
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);

    // Cloud Firestore Emulator.
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);

    // Cloud Functions Emulator.
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  }

  runApp(const CloudQuestApp());
}

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final user = snap.data;

          if (user == null) {
            return const SignInScreen();
          }

          return ChallengeScreen(user: user);
        },
      ),
    );
  }
}
