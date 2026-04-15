import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_account.dart';

/// Family account management screen
class FamilyManagementScreen extends ConsumerWidget {
  const FamilyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAccount = ref.watch(familyAccountProvider);
    final pendingInvitations = ref.watch(pendingInvitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Account'),
        centerTitle: true,
        actions: [
          if (familyAccount.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showFamilySettings(context, ref),
            ),
        ],
      ),
      body: familyAccount.when(
        data: (account) {
          if (account == null) {
            return _NoFamilyAccountView(
              pendingInvitations: pendingInvitations.valueOrNull ?? [],
              onAcceptInvitation: (id) => _acceptInvitation(context, ref, id),
              onDeclineInvitation: (id) => _declineInvitation(ref, id),
            );
          }
          return _FamilyAccountView(
            account: account,
            onInviteMember: () => _showInviteDialog(context, ref, account.id),
            onRemoveMember: (userId) =>
                _removeMember(context, ref, account.id, userId),
            onChangeRole: (userId, role) =>
                _changeRole(ref, account.id, userId, role),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading family account: $error'),
        ),
      ),
    );
  }

  void _showFamilySettings(BuildContext context, WidgetRef ref) {
    final account = ref.read(familyAccountProvider).valueOrNull;
    if (account == null) return;

    final nameController = TextEditingController(text: account.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Family Settings',
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Family Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final service = ref.read(familyPricingServiceProvider);
                await service.updateFamilyName(
                    account.id, nameController.text.trim());
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(
      BuildContext context, WidgetRef ref, String familyAccountId) {
    final emailController = TextEditingController();
    FamilyRole selectedRole = FamilyRole.member;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Invite Family Member',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'member@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Role',
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [FamilyRole.member, FamilyRole.admin, FamilyRole.child]
                    .map((role) => ChoiceChip(
                          label: Text(role.displayName),
                          selected: selectedRole == role,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedRole = role);
                            }
                          },
                          selectedColor: AppColors.primaryLight,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  try {
                    final service = ref.read(familyPricingServiceProvider);
                    await service.inviteFamilyMember(
                      familyAccountId: familyAccountId,
                      inviteeEmail: email,
                      role: selectedRole,
                    );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invitation sent to $email')),
                      );
                    }
                  } catch (e) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Send Invitation'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(
      BuildContext context, WidgetRef ref, String invitationId) async {
    try {
      final service = ref.read(familyPricingServiceProvider);
      await service.acceptInvitation(invitationId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to the family!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _declineInvitation(WidgetRef ref, String invitationId) async {
    final service = ref.read(familyPricingServiceProvider);
    await service.declineInvitation(invitationId);
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref,
      String familyAccountId, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
            'Are you sure you want to remove this member from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(familyPricingServiceProvider);
      await service.removeFamilyMember(familyAccountId, userId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _changeRole(WidgetRef ref, String familyAccountId, String userId,
      FamilyRole newRole) {
    final service = ref.read(familyPricingServiceProvider);
    service.updateMemberRole(familyAccountId, userId, newRole);
  }
}

/// View when user has no family account
class _NoFamilyAccountView extends StatelessWidget {
  final List<FamilyInvitation> pendingInvitations;
  final ValueChanged<String> onAcceptInvitation;
  final ValueChanged<String> onDeclineInvitation;

  const _NoFamilyAccountView({
    required this.pendingInvitations,
    required this.onAcceptInvitation,
    required this.onDeclineInvitation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pending invitations
          if (pendingInvitations.isNotEmpty) ...[
            Text(
              'Pending Invitations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...pendingInvitations.map((invite) => _InvitationCard(
                  invitation: invite,
                  onAccept: () => onAcceptInvitation(invite.id),
                  onDecline: () => onDeclineInvitation(invite.id),
                )),
            const SizedBox(height: 32),
          ],

          // No family account info
          const Icon(Icons.family_restroom, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No Family Account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to a Family or Premium plan to share your subscription with up to 6-8 family members.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          const _FamilyBenefitsCard(),
        ],
      ),
    );
  }
}

/// Main family account view
class _FamilyAccountView extends StatelessWidget {
  final FamilyAccount account;
  final VoidCallback onInviteMember;
  final ValueChanged<String> onRemoveMember;
  final void Function(String userId, FamilyRole role) onChangeRole;

  const _FamilyAccountView({
    required this.account,
    required this.onInviteMember,
    required this.onRemoveMember,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Family header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primaryLight.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.family_restroom,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  account.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${account.memberCount} of ${account.maxMembers} members',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                // Member slots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(account.maxMembers, (index) {
                    final isFilled = index < account.memberCount;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? AppColors.primary
                            : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFilled
                              ? AppColors.primary
                              : AppColors.textHint.withValues(alpha: 0.3),
                        ),
                      ),
                      child: isFilled
                          ? const Icon(Icons.person, size: 14, color: Colors.white)
                          : null,
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Members list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (!account.isFull)
                TextButton.icon(
                  onPressed: onInviteMember,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invite'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          ...account.members.map((member) => _MemberCard(
                member: member,
                isOwner: member.role == FamilyRole.owner,
                canManage: account.owner?.userId != member.userId,
                onRemove: () => onRemoveMember(member.userId),
                onChangeRole: (role) => onChangeRole(member.userId, role),
              )),

          if (account.isFull) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Family account is full. Upgrade to Premium for up to 8 members.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Individual member card
class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final bool isOwner;
  final bool canManage;
  final VoidCallback onRemove;
  final ValueChanged<FamilyRole> onChangeRole;

  const _MemberCard({
    required this.member,
    required this.isOwner,
    required this.canManage,
    required this.onRemove,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwner ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isOwner ? AppColors.primary : AppColors.surface,
            backgroundImage:
                member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child: member.photoUrl == null
                ? Icon(
                    Icons.person,
                    color: isOwner ? Colors.white : AppColors.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  member.role.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOwner
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'admin',
                  child: Text('Make Admin'),
                ),
                const PopupMenuItem(
                  value: 'member',
                  child: Text('Set as Member'),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove', style: TextStyle(color: AppColors.error)),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove();
                } else if (value == 'admin') {
                  onChangeRole(FamilyRole.admin);
                } else if (value == 'member') {
                  onChangeRole(FamilyRole.member);
                }
              },
            ),
        ],
      ),
    );
  }
}

/// Invitation card
class _InvitationCard extends StatelessWidget {
  final FamilyInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join ${invitation.familyName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Invited by ${invitation.invitedByName} as ${invitation.assignedRole.displayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDecline,
                child: const Text('Decline'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Family benefits preview card
class _FamilyBenefitsCard extends StatelessWidget {
  const _FamilyBenefitsCard();

  @override
  Widget build(BuildContext context) {
    final benefits = [
      ('👨‍👩‍👧‍👦', 'Share with up to 6 members'),
      ('📱', 'Family dashboard'),
      ('🗺️', 'Share routes & favorites'),
      ('🔒', 'Child safety features'),
      ('📊', 'Per-member statistics'),
      ('💰', 'Save vs individual plans'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Family Plan?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(b.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(b.$2),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
