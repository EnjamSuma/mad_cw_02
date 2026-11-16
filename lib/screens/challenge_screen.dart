
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/quest_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.user,
  });

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

  bool _loading = true;
  bool _coachBusy = false;
  bool _completeBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Load today's challenge and the learner's progress.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final d = await loadToday();

      if (!mounted) return;

      setState(() {
        _data = d;
      });
    } catch (e) {
      debugPrint('Challenge loading error: $e');

      if (!mounted) return;

      setState(() {
        _loadError =
            'Could not load the quest. Check your connection and retry.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Complete today's challenge and display the reward.
  Future<void> _complete() async {
    setState(() {
      _completeBusy = true;
    });

    try {
      final r = await completeChallenge();

      if (!mounted) return;

      setState(() {
        _rewardMsg = r['alreadyCompleted'] == true
            ? 'Already completed: ${r['points']} points, '
                'badge ${r['badgeId']} (no duplicate).'
            : 'Quest complete! +${r['points']} points '
                'and the "${r['badgeId']}" badge.';
      });

      await _load();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('completeToday error code: ${e.code}');
      debugPrint('completeToday error message: ${e.message}');
      debugPrint('completeToday error details: ${e.details}');

      if (mounted) {
        setState(() {
          _rewardMsg = 'Could not complete right now. Try again.';
        });
      }
    } catch (e) {
      debugPrint('Unexpected completion error: $e');

      if (mounted) {
        setState(() {
          _rewardMsg = 'Unexpected error while completing the quest.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _completeBusy = false;
        });
      }
    }
  }

  // Request a hint from the askQuestCoach Cloud Function.
  Future<void> _hint() async {
    final question = _q.text.trim();

    if (question.isEmpty) {
      setState(() {
        _coachReply = 'Type a question first.';
      });
      return;
    }

    setState(() {
      _coachBusy = true;
      _coachReply = null;
    });

    try {
      debugPrint('Sending question to Quest Coach: $question');

      final reply = await getQuestHint(question);

      debugPrint('Quest Coach response: $reply');

      if (!mounted) return;

      setState(() {
        _coachReply = reply;
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Quest Coach error code: ${e.code}');
      debugPrint('Quest Coach error message: ${e.message}');
      debugPrint('Quest Coach error details: ${e.details}');

      if (mounted) {
        setState(() {
          _coachReply =
              'Coach error: ${e.code} - ${e.message ?? "No details"}';
        });
      }
    } catch (e) {
      debugPrint('Unexpected Quest Coach error: $e');

      if (mounted) {
        setState(() {
          _coachReply = 'Unexpected error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _coachBusy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _data?['challenge'] as Map<String, dynamic>?;
    final progress = _data?['progress'] as Map<String, dynamic>?;

    final done = progress?['completed'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: logOut,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Signed-in learner.
                      Text(
                        'Signed in as '
                        '${widget.user.email ?? widget.user.uid}',
                      ),

                      const SizedBox(height: 12),

                      // Today's challenge.
                      Text(
                        "Today's challenge",
                        style:
                            Theme.of(context).textTheme.headlineSmall,
                      ),

                      Text(
                        challenge?['title']?.toString() ??
                            'No challenge found',
                        style:
                            Theme.of(context).textTheme.titleMedium,
                      ),

                      Text(
                        challenge?['prompt']?.toString() ?? '',
                      ),

                      const SizedBox(height: 8),

                      // Learner progress.
                      Text(
                        done
                            ? 'Progress: completed, '
                                '${progress?['points']} points, '
                                'badge ${progress?['badgeId']}'
                            : 'Progress: not completed yet',
                      ),

                      const SizedBox(height: 16),

                      // Complete challenge.
                      FilledButton(
                        onPressed:
                            _completeBusy ? null : _complete,
                        child: Text(
                          _completeBusy
                              ? 'Working...'
                              : 'Complete challenge',
                        ),
                      ),

                      if (_rewardMsg != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Text(_rewardMsg!),
                        ),

                      const Divider(height: 32),

                      // Quest Coach question.
                      TextField(
                        controller: _q,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText:
                              'Ask the Quest Coach for a hint',
                        ),
                      ),

                      // Request hint.
                      OutlinedButton(
                        onPressed:
                            _coachBusy ? null : _hint,
                        child: Text(
                          _coachBusy
                              ? 'Thinking...'
                              : 'Get hint',
                        ),
                      ),

                      // Coach response or diagnostic error.
                      if (_coachReply != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Text(_coachReply!),
                        ),
                    ],
                  ),
      ),
    );
  }
}
