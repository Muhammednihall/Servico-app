const admin = require('firebase-admin');

// Initialize using application default credentials (firebase login must be done)
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'servico-1967',
});

const db = admin.firestore();

async function cleanupWorkers() {
  const keepNames = ['nihal', 'aswin']; // lowercase comparison

  console.log('🔍 Fetching all workers...');
  const snapshot = await db.collection('workers').get();

  console.log(`📋 Found ${snapshot.size} workers total.`);

  const toDelete = [];
  const toKeep = [];

  snapshot.forEach((doc) => {
    const name = (doc.data().name || '').toLowerCase().trim();
    const shouldKeep = keepNames.some((n) => name.includes(n));
    if (shouldKeep) {
      toKeep.push({ id: doc.id, name: doc.data().name });
    } else {
      toDelete.push({ id: doc.id, name: doc.data().name });
    }
  });

  console.log(`\n✅ Keeping (${toKeep.length}):`);
  toKeep.forEach((w) => console.log(`   - ${w.name} (${w.id})`));

  console.log(`\n🗑️  Deleting (${toDelete.length}):`);
  toDelete.forEach((w) => console.log(`   - ${w.name} (${w.id})`));

  if (toDelete.length === 0) {
    console.log('\nNothing to delete!');
    process.exit(0);
  }

  // Batch delete
  const batchSize = 500;
  for (let i = 0; i < toDelete.length; i += batchSize) {
    const batch = db.batch();
    const chunk = toDelete.slice(i, i + batchSize);
    chunk.forEach((w) => batch.delete(db.collection('workers').doc(w.id)));
    await batch.commit();
    console.log(`\n✅ Deleted batch of ${chunk.length} workers.`);
  }

  console.log('\n🎉 Done! Only Nihal and Aswin remain.');
  process.exit(0);
}

cleanupWorkers().catch((err) => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
