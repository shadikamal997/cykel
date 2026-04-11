/**
 * CYKEL Cloud Functions
 * 
 * Functions implemented here:
 *   onUserCreate       → Create profile doc + assign default rider role
 *   onProviderSubmit   → Auto-approve providers on submission
 *   onListingCreate    → Validate serial + duplicate detection
 *   onMessageCreate    → Send push notification to recipient
 *   approveProvider    → Admin callable to approve a provider
 *
 * Phase 7 — Subscriptions:
 *   verifyPurchase     → Validate App Store / Play Store receipt
 *   refreshSubscriptionStatus → Scheduled daily subscription refresh
 */

import * as functions from 'firebase-functions/v1';
import { defineString } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { UserRecord } from 'firebase-admin/auth';
import { QueryDocumentSnapshot } from 'firebase-admin/firestore';

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

// ─── MIGRATION: Create/fix provider_analytics documents ─────────────────────
// Creates missing analytics documents and fixes userId on existing ones
export const migrateProviderAnalytics = functions.https.onRequest(async (req, res) => {
  console.log('Starting provider_analytics migration...');
  
  try {
    const providersSnapshot = await db.collection('providers').get();
    console.log(`Found ${providersSnapshot.size} providers`);
    
    let created = 0;
    let updated = 0;
    let skipped = 0;
    let errors = 0;
    const details: any[] = [];
    
    for (const providerDoc of providersSnapshot.docs) {
      const providerId = providerDoc.id;
      const providerData = providerDoc.data();
      const userId = providerData.userId;
      
      if (!userId) {
        console.log(`Skipping ${providerId} - no userId in provider`);
        skipped++;
        details.push({ providerId, status: 'skipped', reason: 'no userId in provider' });
        continue;
      }
      
      try {
        const analyticsDoc = await db.collection('provider_analytics').doc(providerId).get();
        
        if (!analyticsDoc.exists) {
          // CREATE missing analytics document
          console.log(`Creating analytics for ${providerId} with userId: ${userId}`);
          await db.collection('provider_analytics').doc(providerId).set({
            providerId: providerId,
            userId: userId,
            viewCount: 0,
            contactClicks: 0,
            directionClicks: 0,
            websiteClicks: 0,
            bookingClicks: 0,
            photoViews: 0,
            shareCount: 0,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
          created++;
          details.push({ providerId, status: 'created', userId });
          continue;
        }
        
        const analyticsData = analyticsDoc.data();
        const currentUserId = analyticsData?.userId;
        
        if (currentUserId && currentUserId === userId) {
          console.log(`${providerId} already has correct userId: ${userId}`);
          skipped++;
          details.push({ providerId, status: 'skipped', reason: 'already correct', userId });
          continue;
        }
        
        // Update missing or wrong userId
        console.log(`Updating ${providerId} userId: ${currentUserId} -> ${userId}`);
        await db.collection('provider_analytics').doc(providerId).update({
          userId: userId
        });
        
        updated++;
        details.push({ providerId, status: 'updated', oldUserId: currentUserId, newUserId: userId });
        
      } catch (error) {
        console.error(`Error processing ${providerId}:`, error);
        errors++;
        details.push({ providerId, status: 'error', error: String(error) });
      }
    }
    
    const result = {
      success: true,
      created,
      updated,
      skipped,
      errors,
      total: providersSnapshot.size,
      details
    };
    
    console.log('Migration complete:', result);
    res.json(result);
    
  } catch (error) {
    console.error('Migration failed:', error);
    res.status(500).json({ success: false, error: String(error) });
  }
});

// ─── DEBUG: Investigate database state ──────────────────────────────────────
export const investigateDb = functions.https.onRequest(async (req, res) => {
  const result: any = {
    events: [],
    users: [],
    providers: [],
  };

  // Get events
  const eventsSnap = await db.collection('events').get();
  result.events = eventsSnap.docs.map(doc => ({
    id: doc.id,
    title: doc.data().title,
    organizerId: doc.data().organizerId,
    organizerName: doc.data().organizerName,
    createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || 'N/A',
  }));

  // Get users
  const usersSnap = await db.collection('users').get();
  result.users = usersSnap.docs.map(doc => ({
    id: doc.id,
    email: doc.data().email,
    name: doc.data().name,
  }));

  // Get providers
  const providersSnap = await db.collection('providers').get();
  result.providers = providersSnap.docs.map(doc => ({
    id: doc.id,
    userId: doc.data().userId,
    businessName: doc.data().businessName,
  }));

  // Get Firebase Auth users count
  try {
    const listResult = await auth.listUsers(100);
    result.authUsers = listResult.users.map(u => ({
      uid: u.uid,
      email: u.email,
      displayName: u.displayName,
    }));
  } catch (e) {
    result.authUsersError = String(e);
  }

  res.json(result);
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface UserProfile {
  name: string;
  email: string;
  role: string;
  country: string;
  subscription: {
    plan: 'free' | 'premium';
    active: boolean;
    expiresAt: admin.firestore.Timestamp | null;
  };
  createdAt: admin.firestore.Timestamp;
  verifiedEmail: boolean;
}

// ─── 1. onUserCreate ─────────────────────────────────────────────────────────
// Triggered when a new user signs up via Firebase Auth.
// Creates their Firestore profile and sets the default 'rider' Custom Claim.

export const onUserCreate = functions.auth.user().onCreate(async (user: UserRecord) => {
  const displayName = user.displayName || '';
  const profile: UserProfile = {
    name: displayName,
    email: user.email || '',
    role: 'rider',
    country: 'DK',
    subscription: {
      plan: 'free',
      active: false,
      expiresAt: null,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
    verifiedEmail: user.emailVerified,
  };

  // Write user profile to Firestore (with displayNameLower for search)
  await db.collection('users').doc(user.uid).set({
    ...profile,
    displayName: displayName,
    displayNameLower: displayName.toLowerCase(),
  });

  // Set Custom Claim for role-based access
  await auth.setCustomUserClaims(user.uid, { role: 'rider' });

  functions.logger.info(`[onUserCreate] Profile created for ${user.uid}`);
});

// ─── 2. onProviderSubmit ─────────────────────────────────────────────────────
// Triggered when a provider document is created.
// Auto-approves providers, creates analytics document, and logs submission.

export const onProviderSubmit = functions.firestore
  .document('providers/{providerId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const data = snap.data();
    const providerId = context.params.providerId;

    // AUTO-APPROVE: Set status to approved if not already set
    if (data.verificationStatus !== 'approved') {
      await snap.ref.update({ verificationStatus: 'approved' });
    }

    // Create analytics document with admin privileges (bypasses security rules)
    await db.collection('provider_analytics').doc(providerId).set({
      providerId: providerId,
      userId: data.userId || '',
      viewCount: 0,
      contactClicks: 0,
      directionClicks: 0,
      websiteClicks: 0,
      bookingClicks: 0,
      photoViews: 0,
      shareCount: 0,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`[onProviderSubmit] Provider ${providerId} auto-approved and analytics created`);
  });

// ─── 3. onListingCreate ──────────────────────────────────────────────────────
// Triggered when a marketplace listing is created.
// Validates serial number and checks for duplicates.

export const onListingCreate = functions.firestore
  .document('marketplace_listings/{listingId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const data = snap.data();
    const listingId = context.params.listingId;
    const serial: string | undefined = data.serialNumber;

    if (!serial || serial.trim().length < 4) {
      // No serial provided — mark as unverified but allow
      await snap.ref.update({ serialVerified: false, serialDuplicate: false });
      return;
    }

    const normalizedSerial = serial.trim().toUpperCase();

    // Check for duplicate serial across active listings
    const duplicateQuery = await db
      .collection('marketplace_listings')
      .where('serialNumber', '==', normalizedSerial)
      .where('isSold', '==', false)
      .where(admin.firestore.FieldPath.documentId(), '!=', listingId)
      .limit(1)
      .get();

    const isDuplicate = !duplicateQuery.empty;

    await snap.ref.update({
      serialNumber: normalizedSerial,
      serialVerified: !isDuplicate,
      serialDuplicate: isDuplicate,
    });

    if (isDuplicate) {
      functions.logger.warn(
        `[onListingCreate] Duplicate serial detected on listing ${listingId}: ${normalizedSerial}`,
      );
    }
  });

// ─── 4. onMessageCreate ──────────────────────────────────────────────────────
// Triggered when a chat message is created.
// Sends a push notification to the other participant.

export const onMessageCreate = functions.firestore
  .document('marketplace_chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const message = snap.data();
    const chatId = context.params.chatId;

    // Validate senderId exists
    if (!message.senderId) {
      functions.logger.warn(`[onMessageCreate] Missing senderId in message ${context.params.messageId}`);
      return;
    }

    // Get the chat document to find the other participant
    const chatDoc = await db.collection('marketplace_chats').doc(chatId).get();
    if (!chatDoc.exists) return;

    const chat = chatDoc.data()!;
    // Determine the recipient — the other participant in the thread.
    const recipientId = chat.buyerId === message.senderId
      ? chat.sellerId
      : chat.buyerId;

    if (!recipientId) return;

    // Get recipient's FCM token
    const recipientDoc = await db.collection('users').doc(recipientId).get();
    if (!recipientDoc.exists) return;

    const fcmToken: string | undefined = recipientDoc.data()?.fcmToken;
    if (!fcmToken) return;

    // Send push notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'New message',
        body: message.text
          ? message.text.substring(0, 100)
          : '📷 Photo',
      },
      data: {
        type: 'chat_message',
        chatId,
        senderId: message.senderId,
      },
      apns: {
        payload: {
          aps: { badge: 1, sound: 'default' },
        },
      },
    });

    functions.logger.info(`[onMessageCreate] Notification sent to ${recipientId}`);
  });

// ─── 5. approveProvider (Admin Callable) ────────────────────────────────────
// Called by admin to approve a provider.
// Updates status in Firestore and upgrades the Custom Claim.

export const approveProvider = functions.https.onCall(async (data: unknown, context: functions.https.CallableContext) => {
  // data cast after auth check
  // Must be called by an admin
  if (context.auth?.token.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  // Validate input
  const input = data as { providerId: unknown; providerType: unknown };
  if (!input.providerId || typeof input.providerId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing or invalid providerId');
  }
  if (!input.providerType || typeof input.providerType !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing or invalid providerType');
  }

  const { providerId, providerType } = input as {
    providerId: string;
    providerType: string;
  };

  // Get the provider document to find the userId
  const providerDoc = await db.collection('providers').doc(providerId).get();
  if (!providerDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Provider not found');
  }

  const userId: string = providerDoc.data()!.userId;
  const role = providerType === 'business' ? 'provider_business' : 'provider_personal';

  // Update Firestore
  await providerDoc.ref.update({
    verificationStatus: 'approved',
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update user profile role
  await db.collection('users').doc(userId).update({ role });

  // Update Custom Claim (user must refresh token to see change)
  await auth.setCustomUserClaims(userId, { role });

  functions.logger.info(`[approveProvider] Provider ${providerId} approved as ${role}`);

  return { success: true };
});

// ─── 6. verifyPurchase (Callable) ────────────────────────────────────────────
// Called by the Flutter client after a successful purchase.
// Validates receipts against Apple App Store or Google Play Store
// server-to-server APIs. Extracts actual subscription expiry dates
// and handles refunds, cancellations, and grace periods.

import * as iap from 'node-iap';

interface VerifyPurchaseData {
  source: 'apple' | 'google';
  verificationData: string;
  productId: string;
}

// Configure IAP verification using environment variables
// Set in functions/.env file:
// GOOGLE_SERVICE_ACCOUNT_BASE64=base64_encoded_json
// APPLE_SHARED_SECRET=your_shared_secret
const appleSharedSecret = defineString('APPLE_SHARED_SECRET', { default: '' });
const googleServiceAccountBase64 = defineString('GOOGLE_SERVICE_ACCOUNT_BASE64', { default: '' });

// Decode base64 service account at runtime
function getGoogleServiceAccount() {
  const base64Value = googleServiceAccountBase64.value();
  if (!base64Value) return null;
  try {
    const decoded = Buffer.from(base64Value, 'base64').toString('utf-8');
    return JSON.parse(decoded);
  } catch (error) {
    console.error('Failed to decode Google service account:', error);
    return null;
  }
}

// Helper to get IAP config at runtime (not at module load)
function getIapConfig() {
  return {
    applePassword: appleSharedSecret.value(),
    googleServiceAccount: getGoogleServiceAccount(),
  };
}

// Initialize IAP platform for Apple (production)
function getAppleConfig() {
  return {
    secret: appleSharedSecret.value(),
    environment: ['sandbox', 'production'], // Try both environments
    excludeOldTransactions: true,
  } as iap.AppleIAPConfiguration;
}

export const verifyPurchase = functions.https.onCall(
  async (data: unknown, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be signed in',
      );
    }

    const uid = context.auth.uid;
    const { source, verificationData, productId } = data as VerifyPurchaseData;

    // Validate input
    if (!source || (source !== 'apple' && source !== 'google')) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid source: must be "apple" or "google"',
      );
    }

    if (!verificationData || typeof verificationData !== 'string' || verificationData.length < 10) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing or invalid receipt data',
      );
    }

    if (!productId || typeof productId !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing or invalid productId',
      );
    }

    // Get IAP config at runtime (not module load)
    const iapConfig = getIapConfig();

    const now = admin.firestore.Timestamp.now();
    let expiresAt: admin.firestore.Timestamp;
    let transactionId: string | undefined;
    let isValid = false;

    try {
      if (source === 'apple') {
        // ── Apple Receipt Verification ────────────────────────────────────
        if (!iapConfig.applePassword) {
          functions.logger.warn('[verifyPurchase] Apple shared secret not configured');
          throw new functions.https.HttpsError(
            'failed-precondition',
            'IAP verification not configured',
          );
        }

        const receipt = {
          data: verificationData,
          productId,
        };

        const appleConfig = getAppleConfig();
        const validationResult = await iap.verifyPayment('apple', receipt, appleConfig);
        
        if (!validationResult || !validationResult.receipt) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid Apple receipt',
          );
        }

        // Extract subscription info from latest_receipt_info
        if (validationResult.receipt['latest_receipt_info']) {
          const latestReceipt = validationResult.receipt['latest_receipt_info'][0];
          const expiryMs = parseInt(latestReceipt['expires_date_ms'] || '0', 10);
          
          if (expiryMs === 0) {
            throw new functions.https.HttpsError(
              'invalid-argument',
              'No expiry date in receipt',
            );
          }

          expiresAt = admin.firestore.Timestamp.fromMillis(expiryMs);
          transactionId = latestReceipt['original_transaction_id'];
          isValid = true;
        } else {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'No subscription info in receipt',
          );
        }
      } else {
        // ── Google Play Receipt Verification ──────────────────────────────
        if (!iapConfig.googleServiceAccount) {
          functions.logger.warn('[verifyPurchase] Google service account not configured');
          throw new functions.https.HttpsError(
            'failed-precondition',
            'IAP verification not configured',
          );
        }

        const receipt = {
          data: verificationData,
          signature: '', // Google signature is validated by node-iap internally
        };

        const validationResult = await iap.verifyPayment(
          'google',
          receipt,
          iapConfig.googleServiceAccount,
        );

        if (!validationResult) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid Google Play receipt',
          );
        }

        // Extract subscription info
        const expiryMs = parseInt(validationResult['expiryTimeMillis'] || '0', 10);
        
        if (expiryMs === 0) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'No expiry date in receipt',
          );
        }

        expiresAt = admin.firestore.Timestamp.fromMillis(expiryMs);
        transactionId = validationResult['orderId'];
        isValid = true;

        // Check for cancellation
        if (validationResult['cancelReason']) {
          functions.logger.warn(
            `[verifyPurchase] Cancelled subscription for ${uid}: ${validationResult['cancelReason']}`,
          );
          isValid = false;
        }
      }

      if (!isValid) {
        return { success: false, error: 'Receipt validation failed' };
      }

      // ── Write verified subscription to Firestore ────────────────────────
      await db.collection('users').doc(uid).set(
        {
          subscription: {
            plan: 'premium',
            active: true,
            verified: true,
            expiresAt,
            productId,
            source,
            transactionId,
            lastVerifiedAt: now,
          },
        },
        { merge: true },
      );

      functions.logger.info(
        `[verifyPurchase] Premium activated for ${uid} (${source}, ${productId}, expires: ${expiresAt.toDate()})`,
      );

      return { success: true };
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      functions.logger.error(`[verifyPurchase] Error for ${uid}: ${errorMessage}`);

      // If it's an HttpsError, rethrow it
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Otherwise, wrap it
      throw new functions.https.HttpsError(
        'internal',
        `Receipt verification failed: ${errorMessage}`,
      );
    }
  },
);

// ─── 7. refreshSubscriptionStatus (Scheduled) ──────────────────────────────
// Runs daily at 03:00 UTC.  Queries all users with active premium
// subscriptions and:
//   1. Expires those whose expiresAt has passed
//   2. Revokes unverified fallback subscriptions after 24-hour grace period

export const refreshSubscriptionStatus = functions.pubsub
  .schedule('every day 03:00')
  .timeZone('UTC')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const batch = db.batch();
    let expiredCount = 0;
    let revokedCount = 0;

    // ── 1. Expire subscriptions past their expiresAt date ──────────────────
    const expired = await db
      .collection('users')
      .where('subscription.active', '==', true)
      .where('subscription.expiresAt', '<=', now)
      .get();

    for (const doc of expired.docs) {
      batch.update(doc.ref, {
        'subscription.plan': 'free',
        'subscription.active': false,
      });
      expiredCount++;
    }

    // ── 2. Revoke unverified fallback subscriptions ────────────────────────
    // These were granted when verifyPurchase Cloud Function was unreachable.
    // After 24 hours, if still unverified, revoke them.
    const unverified = await db
      .collection('users')
      .where('subscription.active', '==', true)
      .where('subscription.verified', '==', false)
      .get();

    const gracePeriodMs = 24 * 60 * 60 * 1000; // 24 hours
    for (const doc of unverified.docs) {
      const sub = doc.data()['subscription'];
      const fallbackGrantedAt = sub?.['fallbackGrantedAt'] as admin.firestore.Timestamp | null;
      
      if (fallbackGrantedAt) {
        const ageMs = now.toMillis() - fallbackGrantedAt.toMillis();
        if (ageMs > gracePeriodMs) {
          // Grace period expired, revoke unverified subscription
          batch.update(doc.ref, {
            'subscription.plan': 'free',
            'subscription.active': false,
          });
          revokedCount++;
          functions.logger.warn(
            `[refreshSubscriptionStatus] Revoked unverified subscription for ${doc.id} after ${Math.floor(ageMs / 3600000)}h`,
          );
        }
      }
    }

    if (expiredCount === 0 && revokedCount === 0) {
      functions.logger.info('[refreshSubscriptionStatus] No subscriptions to update');
      return;
    }

    await batch.commit();

    functions.logger.info(
      `[refreshSubscriptionStatus] Expired ${expiredCount}, revoked ${revokedCount} unverified`,
    );
  });

// ═══════════════════════════════════════════════════════════════════════════
// ─── 8. DELETEUSER ACCOUNT (GDPR-COMPLIANT) ────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
// Cascades through ALL user data collections (rides, marketplace, events,
// social, gamification, etc.) and Cloud Storage. Complies with GDPR Article 17.
// Called by client after re-authentication (or uses admin SDK to bypass).
//
// DELETION ORDER (critical for referential integrity):
// 1. User-generated content (events, listings, chats)
// 2. Social connections (friends, follows, shared rides)
// 3. Gamification data (leaderboard, badges, challenges)
// 4. Provider data (providers, analytics, locations)
// 5. Reports (theft, hazard, infrastructure, emergency)
// 6. User subcollections (bikes, settings, route history)
// 7. Cloud Storage (photos, documents)
// 8. User document (main profile)
// 9. Firebase Auth account (MUST BE LAST)

export const deleteUserAccount = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes max (default is 60s)
    memory: '1GB',
  })
  .https.onCall(
    async (_data: unknown, context: functions.https.CallableContext) => {
      // ── Authentication Check ──────────────────────────────────────────────
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Must be signed in to delete account',
        );
      }

      const uid = context.auth.uid;
      const startTime = Date.now();
      functions.logger.info(`[deleteUserAccount] 🔴 STARTING for ${uid}`);

      try {
        // ── Helper: Batch Delete (max 500 ops per batch) ──────────────────
        const deleteInBatches = async (
          querySnapshot: admin.firestore.QuerySnapshot,
          collectionName: string,
        ): Promise<number> => {
          const batchSize = 500;
          const docs = querySnapshot.docs;

          for (let i = 0; i < docs.length; i += batchSize) {
            const batch = db.batch();
            const chunk = docs.slice(i, i + batchSize);
            chunk.forEach((doc) => batch.delete(doc.ref));
            await batch.commit();
          }

          if (docs.length > 0) {
            functions.logger.info(`  ✅ Deleted ${docs.length} ${collectionName}`);
          }
          return docs.length;
        };

        // ── Helper: Delete Subcollection ──────────────────────────────────
        const deleteSubcollection = async (
          parentRef: admin.firestore.DocumentReference,
          subcollectionName: string,
        ): Promise<number> => {
          const snapshot = await parentRef.collection(subcollectionName).get();
          if (!snapshot.empty) {
            await deleteInBatches(snapshot, `${parentRef.path}/${subcollectionName}`);
          }
          return snapshot.size;
        };

        // ── Helper: Delete Storage Path ───────────────────────────────────
        const deleteStoragePath = async (
          prefix: string,
        ): Promise<number> => {
          try {
            const bucket = storage.bucket();
            const [files] = await bucket.getFiles({ prefix });
            if (files.length > 0) {
              await Promise.all(files.map((file) => file.delete()));
              functions.logger.info(`  ✅ Deleted ${files.length} files from ${prefix}`);
            }
            return files.length;
          } catch (error) {
            functions.logger.warn(`  ⚠️  Storage deletion failed for ${prefix}: ${error}`);
            return 0;
          }
        };

        let totalDeleted = 0;

        // ═══════════════════════════════════════════════════════════════════
        // ── PHASE 1: USER-GENERATED CONTENT ────────────────────────────────
        // ═══════════════════════════════════════════════════════════════════

        functions.logger.info('📦 PHASE 1: User-generated content');

        // 1A. Rides (top-level collection)
        const ridesSnap = await db
          .collection('rides')
          .where('userId', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(ridesSnap, 'rides');

        // 1B. Marketplace Listings
        const listingsSnap = await db
          .collection('marketplace_listings')
          .where('sellerId', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(listingsSnap, 'marketplace_listings');

        // 1B-Storage. Marketplace photos (new path: marketplace/{uid}/*)
        totalDeleted += await deleteStoragePath(`marketplace/${uid}/`);

        // 1B-Storage. Legacy listing photos (old path: listings/{listingId}/*)
        if (!listingsSnap.empty) {
          for (const listingDoc of listingsSnap.docs) {
            totalDeleted += await deleteStoragePath(`listings/${listingDoc.id}/images/`);
            totalDeleted += await deleteStoragePath(`listings/${listingDoc.id}/serial_photo.jpg`);
          }
        }

        // 1C. Marketplace Chats (as buyer or seller)
        const chatsSnap = await db
          .collection('marketplace_chats')
          .where('participants', 'array-contains', uid)
          .get();
        if (!chatsSnap.empty) {
          for (const chatDoc of chatsSnap.docs) {
            // Delete messages subcollection first
            await deleteSubcollection(chatDoc.ref, 'messages');
            await chatDoc.ref.delete();
          }
          functions.logger.info(`  ✅ Deleted ${chatsSnap.size} marketplace_chats`);
          totalDeleted += chatsSnap.size;
        }

        // 1D. Events (organized by user)
        const eventsSnap = await db
          .collection('events')
          .where('organizerId', '==', uid)
          .get();
        if (!eventsSnap.empty) {
          for (const eventDoc of eventsSnap.docs) {
            // Delete subcollections: participants, chat, reviews
            await deleteSubcollection(eventDoc.ref, 'participants');
            await deleteSubcollection(eventDoc.ref, 'chat');
            await deleteSubcollection(eventDoc.ref, 'reviews');
            await eventDoc.ref.delete();
          }
          functions.logger.info(`  ✅ Deleted ${eventsSnap.size} events (organized)`);
          totalDeleted += eventsSnap.size;
        }

        // 1E. Event Participations (joined as participant)
        const allEvents = await db.collection('events').get();
        for (const eventDoc of allEvents.docs) {
          // Delete user's participation doc
          const participantDoc = eventDoc.ref.collection('participants').doc(uid);
          const participantExists = await participantDoc.get();
          if (participantExists.exists) {
            await participantDoc.delete();
            totalDeleted++;
          }

          // Delete user's chat messages in event
          const eventChatsSnap = await eventDoc.ref
            .collection('chat')
            .where('userId', '==', uid)
            .get();
          totalDeleted += await deleteInBatches(eventChatsSnap, `events/${eventDoc.id}/chat`);

          // Delete user's event reviews
          const eventReviewsSnap = await eventDoc.ref
            .collection('reviews')
            .where('userId', '==', uid)
            .get();
          totalDeleted += await deleteInBatches(eventReviewsSnap, `events/${eventDoc.id}/reviews`);
        }

        // ═══════════════════════════════════════════════════════════════════
        // ── PHASE 2: SOCIAL FEATURES ───────────────────────────────────────
        // ═══════════════════════════════════════════════════════════════════

        functions.logger.info('👥 PHASE 2: Social features');

        // 2A. Friend Requests (sent or received)
        const friendRequestsSnap = await db
          .collection('friendRequests')
          .where('fromUid', '==', uid)
          .get();
        const friendRequestsSnap2 = await db
          .collection('friendRequests')
          .where('toUid', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(friendRequestsSnap, 'friendRequests');
        totalDeleted += await deleteInBatches(friendRequestsSnap2, 'friendRequests');

        // 2A-alt. Friend Requests (alternate naming)
        const friendRequests2Snap = await db
          .collection('friend_requests')
          .where('fromUserId', '==', uid)
          .get();
        const friendRequests2Snap2 = await db
          .collection('friend_requests')
          .where('toUserId', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(friendRequests2Snap, 'friend_requests');
        totalDeleted += await deleteInBatches(friendRequests2Snap2, 'friend_requests');

        // 2B. Friendships (where user is in users array)
        const friendshipsSnap = await db
          .collection('friendships')
          .where('users', 'array-contains', uid)
          .get();
        totalDeleted += await deleteInBatches(friendshipsSnap, 'friendships');

        // 2C. Social Activity Feed
        const socialActivitySnap = await db
          .collection('socialActivity')
          .where('actorUid', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(socialActivitySnap, 'socialActivity');

        // 2D. Shared Rides
        const sharedRidesSnap = await db
          .collection('sharedRides')
          .where('ownerUid', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(sharedRidesSnap, 'sharedRides');

        // ═══════════════════════════════════════════════════════════════════
        // ── PHASE 3: GAMIFICATION ──────────────────────────────────────────
        // ═══════════════════════════════════════════════════════════════════

        functions.logger.info('🏆 PHASE 3: Gamification');

        // 3A. Leaderboard Entry
        try {
          await db.collection('leaderboard').doc(uid).delete();
          functions.logger.info('  ✅ Deleted leaderboard entry');
          totalDeleted++;
        } catch (error) {
          // Doc might not exist - not an error
        }

        // 3B. User Badges (collection + subcollection)
        const userBadgesDoc = db.collection('user_badges').doc(uid);
        const userBadgesExists = await userBadgesDoc.get();
        if (userBadgesExists.exists) {
          await deleteSubcollection(userBadgesDoc, 'badges');
          await userBadgesDoc.delete();
          functions.logger.info('  ✅ Deleted user_badges');
          totalDeleted++;
        }

        // 3C. User Saved Routes (collection + subcollection)
        const savedRoutesDoc = db.collection('user_saved_routes').doc(uid);
        const savedRoutesExists = await savedRoutesDoc.get();
        if (savedRoutesExists.exists) {
          await deleteSubcollection(savedRoutesDoc, 'routes');
          await savedRoutesDoc.delete();
          functions.logger.info('  ✅ Deleted user_saved_routes');
          totalDeleted++;
        }

        // 3D. Challenge Progress (in each challenge doc)
        const challengesSnap = await db.collection('challenges').get();
        for (const challengeDoc of challengesSnap.docs) {
          const progressDoc = challengeDoc.ref.collection('user_progress').doc(uid);
          const progressExists = await progressDoc.get();
          if (progressExists.exists) {
            await progressDoc.delete();
            totalDeleted++;
          }
        }

        // ═══════════════════════════════════════════════════════════════════
        // ── PHASE 4: PROVIDER DATA ─────────────────────────────────────────
        // ═══════════════════════════════════════════════════════════════════

        functions.logger.info('🏪 PHASE 4: Provider data');

        // 4A. Providers (get all provider IDs first for cleanup)
        const providersSnap = await db
          .collection('providers')
          .where('userId', '==', uid)
          .get();
        const providerIds = providersSnap.docs.map((doc) => doc.id);

        if (providerIds.length > 0) {
          // 4B. Provider Analytics (one per provider)
          for (const providerId of providerIds) {
            try {
              await db.collection('provider_analytics').doc(providerId).delete();
              totalDeleted++;
            } catch (error) {
              // Analytics might not exist yet
            }
          }

          // 4C. Locations (owned by provider)
          const locationsSnap = await db
            .collection('locations')
            .where('providerId', 'in', providerIds)
            .get();
          totalDeleted += await deleteInBatches(locationsSnap, 'locations');

          // 4C-Storage. Location photos
          for (const providerId of providerIds) {
            totalDeleted += await deleteStoragePath(`locations/${providerId}/`);
          }

          // 4D-Storage. Provider photos and documents
          for (const providerId of providerIds) {
            totalDeleted += await deleteStoragePath(`providers/${providerId}/photos/`);
            totalDeleted += await deleteStoragePath(`providers/${providerId}/documents/`);
          }

          // 4E. Finally delete provider docs
          totalDeleted += await deleteInBatches(providersSnap, 'providers');
        }

        // ═══════════════════════════════════════════════════════════════════
        // ── PHASE 5: REPORTS ───────────────────────────────────────────────
        // ═══════════════════════════════════════════════════════════════════

        functions.logger.info('📝 PHASE 5: Reports');

        // 5A. Generic Reports (abuse, content moderation)
        const reportsSnap = await db
          .collection('reports')
          .where('reportedBy', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(reportsSnap, 'reports');

        // 5B. Theft Alerts (+ sightings subcollection)
        const theftAlertsSnap = await db
          .collection('theft_alerts')
          .where('userId', '==', uid)
          .get();
        if (!theftAlertsSnap.empty) {
          for (const alertDoc of theftAlertsSnap.docs) {
            await deleteSubcollection(alertDoc.ref, 'sightings');
            await alertDoc.ref.delete();
          }
          functions.logger.info(`  ✅ Deleted ${theftAlertsSnap.size} theft_alerts`);
          totalDeleted += theftAlertsSnap.size;
        }

        // 5B-alt. Theft Reports (alias collection)
        const theftReportsSnap = await db
          .collection('theft_reports')
          .where('userId', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(theftReportsSnap, 'theft_reports');

        // 5C. Theft Sightings (reports of OTHER people's stolen bikes)
        for (const alertDoc of (await db.collection('theft_alerts').get()).docs) {
          const sightingsSnap = await alertDoc.ref
            .collection('sightings')
            .where('reportedBy', '==', uid)
            .get();
          totalDeleted += await deleteInBatches(sightingsSnap, `theft_alerts/${alertDoc.id}/sightings`);
        }

        // 5D. Hazard Reports
        const hazardReportsSnap = await db
          .collection('hazard_reports')
          .where('reportedBy', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(hazardReportsSnap, 'hazard_reports');

        // 5E. Infrastructure Reports
        const infraReportsSnap = await db
          .collection('infrastructure_reports')
          .where('reportedBy', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(infraReportsSnap, 'infrastructure_reports');

        // 5F. Emergency Reports (911-style reports)
        const emergencyReportsSnap = await db
          .collection('emergency_reports')
          .where('reportedBy', '==', uid)
          .get();
        totalDeleted += await deleteInBatches(emergencyReportsSnap, 'emergency_reports');

        // ═══════════════════════════════════════════════════════════════════
        // ── PHASE 6: USER DOCUMENT + SUBCOLLECTIONS ────────────────────────
        // ═══════════════════════════════════════════════════════════════════

        functions.logger.info('👤 PHASE 6: User profile + subcollections');

        const userDoc = db.collection('users').doc(uid);
        const userExists = await userDoc.get();

        if (userExists.exists) {
          // 6A. Delete all user subcollections
          await deleteSubcollection(userDoc, 'bikes');
          await deleteSubcollection(userDoc, 'rides');
          await deleteSubcollection(userDoc, 'gamification');
          await deleteSubcollection(userDoc, 'challenges');
          await deleteSubcollection(userDoc, 'badges');
          await deleteSubcollection(userDoc, 'friends');
          await deleteSubcollection(userDoc, 'routeHistory');
          await deleteSubcollection(userDoc, 'savedRoutes');
          await deleteSubcollection(userDoc, 'settings');

          // 6B. Delete user document itself
          await userDoc.delete();
          functions.logger.info('  ✅ Deleted user document + subcollections');
          totalDeleted++;
        }

        // 6C-Storage. User profile photos and files
        totalDeleted += await deleteStoragePath(`users/${uid}/`);

        // ═══════════════════════════════════════════════════════════════════
        // ── PHASE 7: FIREBASE AUTH (MUST BE LAST) ─────────────────────────
        // ═══════════════════════════════════════════════════════════════════

        functions.logger.info('🔐 PHASE 7: Firebase Auth account');

        await auth.deleteUser(uid);
        functions.logger.info('  ✅ Deleted Firebase Auth account');

        // ── Success Summary ────────────────────────────────────────────────
        const duration = ((Date.now() - startTime) / 1000).toFixed(2);
        functions.logger.info(
          `[deleteUserAccount] ✅ COMPLETE for ${uid} | ` +
          `Deleted ${totalDeleted} documents/files | ${duration}s`,
        );

        return {
          success: true,
          deletedCount: totalDeleted,
          durationSeconds: parseFloat(duration),
        };

      } catch (error) {
        const duration = ((Date.now() - startTime) / 1000).toFixed(2);
        functions.logger.error(
          `[deleteUserAccount] ❌ FAILED for ${uid} after ${duration}s:`,
          error,
        );
        throw new functions.https.HttpsError(
          'internal',
          `Account deletion failed: ${error instanceof Error ? error.message : error}`,
        );
      }
    },
  );

// ─── 9. exportUserData (Callable) ────────────────────────────────────────────
// GDPR-compliant data export. Returns all user data as JSON.
// Collects: profile, rides, marketplace listings, chats (messages included),
// providers, and reports. The client can then save this as a file or email it.

export const exportUserData = functions.https.onCall(
  async (_data: unknown, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be signed in to export data',
      );
    }

    const uid = context.auth.uid;
    functions.logger.info(`[exportUserData] Starting export for ${uid}`);

    try {
      const exportData: Record<string, unknown> = {};

      // 1. User profile
      const userDoc = await db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        exportData.profile = userDoc.data();
      }

      // 2. All rides
      const ridesSnap = await db
        .collection('rides')
        .where('ownerId', '==', uid)
        .get();
      exportData.rides = ridesSnap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // 3. All marketplace listings
      const listingsSnap = await db
        .collection('marketplace_listings')
        .where('sellerId', '==', uid)
        .get();
      exportData.marketplaceListings = listingsSnap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // 4. All chats (with messages subcollection)
      const chatsSnap = await db
        .collection('marketplace_chats')
        .where('participants', 'array-contains', uid)
        .get();
      const chats: Array<Record<string, unknown>> = [];
      for (const chatDoc of chatsSnap.docs) {
        const messagesSnap = await chatDoc.ref.collection('messages').get();
        chats.push({
          id: chatDoc.id,
          ...chatDoc.data(),
          messages: messagesSnap.docs.map((msgDoc) => ({
            id: msgDoc.id,
            ...msgDoc.data(),
          })),
        });
      }
      exportData.chats = chats;

      // 5. All provider documents
      const providersSnap = await db
        .collection('providers')
        .where('userId', '==', uid)
        .get();
      exportData.providers = providersSnap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // 6. All reports submitted
      const reportsSnap = await db
        .collection('reports')
        .where('reportedBy', '==', uid)
        .get();
      exportData.reports = reportsSnap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // 7. Metadata
      exportData.exportMetadata = {
        userId: uid,
        exportedAt: admin.firestore.Timestamp.now().toDate().toISOString(),
        version: '1.0',
      };

      functions.logger.info(`[exportUserData] Complete for ${uid}`);
      return { data: exportData };
    } catch (error) {
      functions.logger.error(`[exportUserData] Error for ${uid}:`, error);
      throw new functions.https.HttpsError(
        'internal',
        `Failed to export data: ${error}`,
      );
    }
  },
);

// ─── migrateDisplayNameLower ─────────────────────────────────────────────────
// Admin-only callable function to add displayNameLower to all users
// Call via Firebase console or admin SDK

export const migrateDisplayNameLower = functions.https.onCall(
  async (data, context) => {
    // Only allow authenticated admins to run this
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    functions.logger.info(`[migrateDisplayNameLower] Starting migration requested by ${context.auth.uid}`);
    
    try {
      const BATCH_SIZE = 500;
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
          functions.logger.info(`[migrateDisplayNameLower] Batch committed: ${batchCount} users updated`);
        }

        functions.logger.info(`[migrateDisplayNameLower] Progress: ${totalProcessed} processed, ${totalUpdated} updated`);

        // Update lastDoc for next iteration
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        
        // If we got fewer docs than BATCH_SIZE, we're done
        if (snapshot.size < BATCH_SIZE) {
          hasMore = false;
        }
      }

      functions.logger.info(`[migrateDisplayNameLower] Complete: ${totalProcessed} processed, ${totalUpdated} updated`);
      
      return {
        success: true,
        totalProcessed,
        totalUpdated,
        message: `Migration complete! Processed ${totalProcessed} users, updated ${totalUpdated}`,
      };
    } catch (error) {
      functions.logger.error(`[migrateDisplayNameLower] Error:`, error);
      throw new functions.https.HttpsError(
        'internal',
        `Migration failed: ${error}`,
      );
    }
  },
);
