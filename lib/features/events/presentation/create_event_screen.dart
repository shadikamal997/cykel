/// CYKEL — Create Event Screen
/// Create a new group ride event

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/email_verification_banner.dart';
import '../../discover/data/places_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/events_provider.dart';
import '../domain/event.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _paceController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  // Phase 3: Age restriction
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  EventType _selectedType = EventType.social;
  EventDifficulty _selectedDifficulty = EventDifficulty.moderate;
  EventVisibility _selectedVisibility = EventVisibility.public;
  bool _isNoDrop = false;
  bool _requiresLights = false;

  LatLng? _selectedLocation;
  bool _isLoading = false;
  
  // Image upload
  File? _selectedImage;
  final _imagePicker = ImagePicker();
  
  // Address autocomplete
  Timer? _debounce;
  List<PlaceResult> _addressSuggestions = [];
  bool _showSuggestions = false;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _locationNameController.dispose();
    _instructionsController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _paceController.dispose();
    _maxParticipantsController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.createGroupRide),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _buildSectionHeader(context.l10n.basicInfo),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.l10n.eventTitle,
                hintText: context.l10n.eventTitleHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? context.l10n.titleRequired : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: context.l10n.eventDescriptionLabel,
                hintText: context.l10n.eventDescriptionHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Event Image
            _buildImagePicker(),
            const SizedBox(height: 16),

            // Type & Difficulty
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: context.l10n.eventType,
                    value: _selectedType,
                    items: EventType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text('${t.icon} ${t.localizedLabel(context)}'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField(
                    label: context.l10n.difficultyLevel,
                    value: _selectedDifficulty,
                    items: EventDifficulty.values.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('${d.icon} ${d.localizedLabel(context)}'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedDifficulty = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date & Time Section
            _buildSectionHeader(context.l10n.dateAndTimeSection),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePicker(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionHeader(context.l10n.meetingPointSection),
            const SizedBox(height: 12),

            TextFormField(
              controller: _locationNameController,
              decoration: InputDecoration(
                labelText: context.l10n.placeName,
                hintText: context.l10n.placeNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            CompositedTransformTarget(
              link: _layerLink,
              child: TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: context.l10n.address,
                  hintText: context.l10n.addressHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: _showSuggestions
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _addressController.clear();
                            _removeOverlay();
                            setState(() {
                              _addressSuggestions = [];
                              _showSuggestions = false;
                              _selectedLocation = null;
                            });
                          },
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: _onAddressChanged,
                onTap: () {
                  if (_addressSuggestions.isNotEmpty) {
                    _showOverlay();
                  }
                },
                validator: (v) => v?.isEmpty == true ? context.l10n.addressRequired : null,
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedLocation != null)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.hardEdge,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('meeting'),
                      position: _selectedLocation!,
                    ),
                  },
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                ),
              ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _instructionsController,
              decoration: InputDecoration(
                labelText: context.l10n.eventInstructions,
                hintText: context.l10n.eventInstructionsHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Route Details Section
            _buildSectionHeader(context.l10n.rideDetailsSection),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _distanceController,
                    decoration: InputDecoration(
                      labelText: context.l10n.distanceKm,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: context.l10n.durationMin,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _paceController,
                    decoration: InputDecoration(
                      labelText: context.l10n.paceKmh,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxParticipantsController,
                    decoration: InputDecoration(
                      labelText: context.l10n.maxParticipants,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Settings Section
            _buildSectionHeader(context.l10n.settingsSection),
            const SizedBox(height: 12),

            _buildDropdownField(
              label: context.l10n.visibility,
              value: _selectedVisibility,
              items: EventVisibility.values.map((v) => DropdownMenuItem(
                value: v,
                child: Text(v.localizedLabel(context)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedVisibility = v!),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              value: _isNoDrop,
              onChanged: (v) => setState(() => _isNoDrop = v),
              title: Text(context.l10n.noDropPolicy),
              subtitle: Text(context.l10n.noDropDescription),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              value: _requiresLights,
              onChanged: (v) => setState(() => _requiresLights = v),
              title: Text(context.l10n.lightsRequiredToggle),
              subtitle: Text(context.l10n.lightsRequiredDescription),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
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
                  : Text(context.l10n.createEventButton),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.headline3,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.l10n.dateLabel,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.l10n.timeLabel,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (value.length < 3) {
      _removeOverlay();
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAddressSuggestions(value);
    });
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    try {
      final placesService = PlacesService();
      final locale = Localizations.localeOf(context).toString();
      final suggestions = await placesService.autocomplete(
        input,
        language: locale.split('_')[0], // 'en' or 'da'
      );
      
      setState(() {
        _addressSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
      
      if (suggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _addressSuggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _addressSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 20),
                    title: Text(
                      suggestion.text,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: suggestion.subtitle.isNotEmpty
                        ? Text(
                            suggestion.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          )
                        : null,
                    onTap: () => _selectAddress(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _selectAddress(PlaceResult place) async {
    _removeOverlay();
    
    try {
      // PlaceResult always includes coordinates - no need for second API call
      setState(() {
        _selectedLocation = LatLng(place.lat, place.lng);
        _addressController.text = place.text;
        _addressSuggestions = [];
        _showSuggestions = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.couldNotFindAddress}: $e')),
        );
      }
    }
  }

  Future<void> _createEvent() async {
    // Check email verification first
    try {
      await checkEmailVerification(context, ref);
    } catch (e) {
      // User's email is not verified, dialog already shown
      return;
    }

    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.searchAddressFirst)),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mustBeLoggedIn)),
      );
      return;
    }
    
    // Validate that the event date/time is not in the past
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    if (dateTime.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.eventDateTimePast)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image first if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }

      final event = RideEvent(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        organizerId: user.uid,
        organizerName: user.displayName,
        organizerPhotoUrl: user.photoUrl,
        dateTime: dateTime,
        meetingPoint: MeetingPoint(
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          address: _addressController.text.trim(),
          name: _locationNameController.text.trim().isEmpty
              ? null
              : _locationNameController.text.trim(),
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
        ),
        eventType: _selectedType,
        difficulty: _selectedDifficulty,
        visibility: _selectedVisibility,
        status: EventStatus.upcoming,
        distanceKm: double.tryParse(_distanceController.text),
        durationMinutes: int.tryParse(_durationController.text),
        paceKmh: double.tryParse(_paceController.text),
        maxParticipants: int.tryParse(_maxParticipantsController.text),
        minAge: int.tryParse(_minAgeController.text),
        maxAge: int.tryParse(_maxAgeController.text),
        isNoDrop: _isNoDrop,
        requiresLights: _requiresLights,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final eventId = await ref.read(eventsServiceProvider).createEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.groupRideCreated)),
        );
        context.go('/events/$eventId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── Image Upload ─────────────────────────────────────────────────────────

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Image',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add event image',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return null;

      final fileName = 'events/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      await storageRef.putFile(_selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    }
  }
}
