/// CYKEL — Bike Browser Screen
/// Browse and search available bikes for rent

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/bike_listing.dart';
import '../application/bike_rental_providers.dart';
import 'bike_detail_screen.dart';
import 'create_bike_listing_screen.dart';

enum ViewMode { list, map }

class BikeBrowserScreen extends ConsumerStatefulWidget {
  const BikeBrowserScreen({super.key});

  @override
  ConsumerState<BikeBrowserScreen> createState() => _BikeBrowserScreenState();
}

class _BikeBrowserScreenState extends ConsumerState<BikeBrowserScreen> {
  ViewMode _viewMode = ViewMode.list;

  // Filters
  BikeType? _filterType;
  BikeSize? _filterSize;
  double? _maxHourlyRate;
  double? _maxDailyRate;
  bool _filterHelmet = false;
  bool _filterLock = false;
  DateTime? _availableFrom;
  DateTime? _availableTo;

  // Location (default: Copenhagen)
  final LatLng _currentLocation = const LatLng(55.6761, 12.5683);

  bool get _hasActiveFilters =>
      _filterType != null ||
      _filterSize != null ||
      _maxHourlyRate != null ||
      _maxDailyRate != null ||
      _filterHelmet ||
      _filterLock ||
      _availableFrom != null ||
      _availableTo != null;

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _filterSize = null;
      _maxHourlyRate = null;
      _maxDailyRate = null;
      _filterHelmet = false;
      _filterLock = false;
      _availableFrom = null;
      _availableTo = null;
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterDialog(
        filterType: _filterType,
        filterSize: _filterSize,
        maxHourlyRate: _maxHourlyRate,
        maxDailyRate: _maxDailyRate,
        filterHelmet: _filterHelmet,
        filterLock: _filterLock,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
        onApply: ({
          BikeType? type,
          BikeSize? size,
          double? hourlyRate,
          double? dailyRate,
          bool helmet = false,
          bool lock = false,
          DateTime? from,
          DateTime? to,
        }) {
          setState(() {
            _filterType = type;
            _filterSize = size;
            _maxHourlyRate = hourlyRate;
            _maxDailyRate = dailyRate;
            _filterHelmet = helmet;
            _filterLock = lock;
            _availableFrom = from;
            _availableTo = to;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update search parameters whenever filters change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchParametersProvider.notifier).state = SearchParameters(
        location: _currentLocation,
        radiusKm: 10.0,
        bikeType: _filterType,
        size: _filterSize,
        maxHourlyRate: _maxHourlyRate,
        maxDailyRate: _maxDailyRate,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
        hasHelmet: _filterHelmet ? true : null,
        hasLock: _filterLock ? true : null,
      );
    });
    
    final listingsStream = ref.watch(searchBikeListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent a Bike'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == ViewMode.list ? Icons.map : Icons.list),
            onPressed: () {
              setState(() {
                _viewMode =
                    _viewMode == ViewMode.list ? ViewMode.map : ViewMode.list;
              });
            },
            tooltip: _viewMode == ViewMode.list ? 'Map View' : 'List View',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: 'Filters',
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chip bar
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (_filterType != null)
                          _FilterChip(
                            label: _filterType!.displayName,
                            onDeleted: () {
                              setState(() => _filterType = null);
                            },
                          ),
                        if (_filterSize != null)
                          _FilterChip(
                            label: 'Size ${_filterSize!.displayName}',
                            onDeleted: () {
                              setState(() => _filterSize = null);
                            },
                          ),
                        if (_maxHourlyRate != null)
                          _FilterChip(
                            label: '≤ ${_maxHourlyRate!.toInt()} DKK/hr',
                            onDeleted: () {
                              setState(() => _maxHourlyRate = null);
                            },
                          ),
                        if (_filterHelmet)
                          _FilterChip(
                            label: 'With Helmet',
                            onDeleted: () {
                              setState(() => _filterHelmet = false);
                            },
                          ),
                        if (_filterLock)
                          _FilterChip(
                            label: 'With Lock',
                            onDeleted: () {
                              setState(() => _filterLock = false);
                            },
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: StreamBuilder<List<BikeListing>>(
              stream: listingsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading listings:\n${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final listings = snapshot.data!;
                if (listings.isEmpty) {
                  return _buildEmptyState();
                }

                return _viewMode == ViewMode.list
                    ? _buildListView(listings)
                    : _buildMapView(listings);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBikeListingScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('List Your Bike'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pedal_bike, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No bikes available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters
                ? 'Try changing your filters'
                : 'Be the first to list your bike!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<BikeListing> listings) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _BikeListingCard(listing: listing);
      },
    );
  }

  Widget _buildMapView(List<BikeListing> listings) {
    final markers = listings.map((listing) {
      return Marker(
        markerId: MarkerId(listing.id),
        position: listing.location,
        infoWindow: InfoWindow(
          title: listing.title,
          snippet: '${listing.pricing.formattedHourlyRate}/hr',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BikeDetailScreen(listingId: listing.id),
              ),
            );
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          listing.bikeType == BikeType.electric
              ? BitmapDescriptor.hueYellow
              : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 12,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}

class _BikeListingCard extends StatelessWidget {
  const _BikeListingCard({required this.listing});

  final BikeListing listing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BikeDetailScreen(listingId: listing.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (listing.hasPhotos)
              Image.network(
                listing.photoUrls.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            else
              _buildPlaceholder(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and type
                  Row(
                    children: [
                      Text(
                        listing.bikeType.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location and rating
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.locationName,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      if (listing.hasReviews) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.averageRating.toStringAsFixed(1)} (${listing.totalReviews})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    listing.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),

                  // Features
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: listing.features.featuresList
                        .take(3)
                        .map((feature) => Chip(
                              label: Text(
                                feature,
                                style: const TextStyle(fontSize: 12),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Pricing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.pricing.formattedHourlyRate,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'per hour',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            listing.pricing.formattedDailyRate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'per day',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.pedal_bike,
          size: 64,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onDeleted,
  });

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
    );
  }
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.filterType,
    required this.filterSize,
    required this.maxHourlyRate,
    required this.maxDailyRate,
    required this.filterHelmet,
    required this.filterLock,
    required this.availableFrom,
    required this.availableTo,
    required this.onApply,
  });

  final BikeType? filterType;
  final BikeSize? filterSize;
  final double? maxHourlyRate;
  final double? maxDailyRate;
  final bool filterHelmet;
  final bool filterLock;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final void Function({
    BikeType? type,
    BikeSize? size,
    double? hourlyRate,
    double? dailyRate,
    bool helmet,
    bool lock,
    DateTime? from,
    DateTime? to,
  }) onApply;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late BikeType? _type;
  late BikeSize? _size;
  late double? _hourlyRate;
  late double? _dailyRate;
  late bool _helmet;
  late bool _lock;
  late DateTime? _from;
  late DateTime? _to;

  @override
  void initState() {
    super.initState();
    _type = widget.filterType;
    _size = widget.filterSize;
    _hourlyRate = widget.maxHourlyRate;
    _dailyRate = widget.maxDailyRate;
    _helmet = widget.filterHelmet;
    _lock = widget.filterLock;
    _from = widget.availableFrom;
    _to = widget.availableTo;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bike Type
              const Text('Bike Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Any'),
                    selected: _type == null,
                    onSelected: (selected) {
                      setState(() => _type = null);
                    },
                  ),
                  ...BikeType.values.map((type) {
                    return ChoiceChip(
                      label: Text('${type.icon} ${type.displayName}'),
                      selected: _type == type,
                      onSelected: (selected) {
                        setState(() => _type = selected ? type : null);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Size
              const Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Any'),
                    selected: _size == null,
                    onSelected: (selected) {
                      setState(() => _size = null);
                    },
                  ),
                  ...BikeSize.values.map((size) {
                    return ChoiceChip(
                      label: Text(size.displayName),
                      selected: _size == size,
                      onSelected: (selected) {
                        setState(() => _size = selected ? size : null);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Price
              const Text('Maximum Price', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Hourly (DKK)',
                        prefixText: '≤ ',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: _hourlyRate?.toInt().toString() ?? '',
                      ),
                      onChanged: (value) {
                        _hourlyRate = double.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Daily (DKK)',
                        prefixText: '≤ ',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: _dailyRate?.toInt().toString() ?? '',
                      ),
                      onChanged: (value) {
                        _dailyRate = double.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Features
              const Text('Features', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Helmet included'),
                value: _helmet,
                onChanged: (value) {
                  setState(() => _helmet = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Lock included'),
                value: _lock,
                onChanged: (value) {
                  setState(() => _lock = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Availability
              const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('From'),
                subtitle: Text(_from != null
                    ? '${_from!.day}/${_from!.month}/${_from!.year}'
                    : 'Any date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _from ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _from = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('To'),
                subtitle: Text(_to != null
                    ? '${_to!.day}/${_to!.month}/${_to!.year}'
                    : 'Any date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _to ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: _from ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _to = picked);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Apply button
              ElevatedButton(
                onPressed: () {
                  widget.onApply(
                    type: _type,
                    size: _size,
                    hourlyRate: _hourlyRate,
                    dailyRate: _dailyRate,
                    helmet: _helmet,
                    lock: _lock,
                    from: _from,
                    to: _to,
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }
}
