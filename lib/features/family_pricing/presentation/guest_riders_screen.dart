import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_image.dart';
import '../../auth/domain/app_user.dart';
import '../application/family_extras_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_extras.dart';

/// Screen for managing guest riders
class GuestRidersScreen extends ConsumerWidget {
  const GuestRidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAccountAsync = ref.watch(familyAccountProvider);

    return familyAccountAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Guest Riders')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Guest Riders')),
            body: const Center(child: Text('No family account found')),
          );
        }

        return _GuestRidersContent(familyId: account.id);
      },
    );
  }
}

class _GuestRidersContent extends ConsumerStatefulWidget {
  final String familyId;

  const _GuestRidersContent({required this.familyId});

  @override
  ConsumerState<_GuestRidersContent> createState() => _GuestRidersContentState();
}

class _GuestRidersContentState extends ConsumerState<_GuestRidersContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Riders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Guests'),
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveGuestsTab(familyId: widget.familyId),
          _InvitationsTab(familyId: widget.familyId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Invite Guest'),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _InviteGuestSheet(familyId: widget.familyId),
    );
  }
}

// ==========================================
// Active Guests Tab
// ==========================================

class _ActiveGuestsTab extends ConsumerWidget {
  final String familyId;

  const _ActiveGuestsTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestsAsync = ref.watch(activeGuestsProvider(familyId));

    return guestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (guests) {
        if (guests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active guests',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Invite friends or family for temporary access',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: guests.length,
          itemBuilder: (context, index) {
            return _GuestMemberCard(
              guest: guests[index],
              familyId: familyId,
            );
          },
        );
      },
    );
  }
}

class _GuestMemberCard extends ConsumerWidget {
  final GuestMember guest;
  final String familyId;

  const _GuestMemberCard({
    required this.guest,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                AppAvatar(
                  url: guest.photoUrl,
                  thumbnailUrl: AppUser.getThumbnailUrl(guest.photoUrl),
                  size: 48,
                  fallbackText: guest.name.isNotEmpty ? guest.name[0].toUpperCase() : 'G',
                ),
                const SizedBox(width: 12),

                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            guest.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (guest.isOnline) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        guest.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Days remaining badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: guest.daysRemaining <= 2
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${guest.daysRemaining} days left',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: guest.daysRemaining <= 2 ? Colors.red : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Info row
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: 'Joined ${dateFormat.format(guest.joinedAt)}',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: guest.isTracking ? Icons.location_on : Icons.location_off,
                  label: guest.isTracking ? 'Tracking on' : 'Tracking off',
                  color: guest.isTracking ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _extendAccess(context, ref),
                    icon: const Icon(Icons.timer),
                    label: const Text('Extend'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _removeGuest(context, ref),
                    icon: const Icon(Icons.person_remove),
                    label: const Text('Remove'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
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

  void _extendAccess(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Access'),
        content: const Text('Would you like to extend this guest\'s access by 7 days?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final newExpiry = guest.expiresAt.add(const Duration(days: 7));
                await FirebaseFirestore.instance
                    .collection('familyAccounts')
                    .doc(familyId)
                    .collection('guests')
                    .doc(guest.id)
                    .update({
                  'expiresAt': Timestamp.fromDate(newExpiry),
                  'daysRemaining': guest.daysRemaining + 7,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Access extended by 7 days')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to extend access: $e')),
                  );
                }
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _removeGuest(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Guest'),
        content: Text('Are you sure you want to remove ${guest.name} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(familyExtrasServiceProvider);
                await service.removeGuest(familyId, guest.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Guest removed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: chipColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: chipColor),
        ),
      ],
    );
  }
}

// ==========================================
// Invitations Tab
// ==========================================

class _InvitationsTab extends ConsumerWidget {
  final String familyId;

  const _InvitationsTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(guestInvitesProvider(familyId));

    return invitesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (invites) {
        if (invites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No invitations sent',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final pending = invites.where((i) => i.isPending).toList();
        final others = invites.where((i) => !i.isPending).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              const _SectionHeader(title: 'Pending'),
              ...pending.map((invite) => _InviteCard(
                    invite: invite,
                    familyId: familyId,
                  )),
              const SizedBox(height: 16),
            ],
            if (others.isNotEmpty) ...[
              const _SectionHeader(title: 'History'),
              ...others.map((invite) => _InviteCard(
                    invite: invite,
                    familyId: familyId,
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  final GuestInvite invite;
  final String familyId;

  const _InviteCard({
    required this.invite,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(invite.status).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(invite.status),
                color: _getStatusColor(invite.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invite.guestEmail,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Invited by ${invite.invitedByName} • ${dateFormat.format(invite.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(invite.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(invite.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(invite.status),
                ),
              ),
            ),

            // Revoke button (only for pending)
            if (invite.isPending) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _revokeInvite(context, ref),
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Revoke',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(GuestInviteStatus status) {
    switch (status) {
      case GuestInviteStatus.pending:
        return Colors.orange;
      case GuestInviteStatus.accepted:
        return Colors.green;
      case GuestInviteStatus.declined:
        return Colors.red;
      case GuestInviteStatus.expired:
        return Colors.grey;
      case GuestInviteStatus.revoked:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(GuestInviteStatus status) {
    switch (status) {
      case GuestInviteStatus.pending:
        return Icons.hourglass_empty;
      case GuestInviteStatus.accepted:
        return Icons.check;
      case GuestInviteStatus.declined:
        return Icons.close;
      case GuestInviteStatus.expired:
        return Icons.timer_off;
      case GuestInviteStatus.revoked:
        return Icons.block;
    }
  }

  String _getStatusText(GuestInviteStatus status) {
    switch (status) {
      case GuestInviteStatus.pending:
        return 'Pending';
      case GuestInviteStatus.accepted:
        return 'Accepted';
      case GuestInviteStatus.declined:
        return 'Declined';
      case GuestInviteStatus.expired:
        return 'Expired';
      case GuestInviteStatus.revoked:
        return 'Revoked';
    }
  }

  void _revokeInvite(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invitation'),
        content: const Text('Are you sure you want to revoke this invitation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(familyExtrasServiceProvider);
                await service.revokeGuestInvite(familyId, invite.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation revoked')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Invite Guest Sheet
// ==========================================

class _InviteGuestSheet extends ConsumerStatefulWidget {
  final String familyId;

  const _InviteGuestSheet({required this.familyId});

  @override
  ConsumerState<_InviteGuestSheet> createState() => _InviteGuestSheetState();
}

class _InviteGuestSheetState extends ConsumerState<_InviteGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  int _maxDays = 7;
  bool _canTrack = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Invite Guest Rider',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Guests get temporary access to ride with your family',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Guest Email',
                          hintText: 'Enter guest\'s email address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Duration selector
                      const Text(
                        'Access Duration',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [1, 3, 7, 14, 30].map((days) {
                          return ChoiceChip(
                            label: Text('$days ${days == 1 ? 'day' : 'days'}'),
                            selected: _maxDays == days,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _maxDays = days);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Tracking toggle
                      SwitchListTile(
                        title: const Text('Allow Location Tracking'),
                        subtitle: const Text(
                          'Family members can see guest\'s location while they ride',
                        ),
                        value: _canTrack,
                        onChanged: (value) => setState(() => _canTrack = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Personal message
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Personal Message (Optional)',
                          hintText: 'Add a note for your guest',
                          prefixIcon: Icon(Icons.message),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Send button
              SafeArea(
                child: FilledButton(
                  onPressed: _isLoading ? null : _sendInvite,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Invitation'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.sendGuestInvite(
        familyId: widget.familyId,
        guestEmail: _emailController.text.trim().toLowerCase(),
        personalMessage: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        maxDays: _maxDays,
        canTrack: _canTrack,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ==========================================
// Pending Invites Widget (for home screen)
// ==========================================

/// Widget to show pending invites for the current user
class PendingGuestInvitesWidget extends ConsumerWidget {
  const PendingGuestInvitesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(myPendingInvitesProvider);

    return invitesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (invites) {
        if (invites.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Family Invitations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...invites.map((invite) => _PendingInviteListTile(invite: invite)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _PendingInviteListTile extends ConsumerWidget {
  final GuestInvite invite;

  const _PendingInviteListTile({required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const AppAvatar(
        url: null,
        size: 40,
        fallbackIcon: Icons.group,
      ),
      title: Text('Join ${invite.invitedByName}\'s family'),
      subtitle: Text(
        '${invite.maxDays} days access • Expires ${DateFormat('MMM d').format(invite.expiresAt)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _declineInvite(context, ref),
            icon: const Icon(Icons.close, color: Colors.red),
          ),
          IconButton(
            onPressed: () => _acceptInvite(context, ref),
            icon: const Icon(Icons.check, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvite(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.acceptGuestInvite(invite.familyId, invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'ve joined as a guest!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _declineInvite(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.declineGuestInvite(invite.familyId, invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
