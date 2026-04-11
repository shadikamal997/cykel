/**
 * Migration script to add userId to existing provider_analytics documents
 * Run once with: firebase functions:shell
 * Then: migrateProviderAnalytics()
 */

import * as admin from 'firebase-admin';

export async function migrateProviderAnalytics() {
  const db = admin.firestore();
  
  console.log('Starting provider_analytics migration...');
  
  // Get all providers
  const providersSnapshot = await db.collection('providers').get();
  console.log(`Found ${providersSnapshot.size} providers`);
  
  let updated = 0;
  let skipped = 0;
  let errors = 0;
  
  for (const providerDoc of providersSnapshot.docs) {
    const providerId = providerDoc.id;
    const providerData = providerDoc.data();
    const userId = providerData.userId;
    
    if (!userId) {
      console.log(`Skipping ${providerId} - no userId in provider doc`);
      skipped++;
      continue;
    }
    
    try {
      // Check if analytics doc exists
      const analyticsDoc = await db.collection('provider_analytics').doc(providerId).get();
      
      if (!analyticsDoc.exists) {
        console.log(`No analytics doc for provider ${providerId}, skipping`);
        skipped++;
        continue;
      }
      
      const analyticsData = analyticsDoc.data();
      if (analyticsData?.userId) {
        console.log(`Provider ${providerId} already has userId, skipping`);
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
      console.error(`Error updating provider ${providerId}:`, error);
      errors++;
    }
  }
  
  console.log('\n=== Migration Complete ===');
  console.log(`Updated: ${updated}`);
  console.log(`Skipped: ${skipped}`);
  console.log(`Errors: ${errors}`);
  console.log(`Total: ${providersSnapshot.size}`);
  
  return { updated, skipped, errors, total: providersSnapshot.size };
}
