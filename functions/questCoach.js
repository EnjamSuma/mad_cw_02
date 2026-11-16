const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

// The coach's ONE tool. Read-only. UID comes only from verified Auth context.
async function readMyQuestState(uid) {
  const db = getFirestore();
  const [challenge, progress] = await Promise.all([
    db.doc("challenges/today").get(),
    db.doc(`users/${uid}/progress/today`).get(),
  ]);
  if (!challenge.exists) throw new Error("challenge missing");
  return {
    challenge: challenge.data(),
    progress: progress.exists ? progress.data() : { completed: false, points: 0 },
  };
}

const INJECTION = /ignore (your|all|previous)|another learner|someone else|other user|give me \d+ points|\b\d{2,} points\b|reveal|bypass/i;

// Emulator-safe mock "model". Swap this for a Genkit call if you have gateway access.
// System instruction it follows: supportive quest coach, one concise hint (not the
// full answer), never claim a reward was granted, cannot write data.
function buildHint(state, question) {
  if (INJECTION.test(question)) {
    return "I can only see your own quest, and I can't change points or badges. " +
      "Only the Complete button can request a reward. Want a hint for today's challenge instead?";
  }
  const { challenge, progress } = state;
  if (progress.completed) {
    return `You've already finished "${challenge.title}". Nice work! Nothing more to do today.`;
  }
  const words = String(challenge.prompt || "").split(" ").slice(0, 6).join(" ");
  return `Hint for "${challenge.title}": start small. Re-read the first part of the prompt ("${words}...") ` +
    "and tackle just that piece. When you're done, press Complete yourself.";
}

exports.askQuestCoach = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const question = typeof request.data?.question === "string" ? request.data.question.trim() : "";
  if (!question || question.length > 300) {
    throw new HttpsError("invalid-argument", "Question must be 1-300 characters.");
  }
  // Simulated model outage for testing (emulator only)
  if (process.env.FUNCTIONS_EMULATOR === "true" && question === "/fail") {
    throw new HttpsError("unavailable", "The coach is unavailable.");
  }
  let state;
  try {
    state = await readMyQuestState(request.auth.uid); // tool ALWAYS runs first
  } catch (e) {
    throw new HttpsError("internal", "Could not read your quest state."); // no invented hint
  }
  return { reply: buildHint(state, question) };
});