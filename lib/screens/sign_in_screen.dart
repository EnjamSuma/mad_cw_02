import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/quest_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _go(Future<void> Function(String, String) action) async {
    setState(() { _busy = true; _error = null; });
    try {
      await action(_email.text.trim(), _pass.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Authentication failed (${e.code}).');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cloud Quest')),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Sign in to start your quest.'),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _pass, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (6+ chars)')),
            if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : () => _go(signIn), child: const Text('Sign in')),
            OutlinedButton(onPressed: _busy ? null : () => _go(register), child: const Text('Create account')),
          ]),
        ),
      );
}