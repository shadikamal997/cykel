import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

/// Admin Migration Screen
/// 
/// This screen allows admins to trigger the displayNameLower migration
/// 
/// Usage:
/// 1. Navigate to this screen
/// 2. Tap "Run Migration" button
/// 3. Wait for completion message
/// 
/// The migration will:
/// - Process all users in batches
/// - Add displayNameLower field to users who don't have it
/// - Skip users who already have the field

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isLoading = false;
  String? _result;

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('migrateDisplayNameLower');
      
      final response = await callable.call();
      final data = response.data as Map<String, dynamic>;
      
      setState(() {
        _result = '✅ ${data['message']}\n\n'
            'Total processed: ${data['totalProcessed']}\n'
            'Total updated: ${data['totalUpdated']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Display Name Migration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will add the displayNameLower field to all users. '
              'This field is required for case-insensitive user search.',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _runMigration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Migration'),
            ),
            const SizedBox(height: 24),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
