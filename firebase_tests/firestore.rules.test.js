'use strict';

// Security-rules unit tests for firestore.rules, run against the Firebase
// Firestore emulator. Self-running and portable: works under any Node
// (including the node bundled with the firebase CLI). Usage:
//
//   cd firebase_tests && npm ci
//   cd .. && firebase emulators:exec --only firestore \
//     --project demo-pantry-app 'node firebase_tests/firestore.rules.test.js'
//
// Emulator default is allow-all, so every denial assertion below FAILS
// without the rules in firestore.rules — this suite is the regression
// lock for the security model.

const fs = require('node:fs');
const path = require('node:path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const projectId = 'demo-pantry-app';
const rulesPath = path.resolve(__dirname, '..', 'firestore.rules');

let testEnv;
let failed = 0;

function validProduct() {
  return {
    barcode: '7622210449283',
    name: 'Salted Butter',
    createdAt: 1,
    lastRefreshedAt: 2,
    nextRefreshAt: 3,
  };
}

function validProduce() {
  return {
    fdcId: 168462,
    name: 'apple',
    nutrition: { energyKcal: 52 },
    createdAt: 1,
    lastRefreshedAt: 2,
    nextRefreshAt: 3,
  };
}

function validRecipe(uid) {
  return {
    recipeId: '0e457ac7-6486-4751-ba7d-270d8cf7e1ae',
    name: 'Pasta',
    instructions: 'Boil',
    servings: 2,
    ingredients: [],
    createdAt: 1,
    lastRefreshedAt: 2,
    nextRefreshAt: 3,
    ingestedBy: uid,
  };
}

async function test(name, fn) {
  await testEnv.clearFirestore();
  try {
    await fn();
    console.log(`ok - ${name}`);
  } catch (e) {
    failed += 1;
    console.error(`not ok - ${name}\n  ${e && e.message}`);
  }
}

async function main() {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });

  await test('product_cache allows unauthenticated reads', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(db.collection('product_cache').get());
  });

  await test('product_cache rejects unauthenticated writes', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('product_cache').doc('123').set(validProduct()),
    );
  });

  await test('product_cache allows a signed-in user to write a well-formed product', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(
      db.collection('product_cache').doc('123').set(validProduct()),
    );
  });

  await test('product_cache rejects a non-barcode document id', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(
      db.collection('product_cache').doc('bad id with spaces').set(validProduct()),
    );
  });

  await test('product_cache rejects a malformed document', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(
      db.collection('product_cache').doc('123').set({ junk: true }),
    );
  });

  await test('product_cache rejects deletes', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await db.collection('product_cache').doc('123').set(validProduct());
    await assertFails(db.collection('product_cache').doc('123').delete());
  });

  await test('produce_cache allows a signed-in user to write a well-formed entry', async () => {
    const db = testEnv.authenticatedContext('bob').firestore();
    await assertSucceeds(
      db.collection('produce_cache').doc('apple').set(validProduce()),
    );
  });

  await test('produce_cache rejects a malformed entry', async () => {
    const db = testEnv.authenticatedContext('bob').firestore();
    await assertFails(
      db.collection('produce_cache').doc('apple').set({ fdcId: 'nope' }),
    );
  });

  await test('recipe_cache allows the author to create their own recipe', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(
      db
        .collection('recipe_cache')
        .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
        .set(validRecipe('alice')),
    );
  });

  await test('recipe_cache rejects creating a recipe attributed to someone else', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(
      db
        .collection('recipe_cache')
        .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
        .set(validRecipe('mallory')),
    );
  });

  await test('recipe_cache rejects updating someone elses recipe', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await alice
      .collection('recipe_cache')
      .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
      .set(validRecipe('alice'));
    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertFails(
      bob
        .collection('recipe_cache')
        .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
        .update({ servings: 9 }),
    );
  });

  await test('recipe_cache allows the author to update their own recipe', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await db
      .collection('recipe_cache')
      .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
      .set(validRecipe('alice'));
    await assertSucceeds(
      db
        .collection('recipe_cache')
        .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
        .update({ servings: 9 }),
    );
  });

  await test('recipe_cache rejects deleting someone elses recipe', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await alice
      .collection('recipe_cache')
      .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
      .set(validRecipe('alice'));
    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertFails(
      bob
        .collection('recipe_cache')
        .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
        .delete(),
    );
  });

  await test('recipe_cache allows the author to delete their own recipe', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await db
      .collection('recipe_cache')
      .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
      .set(validRecipe('alice'));
    await assertSucceeds(
      db
        .collection('recipe_cache')
        .doc('0e457ac7-6486-4751-ba7d-270d8cf7e1ae')
        .delete(),
    );
  });

  await testEnv.cleanup();
}

main()
  .then(() => {
    console.log(`${failed === 0 ? 'PASS' : 'FAIL'}: ${failed} test(s) failed`);
    process.exit(failed === 0 ? 0 : 1);
  })
  .catch((e) => {
    console.error('rules test harness crashed:', e && e.message);
    process.exit(1);
  });
