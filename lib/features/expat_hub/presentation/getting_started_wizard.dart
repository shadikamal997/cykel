/// CYKEL — Getting Started Wizard
/// Onboarding wizard for new expats

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GettingStartedWizard extends ConsumerStatefulWidget {
  const GettingStartedWizard({super.key});

  @override
  ConsumerState<GettingStartedWizard> createState() => _GettingStartedWizardState();
}

class _GettingStartedWizardState extends ConsumerState<GettingStartedWizard> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<_WizardStep> _steps = [
    const _WizardStep(
      title: 'Welcome to Copenhagen Cycling!',
      icon: '🚴',
      description:
          'Copenhagen is one of the world\'s most bike-friendly cities. Let\'s help you get started!',
      content: _WelcomeContent(),
    ),
    const _WizardStep(
      title: 'Traffic Rules',
      icon: '🚦',
      description: 'Essential traffic rules every cyclist must know',
      content: _TrafficRulesContent(),
    ),
    const _WizardStep(
      title: 'Hand Signals',
      icon: '✋',
      description: 'Communicate with other cyclists and drivers',
      content: _HandSignalsContent(),
    ),
    const _WizardStep(
      title: 'Safety First',
      icon: '🦺',
      description: 'Tips to stay safe on Copenhagen roads',
      content: _SafetyContent(),
    ),
    const _WizardStep(
      title: 'Bike Lights & Equipment',
      icon: '💡',
      description: 'Required equipment for cycling in Denmark',
      content: _EquipmentContent(),
    ),
    const _WizardStep(
      title: 'You\'re Ready!',
      icon: '🎉',
      description: 'You\'re all set to cycle like a local',
      content: _CompletionContent(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting Started'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of ${_steps.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${((_currentStep + 1) / _steps.length * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          step.icon,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      step.content,
                    ],
                  ),
                );
              },
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                _currentStep == _steps.length - 1 ? 'Finish' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardStep {
  const _WizardStep({
    required this.title,
    required this.icon,
    required this.description,
    required this.content,
  });

  final String title;
  final String icon;
  final String description;
  final Widget content;
}

// ─── Step Contents ─────────────────────────────────────────────────────────

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          context,
          icon: Icons.people,
          title: 'Join 360,000+ Daily Cyclists',
          description: '62% of Copenhagen residents cycle to work or school daily',
        ),
        _buildInfoCard(
          context,
          icon: Icons.route,
          title: '382 km of Bike Lanes',
          description: 'Dedicated, safe cycling infrastructure throughout the city',
        ),
        _buildInfoCard(
          context,
          icon: Icons.speed,
          title: 'Average Speed: 15.5 km/h',
          description: 'Often faster than cars in city center during peak hours',
        ),
      ],
    );
  }
}

class _TrafficRulesContent extends StatelessWidget {
  const _TrafficRulesContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRuleItem(
          '🚦 Follow Traffic Lights',
          'Always stop at red lights. Police strictly enforce this (700 DKK fine).',
        ),
        _buildRuleItem(
          '➡️ Keep Right',
          'Always cycle on the right side unless overtaking.',
        ),
        _buildRuleItem(
          '🛑 Bike Lanes Only',
          'Use designated bike lanes, not sidewalks (1,000 DKK fine).',
        ),
        _buildRuleItem(
          '🎧 No Headphones',
          'Don\'t wear headphones in both ears while cycling.',
        ),
        _buildRuleItem(
          '🍺 No Alcohol',
          'Same alcohol limits as driving (0.05% BAC).',
        ),
      ],
    );
  }
}

class _HandSignalsContent extends StatelessWidget {
  const _HandSignalsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSignalCard(
          title: 'Left Turn',
          description: 'Extend left arm horizontally',
          emoji: '👈',
        ),
        _buildSignalCard(
          title: 'Right Turn',
          description: 'Extend right arm horizontally',
          emoji: '👉',
        ),
        _buildSignalCard(
          title: 'Stopping',
          description: 'Raise left or right hand vertically',
          emoji: '✋',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Signal clearly and in advance. Danish cyclists expect predictable behavior.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyContent extends StatelessWidget {
  const _SafetyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSafetyTip(
          icon: Icons.visibility,
          title: 'Be Visible',
          description: 'Wear bright colors, especially in winter months',
        ),
        _buildSafetyTip(
          icon: Icons.remove_red_eye,
          title: 'Check Blind Spots',
          description: 'Look over your shoulder before turning or changing lanes',
        ),
        _buildSafetyTip(
          icon: Icons.directions_bus,
          title: 'Watch for Buses',
          description: 'Give buses space and be aware of bus stops',
        ),
        _buildSafetyTip(
          icon: Icons.door_front_door,
          title: 'Car Doors',
          description: 'Leave space for car doors opening from parked cars',
        ),
        _buildSafetyTip(
          icon: Icons.ac_unit,
          title: 'Weather Awareness',
          description: 'Reduce speed in rain, snow, or ice. Use winter tires.',
        ),
      ],
    );
  }
}

class _EquipmentContent extends StatelessWidget {
  const _EquipmentContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Required by Law',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Failure to have required equipment can result in fines.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildEquipmentItem(
          emoji: '💡',
          title: 'Front White Light',
          description: 'Required from sunset to sunrise',
          required: true,
        ),
        _buildEquipmentItem(
          emoji: '🔴',
          title: 'Rear Red Light',
          description: 'Required from sunset to sunrise',
          required: true,
        ),
        _buildEquipmentItem(
          emoji: '🔔',
          title: 'Bell',
          description: 'Must be functional and audible',
          required: true,
        ),
        _buildEquipmentItem(
          emoji: '🔧',
          title: 'Working Brakes',
          description: 'Front and rear brakes in good condition',
          required: true,
        ),
        _buildEquipmentItem(
          emoji: '🪞',
          title: 'Reflectors',
          description: 'Yellow on wheels, white front, red rear',
          required: true,
        ),
        const SizedBox(height: 16),
        _buildEquipmentItem(
          emoji: '🎒',
          title: 'Helmet',
          description: 'Highly recommended, especially for children',
          required: false,
        ),
        _buildEquipmentItem(
          emoji: '🔒',
          title: 'Lock',
          description: 'Essential in Copenhagen (high theft rate)',
          required: false,
        ),
      ],
    );
  }
}

class _CompletionContent extends StatelessWidget {
  const _CompletionContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
              const SizedBox(height: 16),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re ready to cycle like a Copenhagener',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Next Steps:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildNextStepCard(
          icon: Icons.store,
          title: 'Find a Bike Shop',
          description: 'Get your bike checked and buy necessary equipment',
        ),
        _buildNextStepCard(
          icon: Icons.route,
          title: 'Explore Routes',
          description: 'Discover beginner-friendly routes around Copenhagen',
        ),
        _buildNextStepCard(
          icon: Icons.people,
          title: 'Join the Community',
          description: 'Connect with other expat cyclists',
        ),
        _buildNextStepCard(
          icon: Icons.menu_book,
          title: 'Read More Guides',
          description: 'Learn about Danish cycling culture and etiquette',
        ),
      ],
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────

Widget _buildInfoCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String description,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildRuleItem(String title, String description) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSignalCard({
  required String title,
  required String description,
  required String emoji,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSafetyTip({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildEquipmentItem({
  required String emoji,
  required String title,
  required String description,
  required bool required,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: required ? Colors.red[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        required ? 'REQUIRED' : 'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: required ? Colors.red[700] : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNextStepCard({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    ),
  );
}
