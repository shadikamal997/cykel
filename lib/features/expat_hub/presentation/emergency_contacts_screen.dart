/// CYKEL — Emergency Contacts Screen
/// Quick access to emergency numbers and contacts

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/expat_resource.dart';
import '../application/expat_hub_providers.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EmergencyContact> _filterContacts(List<EmergencyContact> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    
    final query = _searchQuery.toLowerCase();
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
             contact.phoneNumber.contains(query) ||
             contact.type.displayName.toLowerCase().contains(query) ||
             (contact.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    final available247Async = ref.watch(available247ContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search emergency contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Warning banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.emergency, size: 48, color: Colors.red[700]),
                const SizedBox(height: 12),
                Text(
                  'In case of emergency, call 112',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '112 is the universal emergency number in Denmark',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _launchPhone('112'),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call 112 Emergency'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 24/7 contacts
          if (_searchQuery.isEmpty) ...[
            const Text(
              '24/7 Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
          available247Async.when(
            data: (contacts) {
              final filtered = _filterContacts(contacts);
              if (filtered.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: filtered.map((contact) {
                  return _ContactCard(contact: contact, highlighted: true);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // All contacts
          if (_searchQuery.isEmpty)
            const Text(
              'All Contacts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          contactsAsync.when(
            data: (contacts) {
              final filtered = _filterContacts(contacts);
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No contacts found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group by type
              final grouped = <EmergencyType, List<EmergencyContact>>{};
              for (final contact in filtered) {
                grouped[contact.type] ??= [];
                grouped[contact.type]!.add(contact);
              }

              return Column(
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          '${entry.key.icon} ${entry.key.displayName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...entry.value.map((contact) {
                        return _ContactCard(contact: contact);
                      }),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading contacts: $error'),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    this.highlighted = false,
  });

  final EmergencyContact contact;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlighted ? Colors.red[50] : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red[200]!),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: highlighted ? Colors.red[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      contact.type.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        contact.type.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (contact.isAvailable24x7)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '24/7',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (contact.description != null) ...[
              Text(
                contact.description!,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchPhone(contact.phoneNumber),
                    icon: const Icon(Icons.phone),
                    label: Text(contact.phoneNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: highlighted ? Colors.red[700] : null,
                      foregroundColor: highlighted ? Colors.white : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _copyToClipboard(
                    context,
                    contact.phoneNumber,
                  ),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy number',
                ),
              ],
            ),
            if (contact.speaksEnglish) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'English spoken',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (contact.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      contact.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
