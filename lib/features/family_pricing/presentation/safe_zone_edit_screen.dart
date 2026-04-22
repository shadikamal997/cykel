import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/location_service.dart';
import '../application/family_location_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_location.dart';

/// Screen for creating or editing a safe zone
class SafeZoneEditScreen extends ConsumerStatefulWidget {
  final SafeZone? existingZone;

  const SafeZoneEditScreen({super.key, this.existingZone});

  @override
  ConsumerState<SafeZoneEditScreen> createState() => _SafeZoneEditScreenState();
}

class _SafeZoneEditScreenState extends ConsumerState<SafeZoneEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  double _radiusMeters = 100;
  bool _alertOnEnter = true;
  bool _alertOnExit = true;
  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditing => widget.existingZone != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingZone != null) {
      final zone = widget.existingZone!;
      _nameController.text = zone.name;
      _selectedLocation = zone.center;
      _radiusMeters = zone.radiusMeters;
      _alertOnEnter = zone.alertOnEnter;
      _alertOnExit = zone.alertOnExit;
      _isActive = zone.isActive;
    } else {
      // Get current location for new zones
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      if (mounted) {
        setState(() => _selectedLocation = location);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 16),
        );
      }
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Safe Zone' : 'Add Safe Zone'),
        centerTitle: true,
        actions: [
          if (isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveZone,
              child: const Text('Save'),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _saveZone,
              child: const Text('Create'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map section
              _buildMapSection(),

              // Form section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone name
                    _buildSectionTitle('Zone Name'),
                    const SizedBox(height: 8),
                    _buildNameField(),
                    const SizedBox(height: 24),

                    // Quick presets
                    _buildSectionTitle('Quick Presets'),
                    const SizedBox(height: 8),
                    _buildPresetChips(),
                    const SizedBox(height: 24),

                    // Radius slider
                    _buildSectionTitle('Radius'),
                    const SizedBox(height: 8),
                    _buildRadiusSlider(),
                    const SizedBox(height: 24),

                    // Alert settings
                    _buildSectionTitle('Alert Settings'),
                    const SizedBox(height: 8),
                    _buildAlertSettings(),
                    const SizedBox(height: 24),

                    // Active toggle
                    _buildActiveToggle(),
                    const SizedBox(height: 32),

                    // Save button
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    final initialPosition = _selectedLocation ?? const LatLng(31.9522, 35.2332);

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_selectedLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
                );
              }
            },
            onTap: (position) {
              setState(() => _selectedLocation = position);
            },
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('zone_center'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                  }
                : {},
            circles: _selectedLocation != null
                ? {
                    Circle(
                      circleId: const CircleId('zone_radius'),
                      center: _selectedLocation!,
                      radius: _radiusMeters,
                      fillColor: AppColors.primary.withValues(alpha: 0.15),
                      strokeColor: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Instructions overlay
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap on the map to set the zone center',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My location button
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: () async {
                final location = await ref
                    .read(locationServiceProvider)
                    .getCurrentLocation();
                setState(() => _selectedLocation = location);
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(location, 16),
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'e.g., Home, School, Work',
        prefixIcon: const Icon(Icons.label_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a name for this zone';
        }
        return null;
      },
    );
  }

  Widget _buildPresetChips() {
    final presets = [
      ('🏠', 'Home'),
      ('🏫', 'School'),
      ('💼', 'Work'),
      ('🏋️', 'Gym'),
      ('🌳', 'Park'),
      ('👫', 'Friend\'s'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        final isSelected = _nameController.text == preset.$2;
        return FilterChip(
          label: Text('${preset.$1} ${preset.$2}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _nameController.text = preset.$2);
            }
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildRadiusSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_radiusMeters.toInt()} meters',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _getRadiusDescription(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: _radiusMeters,
            min: 50,
            max: 500,
            divisions: 9,
            label: '${_radiusMeters.toInt()}m',
            onChanged: (value) {
              setState(() => _radiusMeters = value);
            },
          ),
        ),
        // Quick radius buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [50, 100, 200, 300, 500].map((r) {
            final isSelected = _radiusMeters == r.toDouble();
            return GestureDetector(
              onTap: () => setState(() => _radiusMeters = r.toDouble()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  '${r}m',
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getRadiusDescription() {
    if (_radiusMeters <= 50) return 'Very precise';
    if (_radiusMeters <= 100) return 'Building-level';
    if (_radiusMeters <= 200) return 'Block-level';
    if (_radiusMeters <= 300) return 'Neighborhood';
    return 'Wide area';
  }

  Widget _buildAlertSettings() {
    return Column(
      children: [
        _buildAlertToggle(
          icon: Icons.login,
          title: 'Alert on Enter',
          subtitle: 'Notify when family members arrive',
          value: _alertOnEnter,
          onChanged: (v) => setState(() => _alertOnEnter = v),
        ),
        const SizedBox(height: 8),
        _buildAlertToggle(
          icon: Icons.logout,
          title: 'Alert on Exit',
          subtitle: 'Notify when family members leave',
          value: _alertOnExit,
          onChanged: (v) => setState(() => _alertOnExit = v),
        ),
      ],
    );
  }

  Widget _buildAlertToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isActive
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isActive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle : Icons.pause_circle,
            color: _isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isActive ? 'Zone Active' : 'Zone Paused',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _isActive
                      ? 'You will receive alerts for this zone'
                      : 'Alerts are disabled for this zone',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeTrackColor: Colors.green.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveZone,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isEditing ? 'Save Changes' : 'Create Safe Zone',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _saveZone() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final familyAccount = ref.read(familyAccountProvider).valueOrNull;
      if (familyAccount == null) throw Exception('No family account');

      final zone = SafeZone(
        id: widget.existingZone?.id ?? '',
        familyId: familyAccount.id,
        name: _nameController.text.trim(),
        center: _selectedLocation!,
        radiusMeters: _radiusMeters,
        alertOnEnter: _alertOnEnter,
        alertOnExit: _alertOnExit,
        isActive: _isActive,
      );

      final service = ref.read(familyLocationServiceProvider);

      if (isEditing) {
        await service.updateSafeZone(
          familyAccount.id,
          widget.existingZone!.id,
          zone,
        );
      } else {
        await service.addSafeZone(zone);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Zone "${zone.name}" updated'
                  : 'Zone "${zone.name}" created',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
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
