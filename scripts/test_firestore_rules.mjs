/**
 * Firestore rules 검증 — 에뮬레이터에서 실행
 * firebase emulators:exec --only firestore "node scripts/test_firestore_rules.mjs"
 */
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, collection, getDocs, query, where, orderBy } from 'firebase/firestore';

const PROJECT_ID = 'chapter-cc187-test';
const rules = readFileSync('firestore.rules', 'utf8');

const ownerUid = 'user-owner-abc';
const otherUid = 'user-other-xyz';

async function run() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });

  try {
    // ── 소유자: chapters 읽기/쓰기 OK
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${ownerUid}/chapters/ch1`), {
        userId: ownerUid,
        title: 'test',
      });
    });

    const ownerDb = testEnv.authenticatedContext(ownerUid).firestore();

    async function expectOk(name, fn) {
      try {
        await assertSucceeds(fn());
        console.log('✔', name);
      } catch (e) {
        console.log('✘', name, '—', e?.message ?? e);
        process.exitCode = 1;
      }
    }

    async function expectDenied(name, fn) {
      try {
        await assertFails(fn());
        console.log('✔', name);
      } catch (e) {
        console.log('✘', name, '—', e?.message ?? e);
        process.exitCode = 1;
      }
    }

    await expectOk('owner chapters get', () =>
        getDoc(doc(ownerDb, `users/${ownerUid}/chapters/ch1`)));
    await expectOk('owner chapters collection query', () =>
        getDocs(collection(ownerDb, `users/${ownerUid}/chapters`)));
    await expectOk('owner chapters write', () =>
        setDoc(doc(ownerDb, `users/${ownerUid}/chapters/ch2`), {
          userId: ownerUid,
          title: 'new',
        }));

    await expectDenied('owner cannot read other user chapters', () =>
        getDoc(doc(ownerDb, `users/${otherUid}/chapters/ch1`)));

    const otherDb = testEnv.authenticatedContext(otherUid).firestore();
    await expectDenied('other user cannot read owner chapters', () =>
        getDoc(doc(otherDb, `users/${ownerUid}/chapters/ch1`)));

    const anonDb = testEnv.unauthenticatedContext().firestore();
    await expectDenied('unauthenticated denied', () =>
        getDoc(doc(anonDb, `users/${ownerUid}/chapters/ch1`)));

    // ── orders
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'orders/order1'), {
        userId: ownerUid,
        status: 'pending_payment',
        snapshots: [{ date: '2024-01-01', title: 't', body: 'b', photoUrls: [] }],
        createdAt: new Date('2024-06-01'),
      });
    });
    await expectOk('owner can read own order', () => getDoc(doc(ownerDb, 'orders/order1')));
    await expectOk('owner orders list query (userId + createdAt)', () =>
      getDocs(
        query(
          collection(ownerDb, 'orders'),
          where('userId', '==', ownerUid),
          orderBy('createdAt', 'desc'),
        ),
      ),
    );
    await expectDenied('query with wrong userId denied', () =>
      getDocs(
        query(
          collection(ownerDb, 'orders'),
          where('userId', '==', otherUid),
          orderBy('createdAt', 'desc'),
        ),
      ),
    );
    await expectDenied('other cannot read order', () => getDoc(doc(otherDb, 'orders/order1')));

    if (!process.exitCode) {
      console.log('\nAll Firestore rule checks passed.');
    }
  } finally {
    await testEnv.cleanup();
  }
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
