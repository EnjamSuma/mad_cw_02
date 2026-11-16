import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/quest_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.user});
  final User user;
  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _q = TextEditingController();
  Map<String, Object?>? _data;
  String? _loadError;
  String? _coachReply;
  String? _rewardMsg;
  bool _loading = true, _coachBusy = false, _completeBusy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final d = await loadToday();
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load the quest. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _completeBusy = true);
    try {
      final r = await completeChallenge();
      if (!mounted) return;
      setState(() => _rewardMsg = r['alreadyCompleted'] == true
          ? 'Already completed: ${r['points']} points, badge ${r['badgeId']} (no duplicate).'
          : 'Quest complete! +${r['points']} points and the "${r['badgeId']}" badge.');
      await _load();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('completeToday failed: ${e.code}');
      if (mounted) setState(() => _rewardMsg = 'Could not complete right now. Try again.');
    } finally {
      if (mounted) setState(() => _completeBusy = false);
    }
  }

  Future<void> _hint() async {
    if (_q.text.trim().isEmpty) {
      setState(() => _coachReply = 'Type a question first.');
      return;
    }
    setState(() => _coachBusy = true);
    try {
      final r = await getQuestHint(_q.text);
      if (!mounted) return;
      setState(() => _coachReply = r);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Quest Coach request failed: ${e.code}');
      if (mounted) setState(() => _coachReply = 'The coach is unavailable. Try again.');
    } finally {
      if (mounted) setState(() => _coachBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _data?['challenge'] as Map<String, dynamic>?;
    final progress = _data?['progress'] as Map<String, dynamic>?;
    final done = progress?['completed'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Quest'), actions: [
        IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign out', onPressed: logOut),
      ]),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_loadError!), TextButton(onPressed: _load, child: const Text('Retry'))]))
                : ListView(padding: const EdgeInsets.all(16), children: [
                    Text('Signed in as ${widget.user.email ?? widget.user.uid}'),
                    const SizedBox(height: 12),
                    Text("Today's challenge", style: Theme.of(context).textTheme.headlineSmall),
                    Text(challenge?['title']?.toString() ?? 'No challenge found',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(challenge?['prompt']?.toString() ?? ''),
                    const SizedBox(height: 8),
                    Text(done
                        ? 'Progress: completed, ${progress?['points']} points, badge ${progress?['badgeId']}'
                        : 'Progress: not completed yet'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _completeBusy ? null : _complete,
                      child: Text(_completeBusy ? 'Working…' : 'Complete challenge')),
                    if (_rewardMsg != null) Padding(
                        padding: const EdgeInsets.only(top: 8), child: Text(_rewardMsg!)),
                    const Divider(height: 32),
                    TextField(controller: _q, maxLength: 300,
                        decoration: const InputDecoration(labelText: 'Ask the Quest Coach for a hint')),
                    OutlinedButton(
                      onPressed: _coachBusy ? null : _hint,
                      child: Text(_coachBusy ? 'Thinking…' : 'Get hint')),
                    if (_coachReply != null) Padding(
                        padding: const EdgeInsets.only(top: 8), child: Text(_coachReply!)),
                  ]),
      ),
    );
  }
}