
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

// Award 10 points and one badge for completing today's challenge.
exports.completeToday = onCall(async (request) => {
  // Only authenticated users can complete a challenge.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }

  // Only the 'today' challenge is supported.
  if (request.data?.challengeId !== "today") {
    throw new HttpsError("invalid-argument", "Invalid challenge.");
  }

  const uid = request.auth.uid;
  const progressRef = db.doc(`users/${uid}/progress/today`);

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(progressRef);

    // Prevent duplicate rewards.
    if (snapshot.exists) {
      const progress = snapshot.data();

      return {
        completed: true,
        points: progress.points,
        badgeId: progress.badgeId,
        alreadyCompleted: true,
      };
    }

    // First successful completion.
    transaction.set(progressRef, {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      completedAt: FieldValue.serverTimestamp(),
    });

    return {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      alreadyCompleted: false,
    };
  });
});

exports.askQuestCoach = require("./questCoach").askQuestCoach;