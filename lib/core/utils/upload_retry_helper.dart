/// CYKEL — Upload Retry Helper
/// Exponential backoff retry logic for file uploads

import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class UploadRetryHelper {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);
  static const int backoffMultiplier = 2;

  /// Upload a single file with retry logic
  /// Returns download URL on success, throws on failure after all retries
  static Future<String> uploadFileWithRetry({
    required Reference storageRef,
    required File file,
    SettableMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt < maxRetries) {
      try {
        debugPrint('[UploadRetry] Attempt ${attempt + 1}/$maxRetries for ${storageRef.fullPath}');
        
        final uploadTask = storageRef.putFile(file, metadata);
        
        // Track progress if callback provided
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          });
        }

        // Wait for upload to complete
        await uploadTask;
        
        // Get download URL
        final downloadUrl = await storageRef.getDownloadURL();
        debugPrint('[UploadRetry] ✅ Upload succeeded: ${storageRef.fullPath}');
        return downloadUrl;
        
      } on FirebaseException catch (e) {
        attempt++;
        
        // Check if error is retryable
        if (!_isRetryableError(e) || attempt >= maxRetries) {
          debugPrint('[UploadRetry] ❌ Upload failed permanently: ${e.code} - ${e.message}');
          throw UploadException(
            'Upload failed after $attempt attempts: ${e.message}',
            originalException: e,
          );
        }

        // Wait before retry with exponential backoff
        debugPrint('[UploadRetry] ⚠️ Upload failed (${e.code}), retrying in ${currentDelay.inSeconds}s...');
        await Future.delayed(currentDelay);
        currentDelay *= backoffMultiplier;
        
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries) {
          debugPrint('[UploadRetry] ❌ Upload failed permanently: $e');
          throw UploadException(
            'Upload failed after $attempt attempts: $e',
            originalException: e,
          );
        }

        debugPrint('[UploadRetry] ⚠️ Upload failed, retrying in ${currentDelay.inSeconds}s...');
        await Future.delayed(currentDelay);
        currentDelay *= backoffMultiplier;
      }
    }

    throw UploadException('Upload failed after $maxRetries attempts');
  }

  /// Upload multiple files in parallel with retry logic
  /// Returns list of download URLs on success
  static Future<List<String>> uploadMultipleFilesWithRetry({
    required List<File> files,
    required String Function(int index, String fileName) pathBuilder,
    required Reference storageRoot,
    SettableMetadata? metadata,
    void Function(int fileIndex, double progress)? onProgress,
  }) async {
    final futures = files.asMap().entries.map((entry) async {
      final index = entry.key;
      final file = entry.value;
      final fileName = file.path.split('/').last;
      final path = pathBuilder(index, fileName);
      final ref = storageRoot.child(path);
      
      return uploadFileWithRetry(
        storageRef: ref,
        file: file,
        metadata: metadata,
        onProgress: onProgress != null 
            ? (progress) => onProgress(index, progress) 
            : null,
      );
    });

    return Future.wait(futures);
  }

  /// Upload XFile (from image picker) with retry logic
  static Future<String> uploadXFileWithRetry({
    required Reference storageRef,
    required XFile xFile,
    SettableMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    return uploadFileWithRetry(
      storageRef: storageRef,
      file: File(xFile.path),
      metadata: metadata,
      onProgress: onProgress,
    );
  }

  /// Upload multiple XFiles in parallel with retry logic
  static Future<List<String>> uploadMultipleXFilesWithRetry({
    required List<XFile> files,
    required String Function(int index, String fileName) pathBuilder,
    required Reference storageRoot,
    SettableMetadata? metadata,
    void Function(int fileIndex, double progress)? onProgress,
  }) async {
    final futures = files.asMap().entries.map((entry) async {
      final index = entry.key;
      final xFile = entry.value;
      final path = pathBuilder(index, xFile.name);
      final ref = storageRoot.child(path);
      
      return uploadXFileWithRetry(
        storageRef: ref,
        xFile: xFile,
        metadata: metadata,
        onProgress: onProgress != null 
            ? (progress) => onProgress(index, progress) 
            : null,
      );
    });

    return Future.wait(futures);
  }

  /// Check if Firebase error is retryable
  static bool _isRetryableError(FirebaseException e) {
    // Retry on network errors, timeouts, and server errors
    final retryableCodes = [
      'unavailable',        // Network unavailable
      'deadline-exceeded',  // Timeout
      'internal',          // Server error
      'unknown',           // Unknown transient error
      'cancelled',         // Request cancelled
    ];
    
    return retryableCodes.contains(e.code);
  }
}

/// Custom exception for upload failures
class UploadException implements Exception {
  final String message;
  final Object? originalException;

  UploadException(this.message, {this.originalException});

  @override
  String toString() => 'UploadException: $message';
}
