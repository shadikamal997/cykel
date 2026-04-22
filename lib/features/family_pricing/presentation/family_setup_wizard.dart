import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_member_extended.dart';

/// State for the family setup wizard
class FamilySetupState {
  final int currentStep;
  final String familyName;
  final int totalMembers;
  final EmergencyContact? emergencyContact;
  final FamilyAddress? homeAddress;
  final List<ExtendedFamilyMember> members;
  final bool isLoading;
  final String? error;

  const FamilySetupState({
    this.currentStep = 0,
    this.familyName = '',
    this.totalMembers = 2,
    this.emergencyContact,
    this.homeAddress,
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  FamilySetupState copyWith({
    int? currentStep,
    String? familyName,
    int? totalMembers,
    EmergencyContact? emergencyContact,
    FamilyAddress? homeAddress,
    List<ExtendedFamilyMember>? members,
    bool? isLoading,
    String? error,
  }) {
    return FamilySetupState(
      currentStep: currentStep ?? this.currentStep,
      familyName: familyName ?? this.familyName,
      totalMembers: totalMembers ?? this.totalMembers,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      homeAddress: homeAddress ?? this.homeAddress,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for family setup state
final familySetupProvider =
    StateNotifierProvider.autoDispose<FamilySetupNotifier, FamilySetupState>(
        (ref) => FamilySetupNotifier());

class FamilySetupNotifier extends StateNotifier<FamilySetupState> {
  FamilySetupNotifier() : super(const FamilySetupState());

  void setFamilyName(String name) {
    state = state.copyWith(familyName: name);
  }

  void setTotalMembers(int count) {
    state = state.copyWith(totalMembers: count);
  }

  void setEmergencyContact(EmergencyContact contact) {
    state = state.copyWith(emergencyContact: contact);
  }

  void setHomeAddress(FamilyAddress address) {
    state = state.copyWith(homeAddress: address);
  }

  void addMember(ExtendedFamilyMember member) {
    state = state.copyWith(members: [...state.members, member]);
  }

  void updateMember(int index, ExtendedFamilyMember member) {
    final members = [...state.members];
    members[index] = member;
    state = state.copyWith(members: members);
  }

  void removeMember(int index) {
    final members = [...state.members];
    members.removeAt(index);
    state = state.copyWith(members: members);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const FamilySetupState();
  }
}

/// Family setup wizard screen
class FamilySetupWizard extends ConsumerStatefulWidget {
  const FamilySetupWizard({super.key});

  @override
  ConsumerState<FamilySetupWizard> createState() => _FamilySetupWizardState();
}

class _FamilySetupWizardState extends ConsumerState<FamilySetupWizard> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(familySetupProvider.notifier).goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familySetupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Family'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _StepIndicator(
            currentStep: state.currentStep,
            totalSteps: 4,
            onStepTap: _goToStep,
          ),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _FamilyInfoStep(onNext: () => _goToStep(1)),
                _AddMembersStep(
                  onNext: () => _goToStep(2),
                  onBack: () => _goToStep(0),
                ),
                _EmergencyContactStep(
                  onNext: () => _goToStep(3),
                  onBack: () => _goToStep(1),
                ),
                _ReviewStep(
                  onBack: () => _goToStep(2),
                  onComplete: () => _completeSetup(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSetup() async {
    final notifier = ref.read(familySetupProvider.notifier);
    final state = ref.read(familySetupProvider);
    notifier.setLoading(true);

    try {
      final service = ref.read(familyPricingServiceProvider);
      
      // Convert members to the format expected by the service
      final membersData = state.members.map((m) => {
        'id': m.id,
        'userId': m.userId,
        'firstName': m.firstName,
        'lastName': m.lastName,
        'dateOfBirth': Timestamp.fromDate(m.dateOfBirth),
        'relationship': m.relationship.name,
        'email': m.email,
        'phone': m.phone,
        'photoUrl': m.photoUrl,
        'memberType': m.memberType.name,
        'permissions': m.permissions.toMap(),
        'childSafetySettings': m.childSafetySettings?.toMap(),
        'createdAt': Timestamp.fromDate(m.createdAt),
        'isActive': m.isActive,
      }).toList();

      // Create the family account
      await service.createExtendedFamilyAccount(
        name: state.familyName,
        members: membersData,
        emergencyContact: state.emergencyContact?.toMap(),
        homeAddress: state.homeAddress?.toMap(),
      );
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family created successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      notifier.setError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      notifier.setLoading(false);
      notifier.reset();
    }
  }
}

/// Step progress indicator
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Function(int) onStepTap;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['Family Info', 'Members', 'Emergency', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isLast = index == totalSteps - 1;

          return Expanded(
            child: Row(
              children: [
                // Step circle
                GestureDetector(
                  onTap: isCompleted ? () => onStepTap(index) : null,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppColors.primary
                              : AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted || isCurrent
                                ? AppColors.primary
                                : AppColors.textHint.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.white
                                        : AppColors.textHint,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.textHint.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Step 1: Family Information
class _FamilyInfoStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const _FamilyInfoStep({required this.onNext});

  @override
  ConsumerState<_FamilyInfoStep> createState() => _FamilyInfoStepState();
}

class _FamilyInfoStepState extends ConsumerState<_FamilyInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedMembers = 2;

  @override
  void initState() {
    super.initState();
    final state = ref.read(familySetupProvider);
    _nameController.text = state.familyName;
    _selectedMembers = state.totalMembers;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(Icons.family_restroom, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Let\'s set up your family',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a family account to track rides together and keep everyone connected.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // Family name field
            Text(
              'Family Name',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., The Johansen Family',
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a family name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Number of members
            Text(
              'How many family members?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Including yourself',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Member count selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _selectedMembers > 2
                        ? () => setState(() => _selectedMembers--)
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _selectedMembers > 2
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      Text(
                        '$_selectedMembers',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                      Text(
                        'members',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: _selectedMembers < 8
                        ? () => setState(() => _selectedMembers++)
                        : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _selectedMembers < 8
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                    iconSize: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum 8 members per family',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 32),

            // Next button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final notifier = ref.read(familySetupProvider.notifier);
                  notifier.setFamilyName(_nameController.text.trim());
                  notifier.setTotalMembers(_selectedMembers);
                  widget.onNext();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2: Add Members
class _AddMembersStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _AddMembersStep({required this.onNext, required this.onBack});

  @override
  ConsumerState<_AddMembersStep> createState() => _AddMembersStepState();
}

class _AddMembersStepState extends ConsumerState<_AddMembersStep> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familySetupProvider);
    final membersNeeded = state.totalMembers - 1; // Minus the owner
    final membersAdded = state.members.length;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Family Members',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '$membersAdded / $membersNeeded',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: membersNeeded > 0 ? membersAdded / membersNeeded : 0,
                backgroundColor: context.colors.surface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                'You\'ve added $membersAdded of $membersNeeded members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),

        // Members list
        Expanded(
          child: state.members.isEmpty
              ? _EmptyMembersView(onAddMember: () => _showAddMemberSheet())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.members.length + 1, // +1 for add button
                  itemBuilder: (context, index) {
                    if (index == state.members.length) {
                      // Add more button
                      if (membersAdded < membersNeeded) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddMemberSheet(),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Another Member'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final member = state.members[index];
                    return _MemberCard(
                      member: member,
                      onEdit: () => _showAddMemberSheet(
                        existingMember: member,
                        memberIndex: index,
                      ),
                      onRemove: () {
                        ref.read(familySetupProvider.notifier).removeMember(index);
                      },
                    );
                  },
                ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: membersAdded >= 1 ? widget.onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddMemberSheet({
    ExtendedFamilyMember? existingMember,
    int? memberIndex,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMemberSheet(
        existingMember: existingMember,
        onSave: (member) {
          final notifier = ref.read(familySetupProvider.notifier);
          if (memberIndex != null) {
            notifier.updateMember(memberIndex, member);
          } else {
            notifier.addMember(member);
          }
        },
      ),
    );
  }
}

/// Empty state for members list
class _EmptyMembersView extends StatelessWidget {
  final VoidCallback onAddMember;

  const _EmptyMembersView({required this.onAddMember});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No members added yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your family members to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddMember,
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Member card in the list
class _MemberCard extends StatelessWidget {
  final ExtendedFamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          AppAvatar(
            url: null,
            size: 48,
            fallbackText: member.relationship.icon,
          ),
          const SizedBox(width: 14),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _InfoChip(
                      label: member.relationship.displayName,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _InfoChip(
                      label: '${member.age} years',
                      color: member.isChild
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    if (member.isChild) ...[
                      const SizedBox(width: 6),
                      _InfoChip(
                        label: member.isManagedChild ? 'Managed' : 'Teen',
                        color: AppColors.info,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: context.colors.textSecondary,
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

/// Small info chip
class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Add/Edit member bottom sheet
class _AddMemberSheet extends StatefulWidget {
  final ExtendedFamilyMember? existingMember;
  final Function(ExtendedFamilyMember) onSave;

  const _AddMemberSheet({
    this.existingMember,
    required this.onSave,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 10));
  FamilyRelationship _relationship = FamilyRelationship.spouse;
  bool _hasAppAccount = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingMember != null) {
      _firstNameController.text = widget.existingMember!.firstName;
      _lastNameController.text = widget.existingMember!.lastName ?? '';
      _emailController.text = widget.existingMember!.email ?? '';
      _phoneController.text = widget.existingMember!.phone ?? '';
      _dateOfBirth = widget.existingMember!.dateOfBirth;
      _relationship = widget.existingMember!.relationship;
      _hasAppAccount = widget.existingMember!.memberType != MemberType.managed;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _age {
    final now = DateTime.now();
    int age = now.year - _dateOfBirth.year;
    if (now.month < _dateOfBirth.month ||
        (now.month == _dateOfBirth.month && now.day < _dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get _isChild => _age < 18;
  bool get _requiresManaged => _age < 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.existingMember != null
                    ? 'Edit Member'
                    : 'Add Family Member',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // First Name
              _buildLabel('First Name *'),
              TextFormField(
                controller: _firstNameController,
                decoration: _inputDecoration('Enter first name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Last Name
              _buildLabel('Last Name'),
              TextFormField(
                controller: _lastNameController,
                decoration: _inputDecoration('Enter last name (optional)'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Date of Birth
              _buildLabel('Date of Birth *'),
              InkWell(
                onTap: () => _selectDate(),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration('Select date'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Row(
                        children: [
                          _InfoChip(
                            label: '$_age years old',
                            color: _isChild
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today,
                              size: 20, color: context.colors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_isChild) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _requiresManaged
                              ? 'Children under 10 are managed through your account'
                              : 'Teens (10-17) can have their own login with parental controls',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Relationship
              _buildLabel('Relationship *'),
              DropdownButtonFormField<FamilyRelationship>(
                initialValue: _relationship,
                decoration: _inputDecoration('Select relationship'),
                items: FamilyRelationship.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Row(
                            children: [
                              Text(r.icon),
                              const SizedBox(width: 8),
                              Text(r.displayName),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _relationship = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Has CYKEL app account (only for 10+)
              if (_age >= 10) ...[
                _buildLabel('Does this person have a CYKEL account?'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SelectionButton(
                        label: 'Yes, send invite',
                        icon: Icons.email_outlined,
                        isSelected: _hasAppAccount,
                        onTap: () => setState(() => _hasAppAccount = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SelectionButton(
                        label: 'No, I\'ll track them',
                        icon: Icons.phone_android_outlined,
                        isSelected: !_hasAppAccount,
                        onTap: () => setState(() => _hasAppAccount = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Email (required if has app account and age >= 10)
              if (_hasAppAccount && _age >= 10) ...[
                _buildLabel('Email Address *'),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('member@example.com'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (_hasAppAccount && _age >= 10) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email required to send invitation';
                      }
                      if (!v.contains('@')) {
                        return 'Enter a valid email';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Phone (optional)
              _buildLabel('Phone Number'),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('+45 12 34 56 78 (optional)'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                ],
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _saveMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                    widget.existingMember != null ? 'Update Member' : 'Add Member'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _saveMember() {
    if (!_formKey.currentState!.validate()) return;

    // Determine member type
    MemberType memberType;
    if (_age < 10) {
      memberType = MemberType.managed;
    } else if (_hasAppAccount) {
      memberType = MemberType.pending;
    } else {
      memberType = MemberType.managed;
    }

    // Determine permissions based on age
    MemberPermissions permissions;
    if (_age >= 18) {
      permissions = MemberPermissions.adult();
    } else if (_age >= 10) {
      permissions = MemberPermissions.teen();
    } else {
      permissions = MemberPermissions.child();
    }

    // Child safety settings for minors
    ChildSafetySettings? childSafety;
    if (_age < 18) {
      childSafety = const ChildSafetySettings();
    }

    final member = ExtendedFamilyMember(
      id: widget.existingMember?.id ?? const Uuid().v4(),
      userId: null, // Will be set when they accept invitation
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      relationship: _relationship,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      memberType: memberType,
      permissions: permissions,
      childSafetySettings: childSafety,
      createdAt: widget.existingMember?.createdAt ?? DateTime.now(),
    );

    widget.onSave(member);
    Navigator.pop(context);
  }
}

/// Selection button for yes/no choices
class _SelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 3: Emergency Contact
class _EmergencyContactStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _EmergencyContactStep({required this.onNext, required this.onBack});

  @override
  ConsumerState<_EmergencyContactStep> createState() =>
      _EmergencyContactStepState();
}

class _EmergencyContactStepState extends ConsumerState<_EmergencyContactStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final contact = ref.read(familySetupProvider).emergencyContact;
    if (contact != null) {
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
      _emailController.text = contact.email ?? '';
      _relationController.text = contact.relationship ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(Icons.emergency, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Emergency Contact',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an emergency contact for your family. This person will be notified in case of emergencies.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // Name
            _buildLabel('Contact Name *'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Full name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            _buildLabel('Phone Number *'),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration('+45 12 34 56 78'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
              ],
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Email
            _buildLabel('Email (optional)'),
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration('email@example.com'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Relationship
            _buildLabel('Relationship (optional)'),
            TextFormField(
              controller: _relationController,
              decoration: _inputDecoration('e.g., Neighbor, Doctor, Friend'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),

            // Skip option
            TextButton(
              onPressed: widget.onNext,
              child: const Text('Skip for now'),
            ),
            const SizedBox(height: 16),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final contact = EmergencyContact(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          email: _emailController.text.trim().isEmpty
                              ? null
                              : _emailController.text.trim(),
                          relationship: _relationController.text.trim().isEmpty
                              ? null
                              : _relationController.text.trim(),
                        );
                        ref
                            .read(familySetupProvider.notifier)
                            .setEmergencyContact(contact);
                        widget.onNext();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// Step 4: Review
class _ReviewStep extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const _ReviewStep({required this.onBack, required this.onComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familySetupProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(Icons.fact_check_outlined,
                    size: 64, color: AppColors.success),
                const SizedBox(height: 16),
                Text(
                  'Review Your Family',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Make sure everything looks correct before creating your family account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),

                // Family info card
                _ReviewCard(
                  title: 'Family Information',
                  icon: Icons.family_restroom,
                  children: [
                    _ReviewRow(label: 'Name', value: state.familyName),
                    _ReviewRow(
                        label: 'Members',
                        value: '${state.members.length + 1} people'),
                  ],
                ),
                const SizedBox(height: 16),

                // Members card
                _ReviewCard(
                  title: 'Family Members',
                  icon: Icons.people,
                  children: [
                    const _ReviewRow(label: 'You', value: 'Admin'),
                    ...state.members.map((m) => _ReviewRow(
                          label: m.displayName,
                          value:
                              '${m.relationship.displayName} • ${m.age} years',
                          subtitle: m.memberType == MemberType.pending
                              ? 'Invite will be sent'
                              : m.memberType == MemberType.managed
                                  ? 'Managed account'
                                  : null,
                        )),
                  ],
                ),
                const SizedBox(height: 16),

                // Emergency contact card
                if (state.emergencyContact != null)
                  _ReviewCard(
                    title: 'Emergency Contact',
                    icon: Icons.emergency,
                    children: [
                      _ReviewRow(
                          label: 'Name', value: state.emergencyContact!.name),
                      _ReviewRow(
                          label: 'Phone', value: state.emergencyContact!.phone),
                      if (state.emergencyContact!.email != null)
                        _ReviewRow(
                            label: 'Email',
                            value: state.emergencyContact!.email!),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Family'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Review card container
class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

/// Review row
class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
