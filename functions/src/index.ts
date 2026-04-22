/**
 * CYKEL Cloud Functions
 * 
 * Functions implemented here:
 *   onUserCreate       → Create profile doc + assign default rider role
 *   onProviderSubmit   → Auto-approve providers on submission
 *   onListingCreate    → Validate serial + duplicate detection
 *   onMessageCreate    → Send push notification to recipient
 *   approveProvider    → Admin callable to approve a provider
 *   generateThumbnail  → Auto-generate 300x300 thumbnail for uploaded images
 *
 * Phase 7 — Subscriptions:
 *   verifyPurchase     → Validate App Store / Play Store receipt
 *   refreshSubscriptionStatus → Scheduled daily subscription refresh
 * 
 * SECURITY FIXES (April 2026):
 *   cleanupOldMessages → Auto-delete chat messages >90 days (GDPR compliance)
 *   monitorSecurity    → Detect spam/DoS attacks and send alerts
 *   getSecurityAlerts  → Admin dashboard for security monitoring
 *   manualCleanupMessages → Admin-triggered message cleanup
 */

import * as functions from 'firebase-functions/v1';
import { defineString } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { UserRecord } from 'firebase-admin/auth';
import { QueryDocumentSnapshot } from 'firebase-admin/firestore';
import sharp from 'sharp';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';

// Import security modules
import { getRateLimitInfo, clearRateLimit, cleanupOldRateLimits } from './middleware/rateLimit';
import { cleanupOldMessages, manualCleanupMessages } from './scheduled/cleanupOldMessages';
import { monitorSecurity, getSecurityAlerts } from './scheduled/securityMonitoring';

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

// ─── THUMBNAIL GENERATION ───────────────────────────────────────────────────
// Automatically generates 300x300 thumbnails for uploaded images
// Triggers on any object uploaded to Firebase Storage
export const generateThumbnail = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name;
  const fileBucket = object.bucket;

  // Skip if not an image or already a thumbnail
  if (!filePath) return;
  if (filePath.startsWith('thumbnails/')) {
    console.log(`Skipping thumbnail generation for: ${filePath} (already in thumbnails/)`);
    return;
  }
  if (!filePath.match(/\.(jpg|jpeg|png|webp)$/i)) {
    console.log(`Skipping thumbnail generation for: ${filePath} (not an image)`);
    return;
  }

  const bucket = storage.bucket(fileBucket);
  const fileName = path.basename(filePath);
  const fileDir = path.dirname(filePath);

  // Create temp paths
  const tempFilePath = path.join(os.tmpdir(), fileName);
  const thumbFileName = `thumb_${fileName}`;
  const thumbFilePath = path.join(os.tmpdir(), thumbFileName);

  try {
    console.log(`[generateThumbnail] Processing: ${filePath}`);

    // Download original image
    await bucket.file(filePath).download({ destination: tempFilePath });
    console.log(`[generateThumbnail] Downloaded to: ${tempFilePath}`);

    // Generate 300x300 thumbnail with sharp
    await sharp(tempFilePath)
      .resize(300, 300, { 
        fit: 'cover',
        position: 'center'
      })
      .jpeg({ quality: 80 })
      .toFile(thumbFilePath);
    console.log(`[generateThumbnail] Thumbnail created: ${thumbFilePath}`);

    // Construct thumbnail path (mirrors original structure)
    const thumbPath = `thumbnails/${fileDir}/${fileName}`;

    // Upload thumbnail to storage
    await bucket.upload(thumbFilePath, {
      destination: thumbPath,
      metadata: {
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      },
      public: true, // Make thumbnail publicly accessible
    });
    console.log(`[generateThumbnail] Uploaded thumbnail to: ${thumbPath}`);

    // Get public URL (format: https://storage.googleapis.com/bucket/path)
    const thumbnailUrl = `https://storage.googleapis.com/${bucket.name}/${thumbPath}`;
    
    // Update Firestore with thumbnail URL
    await updateFirestoreWithThumbnail(filePath, thumbnailUrl);

    // Cleanup temp files
    fs.unlinkSync(tempFilePath);
    fs.unlinkSync(thumbFilePath);
    console.log(`[generateThumbnail] Cleanup complete`);

    return null;
  } catch (error) {
    console.error(`[generateThumbnail] Error processing ${filePath}:`, error);
    
    // Cleanup temp files on error
    try {
      if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
      if (fs.existsSync(thumbFilePath)) fs.unlinkSync(thumbFilePath);
    } catch (cleanupError) {
      console.error('[generateThumbnail] Cleanup error:', cleanupError);
    }
    
    throw error;
  }
});

/**
 * Update Firestore documents with thumbnail URL
 * Handles different document types based on file path
 */
async function updateFirestoreWithThumbnail(filePath: string, thumbnailUrl: string): Promise<void> {
  try {
    // User photos: users/{userId}/profile/
    if (filePath.startsWith('users/') && filePath.includes('/profile/')) {
      const userId = filePath.split('/')[1];
      await db.collection('users').doc(userId).update({
        photoThumbnailUrl: thumbnailUrl,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[updateFirestore] Updated user ${userId} with thumbnail`);
    }
    
    // Event images: events/{eventId}/images/
    else if (filePath.startsWith('events/')) {
      const pathParts = filePath.split('/');
      const eventId = pathParts[1];
      await db.collection('events').doc(eventId).update({
        imageThumbnailUrl: thumbnailUrl,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[updateFirestore] Updated event ${eventId} with thumbnail`);
    }
    
    // Marketplace listings: marketplace/{listingId}/images/
    else if (filePath.startsWith('marketplace/')) {
      const pathParts = filePath.split('/');
      const listingId = pathParts[1];
      
      const listingRef = db.collection('marketplace_listings').doc(listingId);
      const listing = await listingRef.get();
      
      if (listing.exists) {
        const currentThumbnails = listing.data()?.thumbnailUrls || [];
        currentThumbnails.push(thumbnailUrl);
        
        await listingRef.update({
          thumbnailUrls: currentThumbnails,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`[updateFirestore] Updated marketplace listing ${listingId} with thumbnail`);
      }
    }
    
    // Provider photos: providers/{providerId}/photos/
    else if (filePath.startsWith('providers/')) {
      const pathParts = filePath.split('/');
      const providerId = pathParts[1];
      
      const providerRef = db.collection('providers').doc(providerId);
      const provider = await providerRef.get();
      
      if (provider.exists) {
        // Check if this is the cover photo
        if (filePath.includes('cover')) {
          await providerRef.update({
            coverPhotoThumbnailUrl: thumbnailUrl,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // Add to photo thumbnails array
          const currentThumbnails = provider.data()?.photoThumbnailUrls || [];
          currentThumbnails.push(thumbnailUrl);
          
          await providerRef.update({
            photoThumbnailUrls: currentThumbnails,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        console.log(`[updateFirestore] Updated provider ${providerId} with thumbnail`);
      }
    }
    
    // Bike rental listings: bike_rentals/{listingId}/images/
    else if (filePath.startsWith('bike_rentals/')) {
      const pathParts = filePath.split('/');
      const listingId = pathParts[1];
      
      const listingRef = db.collection('bike_listings').doc(listingId);
      const listing = await listingRef.get();
      
      if (listing.exists) {
        const currentThumbnails = listing.data()?.thumbnailUrls || [];
        currentThumbnails.push(thumbnailUrl);
        
        await listingRef.update({
          thumbnailUrls: currentThumbnails,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`[updateFirestore] Updated bike rental ${listingId} with thumbnail`);
      }
    }
    
    else {
      console.log(`[updateFirestore] No Firestore update logic for path: ${filePath}`);
    }
    
  } catch (error) {
    console.error('[updateFirestore] Error updating Firestore:', error);
    // Don't throw - thumbnail was created successfully even if Firestore update failed
  }
}

/**
 * Clean up thumbnails when original image is deleted
 */
export const cleanupThumbnails = functions.storage.object().onDelete(async (object) => {
  const filePath = object.name;
  
  // Skip if already a thumbnail
  if (!filePath || filePath.startsWith('thumbnails/')) {
    return null;
  }
  
  // Construct thumbnail path
  const fileDir = path.dirname(filePath);
  const fileName = path.basename(filePath);
  const thumbPath = `thumbnails/${fileDir}/${fileName}`;
  
  const bucket = storage.bucket(object.bucket);
  
  try {
    await bucket.file(thumbPath).delete();
    console.log(`[cleanupThumbnails] ✅ Deleted thumbnail: ${thumbPath}`);
  } catch (error: any) {
    if (error.code === 404) {
      console.log('[cleanupThumbnails] Thumbnail not found, nothing to delete');
    } else {
      console.error('[cleanupThumbnails] Error deleting thumbnail:', error);
    }
  }
  
  return null;
});

// ─── MIGRATION: Create/fix provider_analytics documents ─────────────────────
// Creates missing analytics documents and fixes userId on existing ones
// 🔒 Requires admin authorization header
export const migrateProviderAnalytics = functions.https.onRequest(async (req, res) => {
  // Check for admin authorization
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized: Missing authorization header' });
    return;
  }

  try {
    // Verify Firebase ID token
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Check if user is admin
    if (decodedToken.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }
    
    console.log(`[migrateProviderAnalytics] Starting migration requested by admin: ${decodedToken.uid}`);
  } catch (error) {
    console.error('[migrateProviderAnalytics] Auth error:', error);
    res.status(401).json({ error: 'Unauthorized: Invalid token' });
    return;
  }
  
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
// 🔒 Requires admin authorization header
export const investigateDb = functions.https.onRequest(async (req, res) => {
  // Check for admin authorization
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized: Missing authorization header' });
    return;
  }

  try {
    // Verify Firebase ID token
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Check if user is admin
    if (decodedToken.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }
    
    console.log(`[investigateDb] Database investigation requested by admin: ${decodedToken.uid}`);
  } catch (error) {
    console.error('[investigateDb] Auth error:', error);
    res.status(401).json({ error: 'Unauthorized: Invalid token' });
    return;
  }

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
// Auto-approves providers, creates analytics document, and sends approval notification.

export const onProviderSubmit = functions.firestore
  .document('providers/{providerId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const data = snap.data();
    const providerId = context.params.providerId;
    const userId = data.userId;

    // AUTO-APPROVE: Set status to approved if not already set
    if (data.verificationStatus !== 'approved') {
      await snap.ref.update({ verificationStatus: 'approved' });
    }

    // Create analytics document with admin privileges (bypasses security rules)
    await db.collection('provider_analytics').doc(providerId).set({
      providerId: providerId,
      userId: userId || '',
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

    // Send approval notification to the provider
    if (userId) {
      try {
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data()!;
          const fcmToken: string | undefined = userData.fcmToken;
          
          // Check subscription alert preference (we'll use this for account-related notifications)
          const subscriptionAlertsEnabled = userData.notif_subscription_alerts !== false;
          
          if (fcmToken && subscriptionAlertsEnabled) {
            const providerName = data.name || 'Your provider profile';
            
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: '✅ Provider Approved!',
                body: `${providerName} is now live on CYKEL!`,
              },
              data: {
                type: 'provider_approved',
                providerId,
              },
              android: {
                notification: {
                  channelId: 'subscription_alerts',
                  priority: 'high',
                },
              },
              apns: {
                payload: {
                  aps: { badge: 1, sound: 'default' },
                },
              },
            });

            functions.logger.info(`[onProviderSubmit] Approval notification sent to ${userId}`);
          }
        }
      } catch (error) {
        functions.logger.warn(`[onProviderSubmit] Failed to send approval notification:`, error);
      }
    }
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
//   2. Expires trials whose trialEndsAt has passed
//   3. Revokes unverified fallback subscriptions after 24-hour grace period

export const refreshSubscriptionStatus = functions.pubsub
  .schedule('every day 03:00')
  .timeZone('UTC')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const batch = db.batch();
    let expiredCount = 0;
    let trialExpiredCount = 0;
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

    // ── 2. Expire trials past their trialEndsAt date ───────────────────────
    const expiredTrials = await db
      .collection('users')
      .where('subscription.isTrial', '==', true)
      .where('subscription.trialEndsAt', '<=', now)
      .get();

    for (const doc of expiredTrials.docs) {
      batch.update(doc.ref, {
        'subscription.plan': 'free',
        'subscription.active': false,
        'subscription.isTrial': false,
        'subscription.expiresAt': null,
      });
      trialExpiredCount++;
      functions.logger.info(
        `[refreshSubscriptionStatus] Expired trial for user ${doc.id}`,
      );
    }

    // ── 3. Revoke unverified fallback subscriptions ────────────────────────
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

    if (expiredCount === 0 && trialExpiredCount === 0 && revokedCount === 0) {
      functions.logger.info('[refreshSubscriptionStatus] No subscriptions to update');
      return;
    }

    await batch.commit();

    functions.logger.info(
      `[refreshSubscriptionStatus] Expired ${expiredCount} subscriptions, ${trialExpiredCount} trials, revoked ${revokedCount} unverified`,
    );
  });

// ═══════════════════════════════════════════════════════════════════════════
// ─── EVENT NOTIFICATIONS ────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

// ─── Send notifications when a new participant joins an event ───────────────
export const onEventParticipantJoin = functions.firestore
  .document('events/{eventId}/participants/{participantId}')
  .onCreate(async (snapshot, context) => {
    const { eventId, participantId } = context.params;
    
    try {
      // Get event details
      const eventDoc = await db.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return;
      
      const event = eventDoc.data();
      if (!event) return;
      
      // Get participant details
      const participantDoc = await db.collection('users').doc(participantId).get();
      if (!participantDoc.exists) return;
      
      const participant = participantDoc.data();
      if (!participant) return;
      
      // Get organizer's FCM token
      const organizerDoc = await db.collection('users').doc(event['organizerId']).get();
      if (!organizerDoc.exists) return;
      
      const fcmToken = organizerDoc.data()?.['fcmToken'];
      if (!fcmToken) {
        functions.logger.info(`[onEventParticipantJoin] Organizer ${event['organizerId']} has no FCM token`);
        return;
      }
      
      // Send notification to organizer
      const message = {
        token: fcmToken,
        notification: {
          title: `New rider joined: ${event['title']}`,
          body: `${participant['name'] || 'Someone'} just joined your ride!`,
        },
        data: {
          type: 'event_participant_join',
          eventId: eventId,
          participantId: participantId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'events',
            priority: 'high' as const,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      await admin.messaging().send(message);
      functions.logger.info(`[onEventParticipantJoin] ✅ Notified organizer ${event['organizerId']} about ${participantId}`);
      
    } catch (error) {
      functions.logger.error(`[onEventParticipantJoin] ❌ Error:`, error);
    }
  });

// ─── Send notifications when an event is updated ────────────────────────────
// Legacy event update handler (deprecated - use onEventUpdateV2 below)
export const onEventUpdateLegacy = functions.firestore
  .document('events/{eventId}')
  .onUpdate(async (change, context) => {
    const { eventId } = context.params;
    const before = change.before.data();
    const after = change.after.data();
    
    try {
      // Check if important fields changed
      const titleChanged = before['title'] !== after['title'];
      const dateChanged = before['dateTime'].toMillis() !== after['dateTime'].toMillis();
      const locationChanged = before['meetingPoint'].latitude !== after['meetingPoint'].latitude ||
                             before['meetingPoint'].longitude !== after['meetingPoint'].longitude;
      const cancelled = after['status'] === 'cancelled' && before['status'] !== 'cancelled';
      
      if (!titleChanged && !dateChanged && !locationChanged && !cancelled) {
        // No important changes, skip notification
        return;
      }
      
      // Get all participants
      const participantsSnapshot = await db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .where('status', '==', 'confirmed')
        .get();
      
      if (participantsSnapshot.empty) {
        functions.logger.info(`[onEventUpdate] No participants to notify for event ${eventId}`);
        return;
      }
      
      // Get FCM tokens for all participants
      const participantIds = participantsSnapshot.docs.map(doc => doc.id);
      const userDocs = await Promise.all(
        participantIds.map(id => db.collection('users').doc(id).get())
      );
      
      const fcmTokens = userDocs
        .map(doc => doc.data()?.['fcmToken'])
        .filter(token => token != null);
      
      if (fcmTokens.length === 0) {
        functions.logger.info(`[onEventUpdate] No FCM tokens found for participants`);
        return;
      }
      
      // Build notification message
      let notificationTitle = `Event updated: ${after['title']}`;
      let notificationBody = '';
      
      if (cancelled) {
        notificationTitle = `Event cancelled: ${after['title']}`;
        notificationBody = 'This event has been cancelled by the organizer.';
      } else if (titleChanged) {
        notificationBody = `Event renamed from "${before['title']}"`;
      } else if (dateChanged) {
        notificationBody = 'Event date/time has been changed.';
      } else if (locationChanged) {
        notificationBody = 'Meeting point has been changed.';
      }
      
      // Send notification to all participants
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: cancelled ? 'event_cancelled' : 'event_updated',
          eventId: eventId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'events',
            priority: 'high' as const,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        tokens: fcmTokens,
      };
      
      const response = await admin.messaging().sendEachForMulticast(message);
      functions.logger.info(
        `[onEventUpdate] ✅ Sent ${response.successCount} notifications, ${response.failureCount} failures`
      );
      
    } catch (error) {
      functions.logger.error(`[onEventUpdate] ❌ Error:`, error);
    }
  });

// ─── Send reminders 1 hour before event starts ──────────────────────────────
export const sendEventReminders = functions.pubsub
  .schedule('every 15 minutes')
  .timeZone('UTC')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const oneHourFromNow = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + 60 * 60 * 1000
    );
    const reminderWindow = admin.firestore.Timestamp.fromMillis(
      oneHourFromNow.toMillis() + 15 * 60 * 1000 // +15 min window
    );
    
    try {
      // Find events starting in the next hour that haven't been reminded
      const eventsSnapshot = await db
        .collection('events')
        .where('status', '==', 'upcoming')
        .where('dateTime', '>=', oneHourFromNow)
        .where('dateTime', '<=', reminderWindow)
        .where('reminderSent', '==', false)
        .get();
      
      if (eventsSnapshot.empty) {
        functions.logger.info(`[sendEventReminders] No events to remind`);
        return;
      }
      
      let remindersSent = 0;
      
      for (const eventDoc of eventsSnapshot.docs) {
        const event = eventDoc.data();
        
        // Get all confirmed participants
        const participantsSnapshot = await db
          .collection('events')
          .doc(eventDoc.id)
          .collection('participants')
          .where('status', '==', 'confirmed')
          .get();
        
        if (participantsSnapshot.empty) continue;
        
        // Get FCM tokens
        const participantIds = participantsSnapshot.docs.map(doc => doc.id);
        const userDocs = await Promise.all(
          participantIds.map(id => db.collection('users').doc(id).get())
        );
        
        const fcmTokens = userDocs
          .map(doc => doc.data()?.['fcmToken'])
          .filter(token => token != null);
        
        if (fcmTokens.length === 0) continue;
        
        // Send reminder notifications
        const message = {
          notification: {
            title: `Ride starting soon: ${event['title']}`,
            body: `Your ride starts in 1 hour! See you at ${event['meetingPoint'].address}`,
          },
          data: {
            type: 'event_reminder',
            eventId: eventDoc.id,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            notification: {
              channelId: 'events',
              priority: 'high' as const,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
          tokens: fcmTokens,
        };
        
        const response = await admin.messaging().sendEachForMulticast(message);
        remindersSent += response.successCount;
        
        // Mark reminder as sent
        await eventDoc.ref.update({ reminderSent: true });
      }
      
      functions.logger.info(`[sendEventReminders] ✅ Sent ${remindersSent} reminders`);
      
    } catch (error) {
      functions.logger.error(`[sendEventReminders] ❌ Error:`, error);
    }
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

// ─── 9. onFamilyAlertCreate ────────────────────────────────────────────────
// Triggered when a family alert is created.
// Sends push notifications to family admins (owners/admins).

export const onFamilyAlertCreate = functions.firestore
  .document('familyAccounts/{familyId}/alerts/{alertId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const alert = snap.data();
    const familyId = context.params.familyId;
    const alertId = context.params.alertId;

    functions.logger.info(`[onFamilyAlertCreate] Alert ${alertId} created for family ${familyId}`);

    // Skip if no message
    if (!alert.message) {
      functions.logger.warn(`[onFamilyAlertCreate] Alert ${alertId} has no message`);
      return;
    }

    // Get the family account to find members
    const familyDoc = await db.collection('familyAccounts').doc(familyId).get();
    if (!familyDoc.exists) {
      functions.logger.warn(`[onFamilyAlertCreate] Family ${familyId} not found`);
      return;
    }

    const family = familyDoc.data()!;
    const members = family.members || [];

    // Find admins (owners and admins only) to notify
    const adminMembers = members.filter((m: any) => 
      m.role === 'owner' || m.role === 'admin'
    );

    // Don't notify the member who triggered the alert
    const adminsToNotify = adminMembers.filter((m: any) => 
      m.userId !== alert.memberId
    );

    if (adminsToNotify.length === 0) {
      functions.logger.info(`[onFamilyAlertCreate] No admins to notify for alert ${alertId}`);
      return;
    }

    // Get notification priority based on alert type
    const alertType = alert.type || 'unknown';
    const isUrgent = ['sosPressed', 'crashDetected'].includes(alertType);

    // Map alert types to notification titles
    const alertTitles: Record<string, string> = {
      rideStarted: '🚴 Ride Started',
      rideEnded: '🏁 Ride Ended',
      sosPressed: '🆘 EMERGENCY SOS',
      crashDetected: '⚠️ Crash Detected',
      enteredSafeZone: '📍 Arrived',
      leftSafeZone: '📍 Departed',
      lowBattery: '🔋 Low Battery',
      speedAlert: '⚡ Speed Alert',
      curfewViolation: '🌙 Curfew Alert',
    };

    const notificationTitle = alertTitles[alertType] || '🔔 Family Alert';

    // Send notifications to all admins
    let sentCount = 0;
    const sendPromises = adminsToNotify.map(async (adminMember: any) => {
      // Get admin's FCM token
      const userDoc = await db.collection('users').doc(adminMember.userId).get();
      if (!userDoc.exists) return;

      const fcmToken: string | undefined = userDoc.data()?.fcmToken;
      if (!fcmToken) {
        functions.logger.warn(`[onFamilyAlertCreate] No FCM token for admin ${adminMember.userId}`);
        return;
      }

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: notificationTitle,
            body: alert.message,
          },
          data: {
            type: 'family_alert',
            alertType: alertType,
            familyId: familyId,
            alertId: alertId,
            memberId: alert.memberId || '',
            memberName: alert.memberName || '',
          },
          android: {
            priority: isUrgent ? 'high' : 'normal',
            notification: {
              channelId: isUrgent ? 'family_urgent' : 'family_alerts',
              sound: isUrgent ? 'alarm' : 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: isUrgent ? 'alarm.caf' : 'default',
                'interruption-level': isUrgent ? 'critical' : 'active',
              },
            },
          },
        });
        sentCount++;
        functions.logger.info(`[onFamilyAlertCreate] Notification sent to ${adminMember.userId}`);
      } catch (err) {
        functions.logger.error(`[onFamilyAlertCreate] Failed to send to ${adminMember.userId}:`, err);
      }
    });

    await Promise.all(sendPromises);
    functions.logger.info(`[onFamilyAlertCreate] Alert ${alertId}: Sent ${sentCount}/${adminsToNotify.length} notifications`);
  });

// ─── 10. onFamilyInvitationCreate ─────────────────────────────────────────────
// Triggered when a family invitation is created.
// Sends email to ALL invitees (new and existing users).
// Additionally sends push notification if invitee is already a CYKEL user.

export const onFamilyInvitationCreate = functions.firestore
  .document('familyInvitations/{invitationId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const invitation = snap.data();
    const invitationId = context.params.invitationId;

    functions.logger.info(`[onFamilyInvitationCreate] Invitation ${invitationId} created`);

    const inviteeEmail = invitation.inviteeEmail;
    if (!inviteeEmail) {
      functions.logger.warn(`[onFamilyInvitationCreate] No invitee email`);
      return;
    }

    const familyName = invitation.familyName || 'a family';
    const invitedByName = invitation.invitedByName || 'Someone';
    const inviteCode = invitation.inviteCode || '';

    // ─── Send Email to Invitee ────────────────────────────────────────────
    try {
      const emailSubject = `🚴 You're invited to join ${familyName} on CYKEL!`;
      const emailBody = `
Hi there!

${invitedByName} has invited you to join their family group on CYKEL.

Your invite code: ${inviteCode}

To join:
1. Download CYKEL app (if you don't have it yet)
   - iOS: https://apps.apple.com/app/cykel
   - Android: https://play.google.com/store/apps/details?id=com.cykel.app

2. Open the app and go to: Profile → Family → Join Family

3. Enter this code: ${inviteCode}

This invitation expires in 7 days.

Happy cycling! 🚲

---
The CYKEL Team
`;

      // Log email content (for debugging and manual sending if needed)
      functions.logger.info(`[onFamilyInvitationCreate] Email to send:`, {
        to: inviteeEmail,
        subject: emailSubject,
        body: emailBody,
      });

      // Send email using Firebase Admin (email extension or custom SMTP)
      // NOTE: This requires Firebase Extension "Trigger Email" or custom email service
      // For now, we'll create a document in a 'mail' collection that Firebase Extension can process
      await db.collection('mail').add({
        to: inviteeEmail,
        message: {
          subject: emailSubject,
          text: emailBody,
          html: `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .code-box { background: white; border: 2px solid #667eea; border-radius: 10px; padding: 20px; margin: 20px 0; text-align: center; }
    .code { font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #667eea; }
    .steps { background: white; padding: 20px; border-radius: 10px; margin: 20px 0; }
    .step { margin: 15px 0; padding-left: 30px; position: relative; }
    .step::before { content: "→"; position: absolute; left: 0; color: #667eea; font-weight: bold; }
    .button { display: inline-block; background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
    .footer { text-align: center; color: #999; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚴 Family Invitation</h1>
      <p>${invitedByName} invited you to join ${familyName}!</p>
    </div>
    <div class="content">
      <p>Hi there!</p>
      <p>${invitedByName} has invited you to join their family group on CYKEL - the cycling companion app.</p>
      
      <div class="code-box">
        <p style="margin: 0; color: #666; font-size: 14px;">Your Invite Code</p>
        <div class="code">${inviteCode}</div>
      </div>

      <div class="steps">
        <h3 style="margin-top: 0;">How to Join:</h3>
        <div class="step">Download CYKEL app (if you don't have it yet)</div>
        <div class="step">Open the app and go to: <strong>Profile → Family → Join Family</strong></div>
        <div class="step">Enter the code: <strong>${inviteCode}</strong></div>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://apps.apple.com/app/cykel" class="button" style="color: white;">Download for iOS</a>
        <a href="https://play.google.com/store/apps/details?id=com.cykel.app" class="button" style="color: white;">Download for Android</a>
      </div>

      <p style="font-size: 12px; color: #666; margin-top: 30px;">⏰ This invitation expires in 7 days.</p>
    </div>
    <div class="footer">
      <p>Happy cycling! 🚲</p>
      <p>The CYKEL Team</p>
    </div>
  </div>
</body>
</html>
          `,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        from: 'CYKEL <noreply@cykel.app>',
      });

      // Update invitation to mark email as sent
      await snap.ref.update({
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      functions.logger.info(`[onFamilyInvitationCreate] Email queued for ${inviteeEmail}`);
    } catch (emailError) {
      functions.logger.error(`[onFamilyInvitationCreate] Failed to send email:`, emailError);
      // Continue even if email fails - we'll try push notification
    }

    // ─── Send Push Notification (if user exists) ─────────────────────────
    let inviteeUser: admin.auth.UserRecord | null = null;
    try {
      inviteeUser = await auth.getUserByEmail(inviteeEmail);
    } catch (error) {
      // User doesn't exist yet - email is their only notification
      functions.logger.info(`[onFamilyInvitationCreate] Invitee ${inviteeEmail} is not a CYKEL user yet - email sent`);
      return;
    }

    if (!inviteeUser) return;

    // Get invitee's FCM token
    const userDoc = await db.collection('users').doc(inviteeUser.uid).get();
    if (!userDoc.exists) {
      functions.logger.warn(`[onFamilyInvitationCreate] User doc not found for ${inviteeUser.uid}`);
      return;
    }

    const fcmToken: string | undefined = userDoc.data()?.fcmToken;
    if (!fcmToken) {
      functions.logger.warn(`[onFamilyInvitationCreate] No FCM token for ${inviteeUser.uid}`);
      return;
    }

    // Send push notification (in addition to email)
    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '👨‍👩‍👧‍👦 Family Invitation',
          body: `${invitedByName} invited you to join "${familyName}" on CYKEL!`,
        },
        data: {
          type: 'family_invitation',
          invitationId: invitationId,
          familyName: familyName,
          invitedByName: invitedByName,
          inviteCode: inviteCode,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'family_invitations',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      });

      // Update invitation with invitee's userId and notification status
      await snap.ref.update({
        inviteeUserId: inviteeUser.uid,
        pushNotificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      functions.logger.info(`[onFamilyInvitationCreate] Push notification sent to ${inviteeEmail}`);
    } catch (err) {
      functions.logger.error(`[onFamilyInvitationCreate] Failed to send push notification:`, err);
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// ─── PHASE 1: RENTAL & EVENT NOTIFICATIONS ─────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

// ─── 11. onRentalRequestCreate ───────────────────────────────────────────────
// Triggered when a rental request is created.
// Notifies bike owner about the new rental request (highest priority).

export const onRentalRequestCreate = functions.firestore
  .document('rentalRequests/{requestId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const request = snap.data();
    const requestId = context.params.requestId;

    functions.logger.info(`[onRentalRequestCreate] Request ${requestId} created`);

    // Get owner's FCM token and notification preferences
    const ownerDoc = await db.collection('users').doc(request.ownerId).get();
    if (!ownerDoc.exists) {
      functions.logger.warn(`[onRentalRequestCreate] Owner ${request.ownerId} not found`);
      return;
    }

    const ownerData = ownerDoc.data()!;
    const fcmToken: string | undefined = ownerData.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onRentalRequestCreate] No FCM token for owner ${request.ownerId}`);
      return;
    }

    // Check user preferences (default true if not set)
    const rentalUpdatesEnabled = ownerData.notif_rental_updates !== false;
    if (!rentalUpdatesEnabled) {
      functions.logger.info(`[onRentalRequestCreate] Rental updates disabled for ${request.ownerId}`);
      return;
    }

    // Get renter's name
    const renterDoc = await db.collection('users').doc(request.renterId).get();
    const renterName = renterDoc.exists ? renterDoc.data()!.name || 'Someone' : 'Someone';

    // Get listing title
    const listingDoc = await db.collection('bikeListings').doc(request.listingId).get();
    const listingTitle = listingDoc.exists ? listingDoc.data()!.title || 'Your bike' : 'Your bike';

    // Format dates
    const startDate = request.startTime?.toDate();
    const endDate = request.endTime?.toDate();
    const startDateStr = startDate 
      ? startDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
      : 'TBA';
    const endDateStr = endDate
      ? endDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
      : 'TBA';
    const totalCost = request.totalCost || 0;

    // ─── 1. Send FCM Notification ────────────────────────────────────────

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🚴 New Rental Request',
          body: `${renterName} wants to rent ${listingTitle}`,
        },
        data: {
          type: 'rental_request',
          requestId,
          listingId: request.listingId,
          renterId: request.renterId,
        },
        android: {
          notification: {
            channelId: 'rental_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onRentalRequestCreate] Notification sent to owner ${request.ownerId}`);
    } catch (error) {
      functions.logger.error(`[onRentalRequestCreate] Failed to send notification:`, error);
    }

    // ─── 2. Send Email to Owner ──────────────────────────────────────────

    const ownerEmail = ownerData.email;
    if (!ownerEmail) {
      functions.logger.warn(`[onRentalRequestCreate] No email for owner ${request.ownerId}`);
      return;
    }

    try {
      await db.collection('mail').add({
        to: ownerEmail,
        message: {
          subject: `🚴 New Rental Request for "${listingTitle}"`,
          html: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 30px 20px; border-radius: 10px 10px 0 0; text-align: center; }
                .header h1 { margin: 0; font-size: 24px; }
                .content { background: #f8f9fa; padding: 30px 20px; border-radius: 0 0 10px 10px; }
                .request-card { background: white; border-radius: 8px; padding: 20px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                .detail { margin: 15px 0; padding: 10px; background: #f8f9fa; border-left: 4px solid #10b981; }
                .detail strong { color: #059669; }
                .price { font-size: 28px; color: #10b981; font-weight: bold; margin: 20px 0; }
                .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>🚴 New Rental Request</h1>
              </div>
              <div class="content">
                <p>Hi,</p>
                <p>You have a new rental request for your bike!</p>
                
                <div class="request-card">
                  <h2 style="margin-top: 0; color: #059669;">${listingTitle}</h2>
                  
                  <div class="detail">
                    <strong>👤 Requested by:</strong> ${renterName}
                  </div>
                  
                  <div class="detail">
                    <strong>📅 Start Date:</strong> ${startDateStr}
                  </div>
                  
                  <div class="detail">
                    <strong>📅 End Date:</strong> ${endDateStr}
                  </div>
                  
                  ${request.message ? `
                  <div class="detail">
                    <strong>💬 Message:</strong><br>
                    "${request.message}"
                  </div>
                  ` : ''}
                  
                  <div class="price">
                    $${totalCost.toFixed(2)}
                  </div>
                </div>
                
                <p><strong>What's next?</strong></p>
                <ul>
                  <li>Open the CYKEL app to review the request</li>
                  <li>Check ${renterName}'s profile and reviews</li>
                  <li>Approve or decline within 24 hours</li>
                </ul>
                
                <div class="footer">
                  <p>This rental request will expire in 24 hours if not responded to.</p>
                  <p style="font-size: 12px; color: #999;">Email sent by CYKEL - Bike Rental Platform</p>
                </div>
              </div>
            </body>
            </html>
          `,
        },
        from: 'CYKEL <noreply@cykel.app>',
      });

      functions.logger.info(`[onRentalRequestCreate] Email queued for owner ${ownerEmail}`);
    } catch (error) {
      functions.logger.error(`[onRentalRequestCreate] Failed to send email:`, error);
    }
  });

// ─── 12. onRentalRequestUpdate ───────────────────────────────────────────────
// Triggered when a rental request is updated (approved/declined).
// Notifies renter about the owner's decision.

export const onRentalRequestUpdate = functions.firestore
  .document('rentalRequests/{requestId}')
  .onUpdate(async (change: functions.Change<QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const requestId = context.params.requestId;

    // Only send notification if status changed to approved or declined
    if (before.status === after.status) return;
    if (after.status !== 'approved' && after.status !== 'declined') return;

    functions.logger.info(`[onRentalRequestUpdate] Request ${requestId} ${after.status}`);

    // Get renter's FCM token and preferences
    const renterDoc = await db.collection('users').doc(after.renterId).get();
    if (!renterDoc.exists) {
      functions.logger.warn(`[onRentalRequestUpdate] Renter ${after.renterId} not found`);
      return;
    }

    const renterData = renterDoc.data()!;
    const fcmToken: string | undefined = renterData.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onRentalRequestUpdate] No FCM token for renter ${after.renterId}`);
      return;
    }

    // Check preferences
    const rentalUpdatesEnabled = renterData.notif_rental_updates !== false;
    if (!rentalUpdatesEnabled) {
      functions.logger.info(`[onRentalRequestUpdate] Rental updates disabled for ${after.renterId}`);
      return;
    }

    // Get listing title
    const listingDoc = await db.collection('bikeListings').doc(after.listingId).get();
    const listingTitle = listingDoc.exists ? listingDoc.data()!.title || 'the bike' : 'the bike';

    const isApproved = after.status === 'approved';
    const title = isApproved ? '✅ Rental Request Approved!' : '❌ Rental Request Declined';
    const body = isApproved 
      ? `Your request to rent ${listingTitle} was approved!`
      : `Your request to rent ${listingTitle} was declined.`;

    // Format dates
    const startDate = after.startTime?.toDate();
    const endDate = after.endTime?.toDate();
    const startDateStr = startDate 
      ? startDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })
      : 'TBA';
    const endDateStr = endDate
      ? endDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })
      : 'TBA';
    const totalCost = after.totalCost || 0;

    // Get owner info
    const ownerDoc = await db.collection('users').doc(after.ownerId).get();
    const ownerName = ownerDoc.exists ? ownerDoc.data()!.name || 'Owner' : 'Owner';

    // ─── 1. Send FCM Notification ────────────────────────────────────────

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: {
          type: 'rental_request_update',
          requestId,
          listingId: after.listingId,
          status: after.status,
        },
        android: {
          notification: {
            channelId: 'rental_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onRentalRequestUpdate] Notification sent to renter ${after.renterId}`);
    } catch (error) {
      functions.logger.error(`[onRentalRequestUpdate] Failed to send notification:`, error);
    }

    // ─── 2. Send Email to Renter ─────────────────────────────────────────

    const renterEmail = renterData.email;
    if (!renterEmail) {
      functions.logger.warn(`[onRentalRequestUpdate] No email for renter ${after.renterId}`);
      return;
    }

    if (isApproved) {
      // Send approval email with rental details
      try {
        await db.collection('mail').add({
          to: renterEmail,
          message: {
            subject: `✅ Your Rental of "${listingTitle}" is Confirmed!`,
            html: `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <style>
                  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                  .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 30px 20px; border-radius: 10px 10px 0 0; text-align: center; }
                  .header h1 { margin: 0; font-size: 24px; }
                  .content { background: #f8f9fa; padding: 30px 20px; border-radius: 0 0 10px 10px; }
                  .rental-card { background: white; border-radius: 8px; padding: 20px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                  .detail { margin: 15px 0; padding: 10px; background: #f8f9fa; border-left: 4px solid #10b981; }
                  .detail strong { color: #059669; }
                  .price { font-size: 28px; color: #10b981; font-weight: bold; margin: 20px 0; }
                  .success-badge { background: #10b981; color: white; padding: 10px 20px; border-radius: 20px; display: inline-block; margin: 10px 0; }
                  .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }
                </style>
              </head>
              <body>
                <div class="header">
                  <h1>✅ Rental Confirmed!</h1>
                </div>
                <div class="content">
                  <div class="success-badge">Your request was approved</div>
                  
                  <p>Great news! ${ownerName} approved your rental request.</p>
                  
                  <div class="rental-card">
                    <h2 style="margin-top: 0; color: #059669;">${listingTitle}</h2>
                    
                    <div class="detail">
                      <strong>👤 Owner:</strong> ${ownerName}
                    </div>
                    
                    <div class="detail">
                      <strong>📅 Pickup:</strong> ${startDateStr}
                    </div>
                    
                    <div class="detail">
                      <strong>📅 Return:</strong> ${endDateStr}
                    </div>
                    
                    <div class="price">
                      Total: $${totalCost.toFixed(2)}
                    </div>
                  </div>
                  
                  <p><strong>Next Steps:</strong></p>
                  <ul>
                    <li>Open the CYKEL app to view pickup location</li>
                    <li>Contact ${ownerName} to coordinate details</li>
                    <li>Be on time for pickup</li>
                    <li>Inspect the bike before riding</li>
                  </ul>
                  
                  <p><strong>Important Reminders:</strong></p>
                  <ul>
                    <li>Treat the bike with care</li>
                    <li>Return it on time and in same condition</li>
                    <li>Take photos before and after</li>
                  </ul>
                  
                  <div class="footer">
                    <p style="font-size: 12px; color: #999;">Email sent by CYKEL - Bike Rental Platform</p>
                  </div>
                </div>
              </body>
              </html>
            `,
          },
          from: 'CYKEL <noreply@cykel.app>',
        });

        functions.logger.info(`[onRentalRequestUpdate] Approval email queued for ${renterEmail}`);
      } catch (error) {
        functions.logger.error(`[onRentalRequestUpdate] Failed to send approval email:`, error);
      }
    } else {
      // Send decline email
      try {
        await db.collection('mail').add({
          to: renterEmail,
          message: {
            subject: `Rental Request Update - "${listingTitle}"`,
            html: `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <style>
                  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                  .header { background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%); color: white; padding: 30px 20px; border-radius: 10px 10px 0 0; text-align: center; }
                  .header h1 { margin: 0; font-size: 24px; }
                  .content { background: #f8f9fa; padding: 30px 20px; border-radius: 0 0 10px 10px; }
                  .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }
                </style>
              </head>
              <body>
                <div class="header">
                  <h1>Rental Request Update</h1>
                </div>
                <div class="content">
                  <p>Hi,</p>
                  <p>Unfortunately, ${ownerName} declined your rental request for "${listingTitle}".</p>
                  <p>Don't worry! There are many other bikes available on CYKEL.</p>
                  <p><strong>Try this:</strong></p>
                  <ul>
                    <li>Search for similar bikes in your area</li>
                    <li>Adjust your rental dates</li>
                    <li>Contact other bike owners</li>
                  </ul>
                  
                  <div class="footer">
                    <p style="font-size: 12px; color: #999;">Email sent by CYKEL - Bike Rental Platform</p>
                  </div>
                </div>
              </body>
              </html>
            `,
          },
          from: 'CYKEL <noreply@cykel.app>',
        });

        functions.logger.info(`[onRentalRequestUpdate] Decline email queued for ${renterEmail}`);
      } catch (error) {
        functions.logger.error(`[onRentalRequestUpdate] Failed to send decline email:`, error);
      }
    }
  });

// ─── 13. onEventUpdate ───────────────────────────────────────────────────────
// Triggered when an event is updated/cancelled.
// Notifies all participants about event cancellations or major changes.

export const onEventUpdate = functions.firestore
  .document('events/{eventId}')
  .onUpdate(async (change: functions.Change<QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const eventId = context.params.eventId;

    // Only notify if event was cancelled or time/location changed significantly
    const wasCancelled = before.status !== 'cancelled' && after.status === 'cancelled';
    const timeChanged = before.dateTime?.seconds !== after.dateTime?.seconds;
    const locationChanged = before.location?.latitude !== after.location?.latitude ||
                           before.location?.longitude !== after.location?.longitude;

    if (!wasCancelled && !timeChanged && !locationChanged) return;

    functions.logger.info(`[onEventUpdate] Event ${eventId} updated (cancelled=${wasCancelled})`);

    // Get all participants
    const participantsSnapshot = await db.collection('events')
      .doc(eventId)
      .collection('participants')
      .get();

    if (participantsSnapshot.empty) {
      functions.logger.info(`[onEventUpdate] No participants for event ${eventId}`);
      return;
    }

    const eventTitle = after.title || 'Your event';
    let notificationTitle: string;
    let notificationBody: string;

    if (wasCancelled) {
      notificationTitle = '❌ Event Cancelled';
      notificationBody = `${eventTitle} has been cancelled by the organizer`;
    } else if (timeChanged) {
      notificationTitle = '🕐 Event Time Changed';
      notificationBody = `${eventTitle} has been rescheduled`;
    } else {
      notificationTitle = '📍 Event Location Changed';
      notificationBody = `The location for ${eventTitle} has been updated`;
    }

    // Get organizer name
    const organizerDoc = await db.collection('users').doc(after.organizerId).get();
    const organizerName = organizerDoc.exists ? organizerDoc.data()!.name || 'The organizer' : 'The organizer';

    // Send notification AND email to each participant
    let fcmSentCount = 0;
    let emailSentCount = 0;
    
    const promises = participantsSnapshot.docs.map(async (participantDoc) => {
      const participant = participantDoc.data();
      const userId = participant.userId;

      // Skip organizer (they made the change)
      if (userId === after.organizerId) return;

      // Get user's FCM token and preferences
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data()!;
      const fcmToken: string | undefined = userData.fcmToken;
      const userEmail: string | undefined = userData.email;
      const userName = userData.name || 'there';
      
      // Check preferences
      const eventUpdatesEnabled = userData.notif_event_updates !== false;
      if (!eventUpdatesEnabled) return;

      // Send FCM notification
      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: notificationTitle,
              body: notificationBody,
            },
            data: {
              type: 'event_update',
              eventId,
              updateType: wasCancelled ? 'cancelled' : timeChanged ? 'time_changed' : 'location_changed',
            },
            android: {
              notification: {
                channelId: 'events',
                priority: 'high',
              },
            },
            apns: {
              payload: {
                aps: { badge: 1, sound: 'default' },
              },
            },
          });
          fcmSentCount++;
        } catch (error) {
          functions.logger.warn(`[onEventUpdate] Failed to send FCM to ${userId}:`, error);
        }
      }

      // Send email for cancellations (most important)
      if (wasCancelled && userEmail) {
        const eventDate = after.dateTime?.toDate();
        const dateStr = eventDate 
          ? eventDate.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })
          : 'TBA';
        const timeStr = eventDate
          ? eventDate.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
          : 'TBA';

        try {
          await db.collection('mail').add({
            to: userEmail,
            message: {
              subject: `❌ Event Cancelled: "${eventTitle}"`,
              html: `
                <!DOCTYPE html>
                <html>
                <head>
                  <meta charset="utf-8">
                  <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%); color: white; padding: 30px 20px; border-radius: 10px 10px 0 0; text-align: center; }
                    .header h1 { margin: 0; font-size: 24px; }
                    .content { background: #f8f9fa; padding: 30px 20px; border-radius: 0 0 10px 10px; }
                    .event-card { background: white; border-radius: 8px; padding: 20px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                    .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }
                  </style>
                </head>
                <body>
                  <div class="header">
                    <h1>❌ Event Cancelled</h1>
                  </div>
                  <div class="content">
                    <p>Hi ${userName},</p>
                    <p>Unfortunately, ${organizerName} has cancelled the following event:</p>
                    
                    <div class="event-card">
                      <h2 style="margin-top: 0; color: #dc2626;">${eventTitle}</h2>
                      <p><strong>Original Date:</strong> ${dateStr}</p>
                      <p><strong>Original Time:</strong> ${timeStr}</p>
                      ${after.cancellationReason ? `<p><strong>Reason:</strong> ${after.cancellationReason}</p>` : ''}
                    </div>
                    
                    <p>We're sorry for the inconvenience. Check out other events in the CYKEL app!</p>
                    
                    <div class="footer">
                      <p style="font-size: 12px; color: #999;">Email sent by CYKEL</p>
                    </div>
                  </div>
                </body>
                </html>
              `,
            },
            from: 'CYKEL <noreply@cykel.app>',
          });
          emailSentCount++;
        } catch (error) {
          functions.logger.warn(`[onEventUpdate] Failed to send email to ${userEmail}:`, error);
        }
      }
    });

    await Promise.all(promises);
    functions.logger.info(`[onEventUpdate] Sent ${fcmSentCount} FCM notifications and ${emailSentCount} emails for event ${eventId}`);
  });

// ─── 14. onEventParticipantCreate ────────────────────────────────────────────
// Triggered when someone joins an event.
// Notifies the organizer and sends a confirmation email to the participant.

export const onEventParticipantCreate = functions.firestore
  .document('events/{eventId}/participants/{participantId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const participant = snap.data();
    const eventId = context.params.eventId;

    // Skip if it's the organizer (auto-added when creating event)
    if (participant.isOrganizer === true) {
      functions.logger.info(`[onEventParticipantCreate] Skipping organizer ${participant.userId}`);
      return;
    }

    functions.logger.info(`[onEventParticipantCreate] User ${participant.userId} joined event ${eventId}`);

    // Get event details
    const eventDoc = await db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      functions.logger.warn(`[onEventParticipantCreate] Event ${eventId} not found`);
      return;
    }

    const event = eventDoc.data()!;
    const eventTitle = event.title || 'Untitled Event';

    // Get participant's user info
    const participantUserDoc = await db.collection('users').doc(participant.userId).get();
    if (!participantUserDoc.exists) {
      functions.logger.warn(`[onEventParticipantCreate] Participant ${participant.userId} not found`);
      return;
    }

    const participantUser = participantUserDoc.data()!;
    const participantName = participantUser.name || 'A cyclist';
    const participantEmail = participantUser.email;

    // ─── 1. Notify Organizer (FCM) ───────────────────────────────────────

    if (event.organizerId !== participant.userId) {
      const organizerDoc = await db.collection('users').doc(event.organizerId).get();
      if (organizerDoc.exists) {
        const organizerData = organizerDoc.data()!;
        const organizerFcmToken: string | undefined = organizerData.fcmToken;
        const eventUpdatesEnabled = organizerData.notif_event_updates !== false;

        if (organizerFcmToken && eventUpdatesEnabled) {
          try {
            await admin.messaging().send({
              token: organizerFcmToken,
              notification: {
                title: '🎉 New Event Participant',
                body: `${participantName} just joined "${eventTitle}"`,
              },
              data: {
                type: 'event_participant_joined',
                eventId,
                participantId: participant.userId,
              },
              android: {
                notification: {
                  channelId: 'events',
                  priority: 'default',
                },
              },
              apns: {
                payload: {
                  aps: { badge: 1, sound: 'default' },
                },
              },
            });

            functions.logger.info(`[onEventParticipantCreate] Notified organizer ${event.organizerId}`);
          } catch (error) {
            functions.logger.warn(`[onEventParticipantCreate] Failed to notify organizer:`, error);
          }
        }
      }
    }

    // ─── 2. Send Confirmation Email to Participant ───────────────────────

    if (!participantEmail) {
      functions.logger.warn(`[onEventParticipantCreate] No email for participant ${participant.userId}`);
      return;
    }

    // Format event date/time
    const eventDate = event.dateTime?.toDate();
    const dateStr = eventDate 
      ? eventDate.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
      : 'TBA';
    const timeStr = eventDate
      ? eventDate.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
      : 'TBA';

    // Build meeting point string
    const meetingPoint = event.meetingPoint 
      ? `${event.meetingPoint.latitude}, ${event.meetingPoint.longitude}` 
      : 'See event details';

    // Get organizer info for contact
    const organizerDoc = await db.collection('users').doc(event.organizerId).get();
    const organizerName = organizerDoc.exists ? organizerDoc.data()!.name || 'Organizer' : 'Organizer';

    try {
      await db.collection('mail').add({
        to: participantEmail,
        message: {
          subject: `📅 You're registered for "${eventTitle}"`,
          html: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px 20px; border-radius: 10px 10px 0 0; text-align: center; }
                .header h1 { margin: 0; font-size: 24px; }
                .content { background: #f8f9fa; padding: 30px 20px; border-radius: 0 0 10px 10px; }
                .event-card { background: white; border-radius: 8px; padding: 20px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                .event-detail { margin: 15px 0; padding: 10px; background: #f8f9fa; border-left: 4px solid #667eea; }
                .event-detail strong { color: #667eea; }
                .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }
                .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>🚴 Event Registration Confirmed</h1>
              </div>
              <div class="content">
                <p>Hi ${participantName},</p>
                <p>You're all set for:</p>
                
                <div class="event-card">
                  <h2 style="margin-top: 0; color: #667eea;">${eventTitle}</h2>
                  
                  <div class="event-detail">
                    <strong>📅 Date:</strong> ${dateStr}
                  </div>
                  
                  <div class="event-detail">
                    <strong>🕐 Time:</strong> ${timeStr}
                  </div>
                  
                  <div class="event-detail">
                    <strong>📍 Meeting Point:</strong> ${meetingPoint}
                  </div>
                  
                  <div class="event-detail">
                    <strong>👤 Organizer:</strong> ${organizerName}
                  </div>
                  
                  ${event.description ? `
                  <div class="event-detail">
                    <strong>📝 Details:</strong><br>
                    ${event.description}
                  </div>
                  ` : ''}
                  
                  ${event.difficulty ? `
                  <div class="event-detail">
                    <strong>🎚️ Difficulty:</strong> ${event.difficulty}
                  </div>
                  ` : ''}
                  
                  ${event.estimatedDistance ? `
                  <div class="event-detail">
                    <strong>📏 Distance:</strong> ${event.estimatedDistance} km
                  </div>
                  ` : ''}
                </div>
                
                <p>Open the CYKEL app to:</p>
                <ul>
                  <li>View full event details</li>
                  <li>See other participants</li>
                  <li>Get navigation to meeting point</li>
                  <li>Chat with the organizer</li>
                </ul>
                
                <p>See you there! 🚴‍♀️</p>
                
                <div class="footer">
                  <p>This email was sent because you joined an event on CYKEL.</p>
                  <p style="font-size: 12px; color: #999;">If you need to cancel, please use the CYKEL app.</p>
                </div>
              </div>
            </body>
            </html>
          `,
        },
        from: 'CYKEL <noreply@cykel.app>',
      });

      functions.logger.info(`[onEventParticipantCreate] Confirmation email queued for ${participantEmail}`);
    } catch (error) {
      functions.logger.error(`[onEventParticipantCreate] Failed to send email:`, error);
    }
  });

// ─── 15. onTheftReportCreate ─────────────────────────────────────────────────
// Triggered when a bike is reported stolen.
// Alerts nearby community members to help find the bike.

export const onTheftReportCreate = functions.firestore
  .document('theft_reports/{reportId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const report = snap.data();
    const reportId = context.params.reportId;

    functions.logger.info(`[onTheftReportCreate] Theft report ${reportId} created`);

    const bikeName = report.bikeName || 'A bike';
    const location = report.location as FirebaseFirestore.GeoPoint;
    const area = report.cityArea || 'your area';

    // Get users within 5km radius who have theft alerts enabled
    // Note: This is a simplified approach. In production, use a geohash index.
    const usersSnapshot = await db.collection('users').limit(500).get();
    
    let notifiedCount = 0;
    const promises = usersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;
      const userData = userDoc.data();

      // Skip the reporter
      if (userId === report.userId) return;

      const fcmToken: string | undefined = userData.fcmToken;
      if (!fcmToken) return;

      // Check theft alert preference
      const theftAlertsEnabled = userData.notif_theft_alerts !== false;
      if (!theftAlertsEnabled) return;

      // For now, send to all users with preference enabled
      // In production, filter by distance using geohash or last known location
      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: '🚨 Bike Theft Alert',
            body: `${bikeName} reported stolen in ${area}. Help find it!`,
          },
          data: {
            type: 'theft_alert',
            reportId,
            latitude: location.latitude.toString(),
            longitude: location.longitude.toString(),
          },
          android: {
            notification: {
              channelId: 'theft_alerts',
              priority: 'max',
            },
          },
          apns: {
            payload: {
              aps: { badge: 1, sound: 'default' },
            },
          },
        });
        notifiedCount++;
      } catch (error) {
        // Silently fail for invalid tokens
      }
    });

    await Promise.all(promises);
    functions.logger.info(`[onTheftReportCreate] Sent ${notifiedCount} community alerts for report ${reportId}`);
  });

// ─── 15. onSightingCreate ────────────────────────────────────────────────────
// Triggered when someone reports a sighting of a stolen bike.
// Notifies the bike owner immediately!

export const onSightingCreate = functions.firestore
  .document('theft_reports/{reportId}/sightings/{sightingId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const sighting = snap.data();
    const reportId = context.params.reportId;
    const sightingId = context.params.sightingId;

    functions.logger.info(`[onSightingCreate] Sighting ${sightingId} reported for ${reportId}`);

    // Get the theft report to find the owner
    const reportDoc = await db.collection('theft_reports').doc(reportId).get();
    if (!reportDoc.exists) {
      functions.logger.warn(`[onSightingCreate] Report ${reportId} not found`);
      return;
    }

    const report = reportDoc.data()!;
    const ownerId = report.userId;

    // Get owner's FCM token and preferences
    const ownerDoc = await db.collection('users').doc(ownerId).get();
    if (!ownerDoc.exists) {
      functions.logger.warn(`[onSightingCreate] Owner ${ownerId} not found`);
      return;
    }

    const ownerData = ownerDoc.data()!;
    const fcmToken: string | undefined = ownerData.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onSightingCreate] No FCM token for owner ${ownerId}`);
      return;
    }

    // Check preferences
    const theftAlertsEnabled = ownerData.notif_theft_alerts !== false;
    if (!theftAlertsEnabled) {
      functions.logger.info(`[onSightingCreate] Theft alerts disabled for ${ownerId}`);
      return;
    }

    const bikeName = report.bikeName || 'Your bike';
    const sightingLocation = sighting.location as FirebaseFirestore.GeoPoint;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '👀 Bike Spotted!',
          body: `Someone may have seen ${bikeName}. Check the details now!`,
        },
        data: {
          type: 'bike_sighting',
          reportId,
          sightingId,
          latitude: sightingLocation.latitude.toString(),
          longitude: sightingLocation.longitude.toString(),
        },
        android: {
          notification: {
            channelId: 'theft_alerts',
            priority: 'max',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onSightingCreate] Notification sent to owner ${ownerId}`);
    } catch (error) {
      functions.logger.error(`[onSightingCreate] Failed to send notification:`, error);
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// ─── PHASE 1: SCHEDULED REMINDER FUNCTIONS ─────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

// ─── 16. checkUpcomingEvents ─────────────────────────────────────────────────
// Runs daily at 8 AM to remind participants about events happening today.

export const checkUpcomingEvents = functions.pubsub
  .schedule('0 8 * * *') // Daily at 8 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    functions.logger.info('[checkUpcomingEvents] Running daily event reminder check');

    const now = admin.firestore.Timestamp.now();
    const oneDayFromNow = admin.firestore.Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);

    // Get events happening in the next 24 hours
    const eventsSnapshot = await db.collection('events')
      .where('status', '==', 'upcoming')
      .where('dateTime', '>=', now)
      .where('dateTime', '<=', oneDayFromNow)
      .get();

    if (eventsSnapshot.empty) {
      functions.logger.info('[checkUpcomingEvents] No upcoming events');
      return;
    }

    functions.logger.info(`[checkUpcomingEvents] Found ${eventsSnapshot.size} upcoming events`);

    let totalNotifications = 0;

    for (const eventDoc of eventsSnapshot.docs) {
      const event = eventDoc.data();
      const eventId = eventDoc.id;
      const eventTitle = event.title || 'Your event';
      const eventTime = event.dateTime.toDate();
      const hoursUntil = Math.round((eventTime.getTime() - Date.now()) / (1000 * 60 * 60));

      // Get all participants
      const participantsSnapshot = await db.collection('events')
        .doc(eventId)
        .collection('participants')
        .get();

      const promises = participantsSnapshot.docs.map(async (participantDoc) => {
        const participant = participantDoc.data();
        const userId = participant.userId;

        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) return;

        const userData = userDoc.data()!;
        const fcmToken: string | undefined = userData.fcmToken;
        const eventUpdatesEnabled = userData.notif_event_updates !== false;

        if (!fcmToken || !eventUpdatesEnabled) return;

        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: `🚴 Event Starting Soon!`,
              body: `${eventTitle} starts in ${hoursUntil} hours`,
            },
            data: {
              type: 'event_reminder',
              eventId,
            },
            android: {
              notification: {
                channelId: 'events',
                priority: 'high',
              },
            },
            apns: {
              payload: {
                aps: { badge: 1, sound: 'default' },
              },
            },
          });
          totalNotifications++;
        } catch (error) {
          // Silently skip invalid tokens
        }
      });

      await Promise.all(promises);
    }

    functions.logger.info(`[checkUpcomingEvents] Sent ${totalNotifications} event reminders`);
  });

// ─── 17. checkUpcomingRentals ────────────────────────────────────────────────
// Runs every 2 hours to remind renters about pickups happening soon.

export const checkUpcomingRentals = functions.pubsub
  .schedule('0 */2 * * *') // Every 2 hours
  .timeZone('UTC')
  .onRun(async (context) => {
    functions.logger.info('[checkUpcomingRentals] Running rental reminder check');

    const now = admin.firestore.Timestamp.now();
    const twoHoursFromNow = admin.firestore.Timestamp.fromMillis(now.toMillis() + 2 * 60 * 60 * 1000);
    const oneHourFromNow = admin.firestore.Timestamp.fromMillis(now.toMillis() + 60 * 60 * 1000);

    // Get rentals starting in 1-2 hours that are still in "upcoming" status
    const rentalsSnapshot = await db.collection('rentalAgreements')
      .where('status', '==', 'upcoming')
      .where('startTime', '>=', oneHourFromNow)
      .where('startTime', '<=', twoHoursFromNow)
      .get();

    if (rentalsSnapshot.empty) {
      functions.logger.info('[checkUpcomingRentals] No upcoming rentals');
      return;
    }

    functions.logger.info(`[checkUpcomingRentals] Found ${rentalsSnapshot.size} upcoming rentals`);

    let sentCount = 0;

    const promises = rentalsSnapshot.docs.map(async (rentalDoc) => {
      const rental = rentalDoc.data();
      const startTime = rental.startTime.toDate();
      const hoursUntil = Math.round((startTime.getTime() - Date.now()) / (1000 * 60 * 60));

      // Get listing title
      const listingDoc = await db.collection('bikeListings').doc(rental.listingId).get();
      const listingTitle = listingDoc.exists ? listingDoc.data()!.title || 'your bike' : 'your bike';

      // Notify renter
      const renterDoc = await db.collection('users').doc(rental.renterId).get();
      if (renterDoc.exists) {
        const renterData = renterDoc.data()!;
        const fcmToken: string | undefined = renterData.fcmToken;
        const rentalUpdatesEnabled = renterData.notif_rental_updates !== false;

        if (fcmToken && rentalUpdatesEnabled) {
          try {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: '⏰ Rental Pickup Reminder',
                body: `Don't forget to pick up ${listingTitle} in ${hoursUntil} hours!`,
              },
              data: {
                type: 'rental_reminder',
                agreementId: rentalDoc.id,
                listingId: rental.listingId,
              },
              android: {
                notification: {
                  channelId: 'rental_updates',
                  priority: 'high',
                },
              },
              apns: {
                payload: {
                  aps: { badge: 1, sound: 'default' },
                },
              },
            });
            sentCount++;
          } catch (error) {
            // Silently skip invalid tokens
          }
        }
      }
    });

    await Promise.all(promises);
    functions.logger.info(`[checkUpcomingRentals] Sent ${sentCount} rental reminders`);
  });

// ─── 18. checkExpiringSubscriptions ──────────────────────────────────────────
// Runs daily at 9 AM to notify users about subscriptions expiring in 7 days.

export const checkExpiringSubscriptions = functions.pubsub
  .schedule('0 9 * * *') // Daily at 9 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    functions.logger.info('[checkExpiringSubscriptions] Running subscription expiry check');

    const now = admin.firestore.Timestamp.now();
    const sevenDaysFromNow = admin.firestore.Timestamp.fromMillis(now.toMillis() + 7 * 24 * 60 * 60 * 1000);
    const eightDaysFromNow = admin.firestore.Timestamp.fromMillis(now.toMillis() + 8 * 24 * 60 * 60 * 1000);

    // Get active subscriptions expiring in 7-8 days (so we only notify once)
    const subsSnapshot = await db.collection('subscriptions')
      .where('status', '==', 'active')
      .where('expiresAt', '>=', sevenDaysFromNow)
      .where('expiresAt', '<=', eightDaysFromNow)
      .get();

    if (subsSnapshot.empty) {
      functions.logger.info('[checkExpiringSubscriptions] No expiring subscriptions');
      return;
    }

    functions.logger.info(`[checkExpiringSubscriptions] Found ${subsSnapshot.size} expiring subscriptions`);

    let sentCount = 0;

    const promises = subsSnapshot.docs.map(async (subDoc) => {
      const subscription = subDoc.data();
      const userId = subscription.userId;

      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data()!;
      const fcmToken: string | undefined = userData.fcmToken;
      const subscriptionAlertsEnabled = userData.notif_subscription_alerts !== false;

      if (!fcmToken || !subscriptionAlertsEnabled) return;

      const planName = subscription.productId === 'cykel_premium_monthly' ? 'Premium' :
                       subscription.productId === 'cykel_student_annual' ? 'Student' :
                       'Premium';

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: '⏰ Subscription Expiring Soon',
            body: `Your ${planName} subscription expires in 7 days. Renew now to keep premium features!`,
          },
          data: {
            type: 'subscription_expiring',
            subscriptionId: subDoc.id,
            daysUntilExpiry: '7',
          },
          android: {
            notification: {
              channelId: 'subscription_alerts',
              priority: 'default',
            },
          },
          apns: {
            payload: {
              aps: { badge: 1, sound: 'default' },
            },
          },
        });
        sentCount++;
      } catch (error) {
        // Silently skip invalid tokens
      }
    });

    await Promise.all(promises);
    functions.logger.info(`[checkExpiringSubscriptions] Sent ${sentCount} expiry notifications`);
  });

// ═══════════════════════════════════════════════════════════════════════════
// ─── PHASE 2: SOCIAL & GAMIFICATION NOTIFICATIONS ──────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

// ─── 19. onFriendRequestCreate ───────────────────────────────────────────────
// Triggered when a friend request is sent.
// Notifies the receiver about the incoming friend request.

export const onFriendRequestCreate = functions.firestore
  .document('friendRequests/{requestId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const request = snap.data();
    const requestId = context.params.requestId;

    functions.logger.info(`[onFriendRequestCreate] Request ${requestId} created`);

    // Get receiver's FCM token and preferences
    const receiverDoc = await db.collection('users').doc(request.toUid).get();
    if (!receiverDoc.exists) {
      functions.logger.warn(`[onFriendRequestCreate] Receiver ${request.toUid} not found`);
      return;
    }

    const receiverData = receiverDoc.data()!;
    const fcmToken: string | undefined = receiverData.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onFriendRequestCreate] No FCM token for receiver ${request.toUid}`);
      return;
    }

    // Check preferences
    const socialUpdatesEnabled = receiverData.notif_social_updates !== false;
    if (!socialUpdatesEnabled) {
      functions.logger.info(`[onFriendRequestCreate] Social updates disabled for ${request.toUid}`);
      return;
    }

    const fromName = request.fromDisplayName || 'Someone';

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '👥 New Friend Request',
          body: `${fromName} wants to connect with you`,
        },
        data: {
          type: 'friend_request',
          requestId,
          fromUid: request.fromUid,
        },
        android: {
          notification: {
            channelId: 'social_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onFriendRequestCreate] Notification sent to ${request.toUid}`);
    } catch (error) {
      functions.logger.error(`[onFriendRequestCreate] Failed to send notification:`, error);
    }
  });

// ─── 20. onFriendRequestUpdate ───────────────────────────────────────────────
// Triggered when a friend request is accepted.
// Notifies the sender that their request was accepted.

export const onFriendRequestUpdate = functions.firestore
  .document('friendRequests/{requestId}')
  .onUpdate(async (change: functions.Change<QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const requestId = context.params.requestId;

    // Only notify if status changed to accepted
    if (before.status === after.status || after.status !== 'accepted') return;

    functions.logger.info(`[onFriendRequestUpdate] Request ${requestId} accepted`);

    // Get sender's FCM token and preferences
    const senderDoc = await db.collection('users').doc(after.fromUid).get();
    if (!senderDoc.exists) {
      functions.logger.warn(`[onFriendRequestUpdate] Sender ${after.fromUid} not found`);
      return;
    }

    const senderData = senderDoc.data()!;
    const fcmToken: string | undefined = senderData.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onFriendRequestUpdate] No FCM token for sender ${after.fromUid}`);
      return;
    }

    // Check preferences
    const socialUpdatesEnabled = senderData.notif_social_updates !== false;
    if (!socialUpdatesEnabled) {
      functions.logger.info(`[onFriendRequestUpdate] Social updates disabled for ${after.fromUid}`);
      return;
    }

    const toName = after.toDisplayName || 'Your friend';

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '✅ Friend Request Accepted!',
          body: `${toName} accepted your friend request`,
        },
        data: {
          type: 'friend_request_accepted',
          requestId,
          toUid: after.toUid,
        },
        android: {
          notification: {
            channelId: 'social_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onFriendRequestUpdate] Notification sent to ${after.fromUid}`);
    } catch (error) {
      functions.logger.error(`[onFriendRequestUpdate] Failed to send notification:`, error);
    }
  });

// ─── 21. onBuddyMatchCreate ──────────────────────────────────────────────────
// Triggered when a buddy match request is sent.
// Notifies the recipient about the incoming buddy match request.

export const onBuddyMatchCreate = functions.firestore
  .document('buddyMatches/{matchId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const match = snap.data();
    const matchId = context.params.matchId;

    functions.logger.info(`[onBuddyMatchCreate] Match ${matchId} created`);

    // Get recipient's (userId2) FCM token and preferences
    const user2Doc = await db.collection('users').doc(match.userId2).get();
    if (!user2Doc.exists) {
      functions.logger.warn(`[onBuddyMatchCreate] User2 ${match.userId2} not found`);
      return;
    }

    const user2Data = user2Doc.data()!;
    const fcmToken: string | undefined = user2Data.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onBuddyMatchCreate] No FCM token for user2 ${match.userId2}`);
      return;
    }

    // Check preferences
    const communityUpdatesEnabled = user2Data.notif_community_updates !== false;
    if (!communityUpdatesEnabled) {
      functions.logger.info(`[onBuddyMatchCreate] Community updates disabled for ${match.userId2}`);
      return;
    }

    // Get sender's (userId1) info
    const user1Doc = await db.collection('users').doc(match.userId1).get();
    const user1Name = user1Doc.exists ? user1Doc.data()!.name || 'Someone' : 'Someone';
    const user1Bio = user1Doc.exists ? user1Doc.data()!.bio || '' : '';
    const compatScore = match.compatibilityScore || 0;

    // ─── 1. Send FCM Notification ────────────────────────────────────────

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '👥 New Buddy Match Request',
          body: `${user1Name} wants to be your riding buddy! ${compatScore}% compatibility`,
        },
        data: {
          type: 'buddy_match_request',
          matchId,
          fromUserId: match.userId1,
          compatibilityScore: compatScore.toString(),
        },
        android: {
          notification: {
            channelId: 'community_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onBuddyMatchCreate] Notification sent to ${match.userId2}`);
    } catch (error) {
      functions.logger.error(`[onBuddyMatchCreate] Failed to send notification:`, error);
    }

    // ─── 2. Send Email to Recipient ──────────────────────────────────────

    const user2Email = user2Data.email;
    const user2Name = user2Data.name || 'there';
    if (!user2Email) {
      functions.logger.warn(`[onBuddyMatchCreate] No email for user2 ${match.userId2}`);
      return;
    }

    try {
      await db.collection('mail').add({
        to: user2Email,
        message: {
          subject: `👥 New Buddy Match Request from ${user1Name}`,
          html: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%); color: white; padding: 30px 20px; border-radius: 10px 10px 0 0; text-align: center; }
                .header h1 { margin: 0; font-size: 24px; }
                .content { background: #f8f9fa; padding: 30px 20px; border-radius: 0 0 10px 10px; }
                .match-card { background: white; border-radius: 8px; padding: 20px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                .score { font-size: 48px; color: #8b5cf6; font-weight: bold; text-align: center; margin: 20px 0; }
                .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>👥 New Buddy Match Request</h1>
              </div>
              <div class="content">
                <p>Hi ${user2Name},</p>
                <p>${user1Name} wants to be your riding buddy on CYKEL!</p>
                
                <div class="match-card">
                  <h2 style="margin-top: 0; color: #6366f1;">${user1Name}</h2>
                  
                  <div class="score">
                    ${compatScore}%
                  </div>
                  <p style="text-align: center; color: #666;">Compatibility Score</p>
                  
                  ${user1Bio ? `<p style="margin-top: 20px;"><strong>About ${user1Name}:</strong><br>${user1Bio}</p>` : ''}
                </div>
                
                <p><strong>Why connect with buddies?</strong></p>
                <ul>
                  <li>Find riding partners near you</li>
                  <li>Plan group rides together</li>
                  <li>Share routes and tips</li>
                  <li>Build a cycling community</li>
                </ul>
                
                <p>Open the CYKEL app to view ${user1Name}'s profile and accept or decline this request.</p>
                
                <div class="footer">
                  <p style="font-size: 12px; color: #999;">Email sent by CYKEL</p>
                </div>
              </div>
            </body>
            </html>
          `,
        },
        from: 'CYKEL <noreply@cykel.app>',
      });

      functions.logger.info(`[onBuddyMatchCreate] Email queued for ${user2Email}`);
    } catch (error) {
      functions.logger.error(`[onBuddyMatchCreate] Failed to send email:`, error);
    }
  });

// ─── 22. onBuddyMatchUpdate ──────────────────────────────────────────────────
// Triggered when a buddy match request is accepted.
// Notifies the sender that their buddy match was accepted.

export const onBuddyMatchUpdate = functions.firestore
  .document('buddyMatches/{matchId}')
  .onUpdate(async (change: functions.Change<QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const matchId = context.params.matchId;

    // Only notify if status changed to accepted
    if (before.status === after.status || after.status !== 'accepted') return;

    functions.logger.info(`[onBuddyMatchUpdate] Match ${matchId} accepted`);

    // Get sender's (userId1) FCM token and preferences
    const user1Doc = await db.collection('users').doc(after.userId1).get();
    if (!user1Doc.exists) {
      functions.logger.warn(`[onBuddyMatchUpdate] User1 ${after.userId1} not found`);
      return;
    }

    const user1Data = user1Doc.data()!;
    const fcmToken: string | undefined = user1Data.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onBuddyMatchUpdate] No FCM token for user1 ${after.userId1}`);
      return;
    }

    // Check preferences
    const communityUpdatesEnabled = user1Data.notif_community_updates !== false;
    if (!communityUpdatesEnabled) {
      functions.logger.info(`[onBuddyMatchUpdate] Community updates disabled for ${after.userId1}`);
      return;
    }

    // Get accepter's (userId2) info
    const user2Doc = await db.collection('users').doc(after.userId2).get();
    const user2Name = user2Doc.exists ? user2Doc.data()!.name || 'Your buddy' : 'Your buddy';

    // ─── 1. Send FCM Notification ────────────────────────────────────────

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🎉 Buddy Match Accepted!',
          body: `${user2Name} accepted your buddy match request. Start planning rides together!`,
        },
        data: {
          type: 'buddy_match_accepted',
          matchId,
          acceptedBy: after.userId2,
        },
        android: {
          notification: {
            channelId: 'community_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onBuddyMatchUpdate] Notification sent to ${after.userId1}`);
    } catch (error) {
      functions.logger.error(`[onBuddyMatchUpdate] Failed to send notification:`, error);
    }

    // ─── 2. Send Email to Original Sender ────────────────────────────────

    const user1Email = user1Data.email;
    const user1Name = user1Data.name || 'there';
    if (!user1Email) {
      functions.logger.warn(`[onBuddyMatchUpdate] No email for user1 ${after.userId1}`);
      return;
    }

    try {
      await db.collection('mail').add({
        to: user1Email,
        message: {
          subject: `🎉 ${user2Name} Accepted Your Buddy Match!`,
          html: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 30px 20px; border-radius: 10px 10px 0 0; text-align: center; }
                .header h1 { margin: 0; font-size: 24px; }
                .content { background: #f8f9fa; padding: 30px 20px; border-radius: 0 0 10px 10px; }
                .success-badge { background: #10b981; color: white; padding: 10px 20px; border-radius: 20px; display: inline-block; margin: 10px 0; font-size: 18px; }
                .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }
              </style>
            </head>
            <body>
              <div class="header">
                <h1>🎉 Buddy Match Accepted!</h1>
              </div>
              <div class="content">
                <div class="success-badge">✅ You're now buddies!</div>
                
                <p>Hi ${user1Name},</p>
                <p>Great news! ${user2Name} accepted your buddy match request.</p>
                
                <p><strong>What's next?</strong></p>
                <ul>
                  <li>Message ${user2Name} in the CYKEL app</li>
                  <li>Plan your first ride together</li>
                  <li>Share your favorite routes</li>
                  <li>Track your rides as a team</li>
                </ul>
                
                <p>Open the CYKEL app to start chatting and planning rides!</p>
                
                <div class="footer">
                  <p style="font-size: 12px; color: #999;">Email sent by CYKEL</p>
                </div>
              </div>
            </body>
            </html>
          `,
        },
        from: 'CYKEL <noreply@cykel.app>',
      });

      functions.logger.info(`[onBuddyMatchUpdate] Email queued for ${user1Email}`);
    } catch (error) {
      functions.logger.error(`[onBuddyMatchUpdate] Failed to send email:`, error);
    }
  });

// ─── 23. onSharedRideCreate ──────────────────────────────────────────────────
// Triggered when a user shares a ride.
// Notifies all friends about the shared ride.

export const onSharedRideCreate = functions.firestore
  .document('sharedRides/{rideId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const sharedRide = snap.data();
    const rideId = context.params.rideId;

    functions.logger.info(`[onSharedRideCreate] Ride ${rideId} shared by ${sharedRide.ownerUid}`);

    // Get owner's friends
    const friendsSnapshot = await db.collection('users')
      .doc(sharedRide.ownerUid)
      .collection('friends')
      .get();

    if (friendsSnapshot.empty) {
      functions.logger.info(`[onSharedRideCreate] No friends for ${sharedRide.ownerUid}`);
      return;
    }

    const ownerName = sharedRide.ownerDisplayName || 'Your friend';
    const distanceKm = Math.round(sharedRide.distanceKm * 10) / 10;

    let sentCount = 0;

    const promises = friendsSnapshot.docs.map(async (friendDoc) => {
      const friendUid = friendDoc.id;

      const friendUserDoc = await db.collection('users').doc(friendUid).get();
      if (!friendUserDoc.exists) return;

      const friendData = friendUserDoc.data()!;
      const fcmToken: string | undefined = friendData.fcmToken;
      const socialUpdatesEnabled = friendData.notif_social_updates !== false;

      if (!fcmToken || !socialUpdatesEnabled) return;

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: '🚴 New Ride Shared',
            body: `${ownerName} completed a ${distanceKm} km ride`,
          },
          data: {
            type: 'shared_ride',
            rideId,
            ownerUid: sharedRide.ownerUid,
          },
          android: {
            notification: {
              channelId: 'social_updates',
              priority: 'default',
            },
          },
          apns: {
            payload: {
              aps: { badge: 1, sound: 'default' },
            },
          },
        });
        sentCount++;
      } catch (error) {
        // Silently skip invalid tokens
      }
    });

    await Promise.all(promises);
    functions.logger.info(`[onSharedRideCreate] Sent ${sentCount} notifications for ride ${rideId}`);
  });

// ─── 22. onUserBadgeEarned ───────────────────────────────────────────────────
// Triggered when a user earns a badge.
// Notifies the user about their achievement.

export const onUserBadgeEarned = functions.firestore
  .document('users/{userId}/badges/{badgeDocId}')
  .onCreate(async (snap: QueryDocumentSnapshot, context: functions.EventContext) => {
    const badgeData = snap.data();
    const userId = context.params.userId;
    const badgeId = badgeData.badgeId;

    functions.logger.info(`[onUserBadgeEarned] User ${userId} earned badge ${badgeId}`);

    // Get badge details
    const badgeDoc = await db.collection('badges').doc(badgeId).get();
    if (!badgeDoc.exists) {
      functions.logger.warn(`[onUserBadgeEarned] Badge ${badgeId} not found`);
      return;
    }

    const badge = badgeDoc.data()!;

    // Get user's FCM token and preferences
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      functions.logger.warn(`[onUserBadgeEarned] User ${userId} not found`);
      return;
    }

    const userData = userDoc.data()!;
    const fcmToken: string | undefined = userData.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onUserBadgeEarned] No FCM token for user ${userId}`);
      return;
    }

    // Check preferences
    const gamificationEnabled = userData.notif_gamification !== false;
    if (!gamificationEnabled) {
      functions.logger.info(`[onUserBadgeEarned] Gamification disabled for ${userId}`);
      return;
    }

    const badgeName = badge.name || 'a new badge';
    const badgeIcon = badge.icon || '🏆';

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: `${badgeIcon} Badge Earned!`,
          body: `You earned the ${badgeName} badge!`,
        },
        data: {
          type: 'badge_earned',
          badgeId,
        },
        android: {
          notification: {
            channelId: 'gamification',
            priority: 'default',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onUserBadgeEarned] Notification sent to ${userId}`);
    } catch (error) {
      functions.logger.error(`[onUserBadgeEarned] Failed to send notification:`, error);
    }
  });

// ─── 23. onChallengeComplete ─────────────────────────────────────────────────
// Triggered when a user completes a challenge.
// Notifies the user of their accomplishment.

export const onChallengeComplete = functions.firestore
  .document('users/{userId}/challenges/{challengeId}')
  .onUpdate(async (change: functions.Change<QueryDocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    const challengeId = after.challengeId || context.params.challengeId;

    // Only notify if challenge just completed
    if (before.completedAt || !after.completedAt) return;

    functions.logger.info(`[onChallengeComplete] User ${userId} completed challenge ${challengeId}`);

    // Get challenge details
    const challengeDoc = await db.collection('challenges').doc(challengeId).get();
    if (!challengeDoc.exists) {
      functions.logger.warn(`[onChallengeComplete] Challenge ${challengeId} not found`);
      return;
    }

    const challenge = challengeDoc.data()!;

    // Get user's FCM token and preferences
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      functions.logger.warn(`[onChallengeComplete] User ${userId} not found`);
      return;
    }

    const userData = userDoc.data()!;
    const fcmToken: string | undefined = userData.fcmToken;
    
    if (!fcmToken) {
      functions.logger.warn(`[onChallengeComplete] No FCM token for user ${userId}`);
      return;
    }

    // Check preferences
    const gamificationEnabled = userData.notif_gamification !== false;
    if (!gamificationEnabled) {
      functions.logger.info(`[onChallengeComplete] Gamification disabled for ${userId}`);
      return;
    }

    const challengeName = challenge.name || 'Challenge';

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🎯 Challenge Complete!',
          body: `Congrats! You completed "${challengeName}"`,
        },
        data: {
          type: 'challenge_completed',
          challengeId,
        },
        android: {
          notification: {
            channelId: 'gamification',
            priority: 'default',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onChallengeComplete] Notification sent to ${userId}`);
    } catch (error) {
      functions.logger.error(`[onChallengeComplete] Failed to send notification:`, error);
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// ╔═╗┬ ┬┌─┐┌─┐┌─┐  ╔═╗ ╔╦╗  ╔═╗┌─┐┬  ┬┌─┐┬ ┬  ╔╗╔┌─┐┌┬┐┬┌─┐┬┌─┐┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
// ╠═╝├─┤├─┤└─┐├┤   ║║║  ║║  ╠═╝│ ││  │└─┐├─┤  ║║║│ │ │ │├┤ ││  ├─┤ │ ││ ││││└─┐
// ╩  ┴ ┴┴ ┴└─┘└─┘  ╚╩╝  ╩   ╩  └─┘┴─┘┴└─┘┴ ┴  ╝╚╝└─┘ ┴ ┴└  ┴└─┘┴ ┴ ┴ ┴└─┘┘└┘└─┘
// ═══════════════════════════════════════════════════════════════════════════
// Phase 3: Polish notifications - Group rides, system updates, marketplace

// ─── 24. onGroupRideInvitation ───────────────────────────────────────────────
// Notify users when invited to a group ride

export const onGroupRideInvitation = functions.firestore
  .document('groupRideInvitations/{invitationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const invitedUserId = data.invitedUserId;
    const groupRideId = data.groupRideId;
    const invitedBy = data.invitedBy;

    functions.logger.info(`[onGroupRideInvitation] User ${invitedUserId} invited to group ride ${groupRideId}`);

    // 1) Fetch group ride details
    const groupRideDoc = await admin.firestore().collection('groupRides').doc(groupRideId).get();
    if (!groupRideDoc.exists) {
      functions.logger.warn(`[onGroupRideInvitation] Group ride ${groupRideId} not found`);
      return;
    }
    const groupRideData = groupRideDoc.data();
    const rideName = groupRideData?.name || 'Unnamed Group Ride';
    const rideDate = groupRideData?.startTime?.toDate?.() || null;

    // 2) Fetch inviter details
    const inviterDoc = await admin.firestore().collection('users').doc(invitedBy).get();
    const inviterName = inviterDoc.exists ? (inviterDoc.data()?.displayName || 'Someone') : 'Someone';

    // 3) Fetch invited user document for FCM token and preferences
    const userDoc = await admin.firestore().collection('users').doc(invitedUserId).get();
    if (!userDoc.exists) {
      functions.logger.warn(`[onGroupRideInvitation] User ${invitedUserId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;
    if (!fcmToken) {
      functions.logger.warn(`[onGroupRideInvitation] No FCM token for user ${invitedUserId}`);
      return;
    }

    // 4) Check if community updates are disabled
    const communityEnabled = userData?.notif_community_updates ?? true;
    if (!communityEnabled) {
      functions.logger.info(`[onGroupRideInvitation] Community updates disabled for ${invitedUserId}`);
      return;
    }

    // 5) Format date
    const dateStr = rideDate 
      ? rideDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })
      : 'Soon';

    // 6) Send notification
    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🚴 Group Ride Invitation',
          body: `${inviterName} invited you to "${rideName}" on ${dateStr}`,
        },
        data: {
          type: 'group_ride_invitation',
          groupRideId,
          invitationId: context.params.invitationId,
          invitedBy,
        },
        android: {
          notification: {
            channelId: 'community_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onGroupRideInvitation] Notification sent to ${invitedUserId}`);
    } catch (error) {
      functions.logger.error(`[onGroupRideInvitation] Failed to send notification:`, error);
    }
  });

// ─── 25. onSystemAnnouncement ────────────────────────────────────────────────
// Notify all users of critical system announcements

export const onSystemAnnouncement = functions.firestore
  .document('systemAnnouncements/{announcementId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = data.title || 'System Update';
    const message = data.message || 'Please check the app for details';
    const priority = data.priority || 'normal'; // 'critical' | 'normal' | 'low'
    const targetAudience = data.targetAudience || 'all'; // 'all' | 'premium' | 'active' etc.

    functions.logger.info(`[onSystemAnnouncement] Broadcasting ${priority} announcement: ${title}`);

    // 1) Build query based on target audience
    let usersQuery: admin.firestore.Query | admin.firestore.CollectionReference = 
      admin.firestore().collection('users');

    if (targetAudience === 'premium') {
      usersQuery = usersQuery.where('premium', '==', true);
    } else if (targetAudience === 'active') {
      // Users active in last 30 days
      const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      );
      usersQuery = usersQuery.where('lastActiveAt', '>=', thirtyDaysAgo);
    }
    // else 'all' - no filter

    // 2) Fetch users
    const usersSnapshot = await usersQuery.get();
    functions.logger.info(`[onSystemAnnouncement] Found ${usersSnapshot.size} target users`);

    // 3) Build notification messages
    const messages: admin.messaging.Message[] = [];

    usersSnapshot.forEach((userDoc) => {
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;
      
      // Skip if no token
      if (!fcmToken) return;

      // Check if system updates are disabled
      const systemEnabled = userData?.notif_system_updates ?? true;
      if (!systemEnabled) return;

      // Determine channel priority
      const channelId = priority === 'critical' ? 'account_security' : 'system_updates';
      const androidPriority = priority === 'critical' ? 'high' : 'default';

      messages.push({
        token: fcmToken,
        notification: {
          title: `📢 ${title}`,
          body: message,
        },
        data: {
          type: 'system_announcement',
          announcementId: context.params.announcementId,
          priority,
        },
        android: {
          notification: {
            channelId,
            priority: androidPriority,
          },
        },
        apns: {
          payload: {
            aps: { 
              badge: priority === 'critical' ? 1 : 0, 
              sound: priority === 'critical' ? 'default' : undefined,
            },
          },
        },
      });
    });

    // 4) Send in batches of 500 (FCM limit)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < messages.length; i += batchSize) {
      const batch = messages.slice(i, i + batchSize);
      try {
        const response = await admin.messaging().sendAll(batch);
        successCount += response.successCount;
        failureCount += response.failureCount;
        
        // Log any failures
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            functions.logger.warn(`[onSystemAnnouncement] Failed to send to token:`, resp.error);
          }
        });
      } catch (error) {
        functions.logger.error(`[onSystemAnnouncement] Batch send failed:`, error);
        failureCount += batch.length;
      }
    }

    functions.logger.info(`[onSystemAnnouncement] Broadcast complete: ${successCount} sent, ${failureCount} failed`);
  });

// ═══════════════════════════════════════════════════════════════════════════
// ╔═╗┬ ┬┌─┐┌─┐┌─┐  ╦ ╦ ╦  ╔═╗┌┐┌┬ ┬┌─┐┌┐┌┌─┐┌─┐┌┬┐  ╔═╗─┐ ┬┌─┐┌─┐┬─┐┬┌─┐┌┐┌┌─┐┌─┐
// ╠═╝├─┤├─┤└─┐├┤   ║║║ ║  ║╣ │││├─┤├─┤││││  ├┤  ││  ║╣ ┌┴┬┘├─┘├┤ ├┬┘│├┤ ││││  ├┤ 
// ╩  ┴ ┴┴ ┴└─┘└─┘  ╩ ╩ ╩  ╚═╝┘└┘┴ ┴┴ ┴┘└┘└─┘└─┘─┴┘  ╚═╝┴ └─┴  └─┘┴└─┴└─┘┘└┘└─┘└─┘
// ═══════════════════════════════════════════════════════════════════════════
// Phase 4: Enhanced experience - Weather, stats, events, milestones

// ─── 26. checkWeatherForUpcomingRides ────────────────────────────────────────
// Scheduled function to check weather for rides in next 24 hours
// Runs daily at 6 AM to notify users of weather conditions

export const checkWeatherForUpcomingRides = functions.pubsub
  .schedule('0 6 * * *')
  .timeZone('America/Los_Angeles')
  .onRun(async (context) => {
    functions.logger.info('[checkWeatherForUpcomingRides] Starting weather check');

    const now = admin.firestore.Timestamp.now();
    const twentyFourHoursLater = admin.firestore.Timestamp.fromDate(
      new Date(now.toDate().getTime() + 24 * 60 * 60 * 1000)
    );

    // 1) Find all planned rides in next 24 hours
    const ridesSnapshot = await admin.firestore()
      .collection('plannedRides')
      .where('startTime', '>=', now)
      .where('startTime', '<=', twentyFourHoursLater)
      .where('cancelled', '==', false)
      .get();

    functions.logger.info(`[checkWeatherForUpcomingRides] Found ${ridesSnapshot.size} rides`);

    for (const rideDoc of ridesSnapshot.docs) {
      const rideData = rideDoc.data();
      const userId = rideData.userId;
      const startTime = rideData.startTime?.toDate();
      const location = rideData.startLocation; // { lat, lng }

      if (!location || !startTime) continue;

      // 2) Fetch user preferences
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (!userDoc.exists) continue;

      const userData = userDoc.data();
      const weatherEnabled = userData?.notif_weather_alerts ?? true;
      const fcmToken = userData?.fcmToken;

      if (!weatherEnabled || !fcmToken) continue;

      // 3) In production, fetch real weather data from API (OpenWeather, etc.)
      // For now, simulate weather data
      const weatherCondition = 'Rain'; // Could be 'Clear', 'Rain', 'Snow', 'Thunderstorm'
      const temperature = 15; // Celsius
      const shouldAlert = weatherCondition === 'Rain' || weatherCondition === 'Snow' || weatherCondition === 'Thunderstorm';

      if (!shouldAlert) continue;

      // 4) Send weather alert
      try {
        const timeStr = startTime.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
        
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: `🌧️ Weather Alert for Your Ride`,
            body: `${weatherCondition} expected at ${timeStr}. Check conditions before heading out.`,
          },
          data: {
            type: 'weather_alert',
            rideId: rideDoc.id,
            condition: weatherCondition,
            temperature: temperature.toString(),
          },
          android: {
            notification: {
              channelId: 'weather_alerts',
              priority: 'default',
            },
          },
          apns: {
            payload: {
              aps: { badge: 1, sound: 'default' },
            },
          },
        });

        functions.logger.info(`[checkWeatherForUpcomingRides] Weather alert sent to ${userId}`);
      } catch (error) {
        functions.logger.error(`[checkWeatherForUpcomingRides] Failed to send alert:`, error);
      }
    }

    functions.logger.info('[checkWeatherForUpcomingRides] Weather check complete');
  });

// ─── 27. sendWeeklyRideStats ─────────────────────────────────────────────────
// Scheduled function to send weekly ride statistics to users
// Runs every Monday at 9 AM

export const sendWeeklyRideStats = functions.pubsub
  .schedule('0 9 * * 1')
  .timeZone('America/Los_Angeles')
  .onRun(async (context) => {
    functions.logger.info('[sendWeeklyRideStats] Starting weekly stats generation');

    const now = new Date();
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const startTimestamp = admin.firestore.Timestamp.fromDate(oneWeekAgo);

    // 1) Find all users with rides in past week
    const usersSnapshot = await admin.firestore().collection('users').get();
    let sentCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();

      // Check preferences
      const statsEnabled = userData?.notif_ride_stats ?? true;
      const fcmToken = userData?.fcmToken;

      if (!statsEnabled || !fcmToken) continue;

      // 2) Query user's rides from past week
      const ridesSnapshot = await admin.firestore()
        .collection('rides')
        .where('userId', '==', userId)
        .where('endTime', '>=', startTimestamp)
        .get();

      if (ridesSnapshot.empty) continue;

      // 3) Calculate statistics
      let totalDistance = 0;
      let totalDuration = 0;
      let rideCount = ridesSnapshot.size;

      ridesSnapshot.forEach((rideDoc) => {
        const rideData = rideDoc.data();
        totalDistance += rideData.distance || 0;
        totalDuration += rideData.duration || 0;
      });

      const avgDistance = (totalDistance / rideCount).toFixed(1);
      const totalDistanceKm = (totalDistance / 1000).toFixed(1);
      const totalHours = Math.floor(totalDuration / 3600);
      const totalMinutes = Math.floor((totalDuration % 3600) / 60);

      // Estimate carbon saved (avg 0.12 kg CO2 per km saved vs car)
      const carbonSaved = (totalDistance / 1000 * 0.12).toFixed(1);

      // 4) Send statistics notification
      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: '📊 Your Week in Cycling',
            body: `${rideCount} rides • ${totalDistanceKm}km • ${carbonSaved}kg CO₂ saved!`,
          },
          data: {
            type: 'weekly_stats',
            rideCount: rideCount.toString(),
            totalDistance: totalDistanceKm,
            avgDistance,
            totalHours: totalHours.toString(),
            totalMinutes: totalMinutes.toString(),
            carbonSaved,
          },
          android: {
            notification: {
              channelId: 'ride_stats',
              priority: 'default',
            },
          },
          apns: {
            payload: {
              aps: { badge: 0, sound: undefined },
            },
          },
        });

        sentCount++;
        functions.logger.info(`[sendWeeklyRideStats] Stats sent to ${userId}`);
      } catch (error) {
        functions.logger.error(`[sendWeeklyRideStats] Failed to send stats:`, error);
      }
    }

    functions.logger.info(`[sendWeeklyRideStats] Weekly stats sent to ${sentCount} users`);
  });

// ─── 28. onLocalEventCreate ──────────────────────────────────────────────────
// Notify users about new cycling events near their location

export const onLocalEventCreate = functions.firestore
  .document('localEvents/{eventId}')
  .onCreate(async (snap, context) => {
    const eventData = snap.data();
    const eventName = eventData.name || 'Cycling Event';
    const eventDate = eventData.date?.toDate();
    const eventLocation = eventData.location; // { lat, lng, address }
    const eventType = eventData.type || 'general'; // 'race', 'group_ride', 'workshop', etc.

    functions.logger.info(`[onLocalEventCreate] New event: ${eventName}`);

    if (!eventLocation || !eventDate) {
      functions.logger.warn('[onLocalEventCreate] Missing location or date');
      return;
    }

    // 1) Find users within 25km radius
    const radiusKm = 25;
    const usersSnapshot = await admin.firestore().collection('users').get();

    let notifiedCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userLocation = userData?.location; // { lat, lng }
      const eventsEnabled = userData?.notif_local_events ?? true;
      const fcmToken = userData?.fcmToken;

      if (!eventsEnabled || !fcmToken || !userLocation) continue;

      // 2) Calculate distance using Haversine formula
      const distance = calculateDistance(
        userLocation.lat,
        userLocation.lng,
        eventLocation.lat,
        eventLocation.lng
      );

      if (distance > radiusKm) continue;

      // 3) Send event notification
      try {
        const dateStr = eventDate.toLocaleDateString('en-US', { 
          month: 'short', 
          day: 'numeric',
          hour: 'numeric',
          minute: '2-digit',
        });
        const distanceStr = distance < 1 ? `${Math.round(distance * 1000)}m` : `${distance.toFixed(1)}km`;

        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: '🚴 Local Cycling Event',
            body: `${eventName} on ${dateStr} • ${distanceStr} away`,
          },
          data: {
            type: 'local_event',
            eventId: context.params.eventId,
            eventType,
            distance: distance.toString(),
          },
          android: {
            notification: {
              channelId: 'local_events',
              priority: 'default',
            },
          },
          apns: {
            payload: {
              aps: { badge: 1, sound: 'default' },
            },
          },
        });

        notifiedCount++;
      } catch (error) {
        functions.logger.error(`[onLocalEventCreate] Failed to notify user:`, error);
      }
    }

    functions.logger.info(`[onLocalEventCreate] Notified ${notifiedCount} users`);
  });

// ─── 29. onMilestoneAchieved ─────────────────────────────────────────────────
// Notify users when they achieve significant milestones

export const onMilestoneAchieved = functions.firestore
  .document('users/{userId}/milestones/{milestoneId}')
  .onCreate(async (snap, context) => {
    const milestoneData = snap.data();
    const userId = context.params.userId;
    const milestoneType = milestoneData.type; // 'distance', 'carbon', 'streak', 'rides'
    const value = milestoneData.value;

    functions.logger.info(`[onMilestoneAchieved] ${userId} achieved ${milestoneType} milestone: ${value}`);

    // 1) Fetch user document
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      functions.logger.warn(`[onMilestoneAchieved] User ${userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const milestonesEnabled = userData?.notif_milestones ?? true;
    const fcmToken = userData?.fcmToken;

    if (!milestonesEnabled || !fcmToken) {
      functions.logger.info(`[onMilestoneAchieved] Milestones disabled for ${userId}`);
      return;
    }

    // 2) Format milestone message
    let emoji = '🎉';
    let title = 'Milestone Achieved!';
    let body = '';

    switch (milestoneType) {
      case 'distance':
        emoji = '🏆';
        title = 'Distance Milestone!';
        body = `You've cycled ${value}km total! Keep riding!`;
        break;
      case 'carbon':
        emoji = '🌍';
        title = 'Carbon Hero!';
        body = `You've saved ${value}kg of CO₂! Great work!`;
        break;
      case 'streak':
        emoji = '🔥';
        title = 'Ride Streak!';
        body = `${value} days riding streak! You're on fire!`;
        break;
      case 'rides':
        emoji = '🚴';
        title = 'Ride Count Milestone!';
        body = `You've completed ${value} rides! Amazing!`;
        break;
      default:
        body = `You've achieved a new milestone: ${value}`;
    }

    // 3) Send milestone notification
    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: `${emoji} ${title}`,
          body,
        },
        data: {
          type: 'milestone',
          milestoneType,
          value: value.toString(),
          milestoneId: context.params.milestoneId,
        },
        android: {
          notification: {
            channelId: 'milestones',
            priority: 'default',
          },
        },
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
      });

      functions.logger.info(`[onMilestoneAchieved] Notification sent to ${userId}`);
    } catch (error) {
      functions.logger.error(`[onMilestoneAchieved] Failed to send notification:`, error);
    }
  });

// ─── Helper: Calculate distance between two coordinates ──────────────────────
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ═══════════════════════════════════════════════════════════════════════════
// SECURITY FUNCTIONS (CRITICAL FIXES - April 2026)
// ═══════════════════════════════════════════════════════════════════════════

/**
 * GDPR Compliance: Auto-delete chat messages older than 90 days
 * Runs daily at 2 AM UTC
 */
export const scheduledCleanupOldMessages = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      await cleanupOldMessages();
      return { success: true };
    } catch (error) {
      functions.logger.error('[scheduledCleanupOldMessages] Error:', error);
      throw error;
    }
  });

/**
 * GDPR Compliance: Admin-triggered manual message cleanup
 */
export const adminCleanupMessages = functions.https.onCall(async (data, context) => {
  // Verify admin
  if (!context.auth || context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can trigger message cleanup'
    );
  }

  const { days } = data;

  try {
    const result = await manualCleanupMessages(days);
    return result;
  } catch (error) {
    functions.logger.error('[adminCleanupMessages] Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to cleanup messages');
  }
});

/**
 * Security Monitoring: Detects spam, DoS attacks, and abuse patterns
 * Runs every 5 minutes
 */
export const scheduledSecurityMonitoring = functions.pubsub
  .schedule('*/5 * * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      await monitorSecurity();
      return { success: true };
    } catch (error) {
      functions.logger.error('[scheduledSecurityMonitoring] Error:', error);
      throw error;
    }
  });

/**
 * Security Dashboard: Get security alerts for admin UI
 */
export const adminGetSecurityAlerts = functions.https.onCall(async (data, context) => {
  // Verify admin
  if (!context.auth || context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can view security alerts'
    );
  }

  const { limit } = data;

  try {
    const alerts = await getSecurityAlerts(limit);
    return { success: true, alerts };
  } catch (error) {
    functions.logger.error('[adminGetSecurityAlerts] Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get security alerts');
  }
});

/**
 * Rate Limit Management: Scheduled cleanup of old rate limit documents
 * Runs daily at 3 AM UTC to clean up documents older than 7 days
 */
export const scheduledCleanupRateLimits = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const deletedCount = await cleanupOldRateLimits();
      functions.logger.info(`[scheduledCleanupRateLimits] Deleted ${deletedCount} old rate limit documents`);
      return { success: true, deletedCount };
    } catch (error) {
      functions.logger.error('[scheduledCleanupRateLimits] Error:', error);
      throw error;
    }
  });

/**
 * Admin Tools: Get rate limit info for a user
 */
export const adminGetUserRateLimit = functions.https.onCall(async (data, context) => {
  // Verify admin
  if (!context.auth || context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can view rate limits'
    );
  }

  const { userId, action } = data;

  if (!userId || !action) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userId and action are required'
    );
  }

  try {
    const info = await getRateLimitInfo(userId, action);
    return { success: true, ...info };
  } catch (error) {
    functions.logger.error('[adminGetUserRateLimit] Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get rate limit info');
  }
});

/**
 * Admin Tools: Clear rate limit for a user (emergency override)
 */
export const adminClearUserRateLimit = functions.https.onCall(async (data, context) => {
  // Verify admin
  if (!context.auth || context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can clear rate limits'
    );
  }

  const { userId, action } = data;

  if (!userId || !action) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userId and action are required'
    );
  }

  try {
    await clearRateLimit(userId, action);

    // Log to audit trail
    await admin.firestore().collection('auditLog').add({
      action: 'rate_limit_cleared',
      targetUserId: userId,
      rateLimitAction: action,
      clearedBy: context.auth.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`[adminClearUserRateLimit] Admin ${context.auth.uid} cleared ${action} for user ${userId}`);
    return { success: true };
  } catch (error) {
    functions.logger.error('[adminClearUserRateLimit] Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to clear rate limit');
  }
});

