#!/usr/bin/env node

/**
 * Migration script to add userId to existing provider_analytics documents
 * Run with: cd functions && node migrate-analytics.js
 */

const admin = require('firebase-admin');

// Initialize Admin SDK with project ID
admin.initializeApp({
  projectId: 'cykel-32383'
});

const db = admin.firestore();

async function migrateProviderAnalytics() {
  console.log('Starting provider_analytics migration...');
  
  // Get all providers
  const providersSnapshot = await db.collection('providers').get();
  console.log(`\nFound ${providersSnapshot.size} providers\n`);
  
  let updated = 0;
  let skipped = 0;
  let errors = 0;
  
  for (const providerDoc of providersSnapshot.docs) {
    const providerId = providerDoc.id;
    const providerData = providerDoc.data();
    const userId = providerData.userId;
    
    if (!userId) {
      console.log(`⊘ Skipping ${providerId} - no userId in provider doc`);
      skipped++;
      continue;
    }
    
    try {
      // Check if analytics doc exists
      const analyticsDoc = await db.collection('provider_analytics').doc(providerId).get();
      
      if (!analyticsDoc.exists) {
        console.log(`⊘ No analytics doc for provider ${providerId}`);
        skipped++;
        continue;
      }
      
      const analyticsData = analyticsDoc.data();
      if (analyticsData?.userId) {
        console.log(`⊘ Provider ${providerId} already has userId`);
        skipped++;
        continue;
      }
      
      // Update with userId
      await db.collection('provider_analytics').doc(providerId).update({
        userId: userId
      });
      
      console.log(`✓ Updated analytics for provider ${providerId} with userId ${userId}`);
      updated++;
      
    } catch (error) {
      console.error(`✗ Error updating provider ${providerId}:`, error.message);
      errors++;
    }
  }
  
  console.log('\n' + '='.repeat(50));
  console.log('MIGRATION COMPLETE');
  console.log('='.repeat(50));
  console.log(`Updated:  ${updated}`);
  console.log(`Skipped:  ${skipped}`);
  console.log(`Errors:   ${errors}`);
  console.log(`Total:    ${providersSnapshot.size}`);
  console.log('='.repeat(50) + '\n');
  
  process.exit(errors > 0 ? 1 : 0);
}

// Run migration
migrateProviderAnalytics().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
