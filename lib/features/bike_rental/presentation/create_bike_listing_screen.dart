/// CYKEL — Create/Edit Bike Listing Screen
/// Form to create or edit a bike listing

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/bike_listing.dart';
import '../application/bike_rental_providers.dart';

class CreateBikeListingScreen extends ConsumerStatefulWidget {
  const CreateBikeListingScreen({
    super.key,
    this.listing,
  });

  final BikeListing? listing;
  bool get isEditing => listing != null;

  @override
  ConsumerState<CreateBikeListingScreen> createState() =>
      _CreateBikeListingScreenState();
}

class _CreateBikeListingScreenState
    extends ConsumerState<CreateBikeListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _weeklyRateController = TextEditingController();
  final _depositController = TextEditingController();
  final _minimumHoursController = TextEditingController(text: '1');
  final _maximumDaysController = TextEditingController();
  final _pickupInstructionsController = TextEditingController();
  final _rulesController = TextEditingController();
  final _locationNameController = TextEditingController();

  BikeType _bikeType = BikeType.city;
  BikeSize _size = BikeSize.m;
  BikeCondition _condition = BikeCondition.good;
  
  // Features
  bool _hasLights = false;
  bool _hasLock = false;
  bool _hasBasket = false;
  bool _hasRack = false;
  bool _hasHelmet = false;
  bool _hasBell = false;
  bool _hasGears = false;
  int? _gearCount;
  bool _hasChildSeat = false;
  bool _hasKickstand = false;

  // Location
  LatLng? _location;
  DateTime? _availableFrom;
  DateTime? _availableTo;

  List<String> _photoUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill form if editing
    if (widget.isEditing) {
      final listing = widget.listing!;
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;
      _brandController.text = listing.brand ?? '';
      _modelController.text = listing.model ?? '';
      _colorController.text = listing.color ?? '';
      _yearController.text = listing.year?.toString() ?? '';
      _hourlyRateController.text = listing.pricing.hourlyRate.toString();
      _dailyRateController.text = listing.pricing.dailyRate.toString();
      _weeklyRateController.text = listing.pricing.weeklyRate?.toString() ?? '';
      _depositController.text = listing.pricing.depositAmount.toString();
      _minimumHoursController.text = listing.minimumRentalHours.toString();
      _maximumDaysController.text = listing.maximumRentalDays?.toString() ?? '';
      _pickupInstructionsController.text = listing.pickupInstructions ?? '';
      _rulesController.text = listing.rules ?? '';
      _locationNameController.text = listing.locationName;

      _bikeType = listing.bikeType;
      _size = listing.size;
      _condition = listing.condition;
      
      _hasLights = listing.features.hasLights;
      _hasLock = listing.features.hasLock;
      _hasBasket = listing.features.hasBasket;
      _hasRack = listing.features.hasRack;
      _hasHelmet = listing.features.hasHelmet;
      _hasBell = listing.features.hasBell;
      _hasGears = listing.features.hasGears;
      _gearCount = listing.features.gearCount;
      _hasChildSeat = listing.features.hasChildSeat;
      _hasKickstand = listing.features.hasKickstand;

      _location = listing.location;
      _availableFrom = listing.availableFrom;
      _availableTo = listing.availableTo;
      _photoUrls = List.from(listing.photoUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _weeklyRateController.dispose();
    _depositController.dispose();
    _minimumHoursController.dispose();
    _maximumDaysController.dispose();
    _pickupInstructionsController.dispose();
    _rulesController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Upload images to Firebase Storage and get URLs
      // For now, just use local paths (will need Firebase Storage implementation)
      final List<String> urls = images.map((img) => img.path).toList();

      setState(() {
        _photoUrls.addAll(urls);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos added (upload to storage pending)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
    });
  }

  Future<void> _selectLocation() async {
    // TODO: Implement location picker (Google Maps picker screen)
    // For now, use a default location (Copenhagen)
    setState(() {
      _location = const LatLng(55.6761, 12.5683);
      _locationNameController.text = 'Copenhagen, Denmark';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location set to Copenhagen (picker pending)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _selectAvailableFrom() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _availableFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _availableFrom = picked;
      });
    }
  }

  Future<void> _selectAvailableTo() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _availableTo ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _availableFrom ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _availableTo = picked;
      });
    }
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(bikeRentalServiceProvider);

      final pricing = BikePricing(
        hourlyRate: double.parse(_hourlyRateController.text),
        dailyRate: double.parse(_dailyRateController.text),
        weeklyRate: _weeklyRateController.text.isNotEmpty
            ? double.parse(_weeklyRateController.text)
            : null,
        depositAmount: double.parse(_depositController.text),
      );

      final features = BikeFeatures(
        hasLights: _hasLights,
        hasLock: _hasLock,
        hasBasket: _hasBasket,
        hasRack: _hasRack,
        hasHelmet: _hasHelmet,
        hasBell: _hasBell,
        hasGears: _hasGears,
        gearCount: _gearCount,
        hasChildSeat: _hasChildSeat,
        hasKickstand: _hasKickstand,
      );

      if (widget.isEditing) {
        // Update existing listing
        final updatedListing = widget.listing!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          bikeType: _bikeType,
          size: _size,
          condition: _condition,
          pricing: pricing,
          features: features,
          location: _location,
          locationName: _locationNameController.text,
          photoUrls: _photoUrls,
          brand: _brandController.text.isNotEmpty ? _brandController.text : null,
          model: _modelController.text.isNotEmpty ? _modelController.text : null,
          year: _yearController.text.isNotEmpty
              ? int.parse(_yearController.text)
              : null,
          color: _colorController.text.isNotEmpty ? _colorController.text : null,
          availableFrom: _availableFrom,
          availableTo: _availableTo,
          minimumRentalHours: int.parse(_minimumHoursController.text),
          maximumRentalDays: _maximumDaysController.text.isNotEmpty
              ? int.parse(_maximumDaysController.text)
              : null,
          pickupInstructions: _pickupInstructionsController.text.isNotEmpty
              ? _pickupInstructionsController.text
              : null,
          rules: _rulesController.text.isNotEmpty ? _rulesController.text : null,
        );
        await service.updateListing(updatedListing);
      } else {
        // Create new listing
        await service.createListing(
          title: _titleController.text,
          description: _descriptionController.text,
          bikeType: _bikeType,
          size: _size,
          condition: _condition,
          pricing: pricing,
          features: features,
          location: _location!,
          locationName: _locationNameController.text,
          photoUrls: _photoUrls,
          brand: _brandController.text.isNotEmpty ? _brandController.text : null,
          model: _modelController.text.isNotEmpty ? _modelController.text : null,
          year: _yearController.text.isNotEmpty
              ? int.parse(_yearController.text)
              : null,
          color: _colorController.text.isNotEmpty ? _colorController.text : null,
          availableFrom: _availableFrom,
          availableTo: _availableTo,
          minimumRentalHours: int.parse(_minimumHoursController.text),
          maximumRentalDays: _maximumDaysController.text.isNotEmpty
              ? int.parse(_maximumDaysController.text)
              : null,
          pickupInstructions: _pickupInstructionsController.text.isNotEmpty
              ? _pickupInstructionsController.text
              : null,
          rules: _rulesController.text.isNotEmpty ? _rulesController.text : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Listing updated successfully!'
                : 'Listing created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Listing' : 'Create Listing'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveListing,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos section
            _buildPhotosSection(),
            const SizedBox(height: 24),

            // Basic info
            _buildSection(
              title: 'Basic Information',
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Blue City Bike with Basket',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe your bike...',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BikeType>(
                  initialValue: _bikeType,
                  decoration: const InputDecoration(labelText: 'Bike Type *'),
                  items: BikeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.icon} ${type.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _bikeType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BikeSize>(
                        initialValue: _size,
                        decoration: const InputDecoration(labelText: 'Size *'),
                        items: BikeSize.values.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(size.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _size = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<BikeCondition>(
                        initialValue: _condition,
                        decoration: const InputDecoration(labelText: 'Condition *'),
                        items: BikeCondition.values.map((condition) {
                          return DropdownMenuItem(
                            value: condition,
                            child: Text(condition.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _condition = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Optional details
            _buildSection(
              title: 'Details (Optional)',
              children: [
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(labelText: 'Year'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(labelText: 'Color'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pricing
            _buildSection(
              title: 'Pricing',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate (DKK) *',
                          prefixText: 'DKK ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _dailyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Daily Rate (DKK) *',
                          prefixText: 'DKK ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weeklyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Weekly Rate (DKK)',
                          prefixText: 'DKK ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _depositController,
                        decoration: const InputDecoration(
                          labelText: 'Deposit (DKK) *',
                          prefixText: 'DKK ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Features
            _buildSection(
              title: 'Features',
              children: [
                _buildFeatureCheckbox('Lights', _hasLights, (value) {
                  setState(() => _hasLights = value);
                }),
                _buildFeatureCheckbox('Lock', _hasLock, (value) {
                  setState(() => _hasLock = value);
                }),
                _buildFeatureCheckbox('Basket', _hasBasket, (value) {
                  setState(() => _hasBasket = value);
                }),
                _buildFeatureCheckbox('Rack', _hasRack, (value) {
                  setState(() => _hasRack = value);
                }),
                _buildFeatureCheckbox('Helmet included', _hasHelmet, (value) {
                  setState(() => _hasHelmet = value);
                }),
                _buildFeatureCheckbox('Bell', _hasBell, (value) {
                  setState(() => _hasBell = value);
                }),
                _buildFeatureCheckbox('Gears', _hasGears, (value) {
                  setState(() {
                    _hasGears = value;
                    if (!value) _gearCount = null;
                  });
                }),
                if (_hasGears)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 8),
                    child: TextFormField(
                      initialValue: _gearCount?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Number of gears',
                        hintText: 'e.g., 7',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _gearCount = int.tryParse(value);
                      },
                    ),
                  ),
                _buildFeatureCheckbox('Child seat', _hasChildSeat, (value) {
                  setState(() => _hasChildSeat = value);
                }),
                _buildFeatureCheckbox('Kickstand', _hasKickstand, (value) {
                  setState(() => _hasKickstand = value);
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Location
            _buildSection(
              title: 'Location',
              children: [
                TextFormField(
                  controller: _locationNameController,
                  decoration: const InputDecoration(labelText: 'Location Name *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectLocation,
                  icon: const Icon(Icons.map),
                  label: Text(_location == null
                      ? 'Select Pickup Location *'
                      : 'Change Location'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Availability
            _buildSection(
              title: 'Availability',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minimumHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Rental (hours) *',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maximumDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Maximum Rental (days)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available From'),
                  subtitle: Text(_availableFrom != null
                      ? '${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}'
                      : 'No start date (available immediately)'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectAvailableFrom,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available To'),
                  subtitle: Text(_availableTo != null
                      ? '${_availableTo!.day}/${_availableTo!.month}/${_availableTo!.year}'
                      : 'No end date (available indefinitely)'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectAvailableTo,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Additional Info
            _buildSection(
              title: 'Additional Information',
              children: [
                TextFormField(
                  controller: _pickupInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Instructions',
                    hintText: 'e.g., Ring doorbell, bike is in back yard...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rulesController,
                  decoration: const InputDecoration(
                    labelText: 'Rental Rules',
                    hintText: 'e.g., No smoking, return clean...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photoUrls.isEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No photos added yet'),
                  Text('Tap "Add Photos" to upload', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _photoUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 48),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => _removePhoto(index),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFeatureCheckbox(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
