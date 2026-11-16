const { test, before, after } = require("node:test");
const fs = require("fs");
const path = require("path");
const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require("@firebase/rules-unit-testing");

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-cloudquest",
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "..", "..", "firestore.rules"), "utf8"),
      host: "127.0.0.1", port: 8080,
    },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("challenges/today").set({ title: "t", prompt: "p" });
    await db.doc("users/bob/progress/today").set({ completed: true, points: 10, badgeId: "first-quest" });
  });
});
after(async () => { await env.cleanup(); });

test("signed-out cannot read the challenge", async () => {
  await assertFails(env.unauthenticatedContext().firestore().doc("challenges/today").get());
});
test("alice can read the challenge", async () => {
  await assertSucceeds(env.authenticatedContext("alice").firestore().doc("challenges/today").get());
});
test("alice cannot read bob's progress", async () => {
  await assertFails(env.authenticatedContext("alice").firestore().doc("users/bob/progress/today").get());
});
test("alice cannot write her own reward directly", async () => {
  await assertFails(env.authenticatedContext("alice").firestore()
    .doc("users/alice/progress/today").set({ completed: true, points: 500, badgeId: "hack" }));
});
test("bob can read his own progress", async () => {
  await assertSucceeds(env.authenticatedContext("bob").firestore().doc("users/bob/progress/today").get());
});