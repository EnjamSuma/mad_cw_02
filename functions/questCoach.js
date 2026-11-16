
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

// Read-only tool: access only the signed-in learner's quest state.
async function readMyQuestState(uid) {
  const db = getFirestore();

  console.log("Reading quest state for authenticated user:", uid);
  console.log("Reading Firestore document: challenges/today");
  console.log(`Reading Firestore document: users/${uid}/progress/today`);

  const [challenge, progress] = await Promise.all([
    db.doc("challenges/today").get(),
    db.doc(`users/${uid}/progress/today`).get(),
  ]);

  // Today's challenge must exist.
  if (!challenge.exists) {
    console.error("Missing Firestore document: challenges/today");
    throw new Error("challenge missing");
  }

  console.log("Challenge document found.");

  return {
    challenge: challenge.data(),
    progress: progress.exists
      ? progress.data()
      : {
          completed: false,
          points: 0,
        },
  };
}

// Detect attempts to override instructions or access other users.
const INJECTION =
  /ignore (your|all|previous)|another learner|someone else|other user|give me \d+ points|\b\d{2,} points\b|reveal|bypass/i;

// Emulator-safe mock coach.
// Returns one concise hint without modifying Firestore.
function buildHint(state, question) {
  if (INJECTION.test(question)) {
    return (
      "I can only see your own quest, and I can't change points or badges. " +
      "Only the Complete button can request a reward. " +
      "Want a hint for today's challenge instead?"
    );
  }

  const { challenge, progress } = state;

  if (progress.completed) {
    return (
      `You've already finished "${challenge.title}". ` +
      "Nice work! Nothing more to do today."
    );
  }

  const words = String(challenge.prompt || "")
    .split(" ")
    .slice(0, 6)
    .join(" ");

  return (
    `Hint for "${challenge.title}": start small. ` +
    `Re-read the first part of the prompt ("${words}...") ` +
    "and tackle just that piece. " +
    "When you're done, press Complete yourself."
  );
}

// Callable Cloud Function: Quest Coach.
exports.askQuestCoach = onCall(async (request) => {
  // Require Firebase Authentication.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Sign in first."
    );
  }

  // Validate the learner's question.
  const question =
    typeof request.data?.question === "string"
      ? request.data.question.trim()
      : "";

  if (!question || question.length > 300) {
    throw new HttpsError(
      "invalid-argument",
      "Question must be 1-300 characters."
    );
  }

  // Simulate a model outage for emulator testing.
  if (
    process.env.FUNCTIONS_EMULATOR === "true" &&
    question === "/fail"
  ) {
    throw new HttpsError(
      "unavailable",
      "The coach is unavailable."
    );
  }

  let state;

  try {
    // Always read the authenticated learner's quest state first.
    state = await readMyQuestState(request.auth.uid);
  } catch (error) {
    // Log the actual error on the backend for debugging.
    console.error("Quest Coach Firestore read failed:", error);

    // Do not expose internal Firestore details to the client.
    throw new HttpsError(
      "internal",
      "Could not read your quest state."
    );
  }

  // Generate a read-only hint.
  const reply = buildHint(state, question);

  console.log("Quest Coach hint generated successfully.");

  return { reply };
});
