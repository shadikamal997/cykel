/// CYKEL — GDPR Consent Dialog
/// First-launch consent dialog for data collection

import 'package:flutter/material.dart';
import '../services/consent_manager.dart';

class GDPRConsentDialog extends StatefulWidget {
  final ConsentManager consentManager;
  final VoidCallback onCompleted;

  const GDPRConsentDialog({
    super.key,
    required this.consentManager,
    required this.onCompleted,
  });

  @override
  State<GDPRConsentDialog> createState() => _GDPRConsentDialogState();
}

class _GDPRConsentDialogState extends State<GDPRConsentDialog> {
  bool _locationConsent = true; // Required for core functionality
  bool _analyticsConsent = true;
  bool _marketingConsent = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A7C59).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Color(0xFF4A7C59),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Privacy Matters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how we use your data',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Introduction
            Text(
              'We value your privacy and comply with GDPR. Please review and accept our data usage policies:',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 20),

            // Location Consent (Required)
            _buildConsentTile(
              icon: Icons.location_on_outlined,
              title: 'Location Services',
              description: 'Required to show nearby rides, events, and services. You can control permissions in device settings.',
              value: _locationConsent,
              isRequired: true,
              onChanged: null, // Cannot be changed since it's required
              isDark: isDark,
            ),

            const SizedBox(height: 12),

            // Analytics Consent (Optional)
            _buildConsentTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics & Performance',
              description: 'Help us improve the app by collecting anonymous usage data.',
              value: _analyticsConsent,
              isRequired: false,
              onChanged: (value) => setState(() => _analyticsConsent = value),
              isDark: isDark,
            ),

            const SizedBox(height: 12),

            // Marketing Consent (Optional)
            _buildConsentTile(
              icon: Icons.email_outlined,
              title: 'Marketing Communications',
              description: 'Receive updates about new features, events, and cycling tips.',
              value: _marketingConsent,
              isRequired: false,
              onChanged: (value) => setState(() => _marketingConsent = value),
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Privacy Policy Link
            Center(
              child: TextButton(
                onPressed: () {
                  // Open privacy policy
                  // TODO: Navigate to privacy policy screen
                },
                child: Text(
                  'Read our Privacy Policy',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF63B3ED) : const Color(0xFF4A7C59),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // Reject optional consents
                      await widget.consentManager.setConsents(
                        location: true, // Required
                        analytics: false,
                        marketing: false,
                      );
                      widget.onCompleted();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'Essential Only',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      // Accept all consents as configured
                      await widget.consentManager.setConsents(
                        location: _locationConsent,
                        analytics: _analyticsConsent,
                        marketing: _marketingConsent,
                      );
                      widget.onCompleted();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7C59),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required bool isRequired,
    required void Function(bool)? onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF4A7C59),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    if (isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A7C59),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF4A7C59),
          ),
        ],
      ),
    );
  }
}
