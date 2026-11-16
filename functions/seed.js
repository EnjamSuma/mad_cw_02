const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
initializeApp({ projectId: "demo-cloudquest" });
getFirestore().doc("challenges/today").set({
  title: "Write your first widget",
  prompt: "Build a Flutter widget that shows your name in a Card and a button that changes its color.",
}).then(() => { console.log("seeded"); process.exit(0); });