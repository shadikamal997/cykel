/**
 * Migration Script: Add displayNameLower field to existing users
 * 
 * This script adds the displayNameLower field to all existing user documents
 * in the users collection. This field is required for case-insensitive search.
 * 
 * Usage:
 *   1. Build the functions: cd functions && npm run build
 *   2. Run this script: node lib/migrate_displayNameLower.js
 * 
 * The script processes users in batches to avoid memory issues with large datasets.
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin with explicit project ID
admin.initializeApp({
  projectId: 'cykel-32383', // Your Firebase project ID
});

const db = admin.firestore();
const BATCH_SIZE = 500; // Process 500 users at a time

async function migrateDisplayNameLower() {
  console.log('🚀 Starting migration: adding displayNameLower to users...');
  
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
  let totalProcessed = 0;
  let totalUpdated = 0;
  let hasMore = true;

  while (hasMore) {
    // Query users in batches
    let query = db.collection('users')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);
    
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    
    if (snapshot.empty) {
      hasMore = false;
      break;
    }

    // Process this batch
    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      totalProcessed++;

      // Check if displayNameLower already exists
      if (!data.displayNameLower) {
        const displayName = data.displayName || data.name || '';
        batch.update(doc.ref, {
          displayNameLower: displayName.toLowerCase(),
        });
        batchCount++;
        totalUpdated++;
      }
    }

    // Commit this batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Batch committed: ${batchCount} users updated`);
    }

    console.log(`📊 Progress: ${totalProcessed} users processed, ${totalUpdated} updated`);

    // Update lastDoc for next iteration
    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    
    // If we got fewer docs than BATCH_SIZE, we're done
    if (snapshot.size < BATCH_SIZE) {
      hasMore = false;
    }
  }

  console.log('\n✨ Migration complete!');
  console.log(`   Total users processed: ${totalProcessed}`);
  console.log(`   Total users updated: ${totalUpdated}`);
  console.log(`   Users already had displayNameLower: ${totalProcessed - totalUpdated}`);
}

// Run the migration
migrateDisplayNameLower()
  .then(() => {
    console.log('\n✅ Migration finished successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  });
