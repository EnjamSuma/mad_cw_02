import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _auth = FirebaseAuth.instance;

Future<void> register(String e, String p) =>
    _auth.createUserWithEmailAndPassword(email: e, password: p);
Future<void> signIn(String e, String p) =>
    _auth.signInWithEmailAndPassword(email: e, password: p);
Future<void> logOut() => _auth.signOut();

Future<Map<String, Object?>> loadToday() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw StateError('Sign in before loading learner progress.');
  final db = FirebaseFirestore.instance;
  final challenge = await db.collection('challenges').doc('today').get();
  final progress =
      await db.collection('users').doc(uid).collection('progress').doc('today').get();
  return {'challenge': challenge.data(), 'progress': progress.data()};
}

Future<Map<String, dynamic>> completeChallenge() async {
  final r = await FirebaseFunctions.instance
      .httpsCallable('completeToday')
      .call<Map<String, dynamic>>({'challengeId': 'today'});
  return Map<String, dynamic>.from(r.data);
}

Future<String> getQuestHint(String question) async {
  final t = question.trim();
  final safe = t.length > 300 ? t.substring(0, 300) : t;
  final r = await FirebaseFunctions.instance
      .httpsCallable('askQuestCoach')
      .call<Map<String, dynamic>>({'question': safe});
  return r.data['reply'] as String;
}