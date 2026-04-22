/// CYKEL — Bike Detail Screen
/// View detailed information about a bike listing

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/cached_image.dart';

import '../domain/bike_listing.dart';
import '../domain/rental_agreement.dart';
import '../application/bike_rental_providers.dart';

class BikeDetailScreen extends ConsumerStatefulWidget {
  const BikeDetailScreen({
    super.key,
    required this.listingId,
  });

  final String listingId;

  @override
  ConsumerState<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends ConsumerState<BikeDetailScreen> {
  int _currentPhotoIndex = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  DateTime? _getCombinedDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _requestRental(BikeListing listing) async {
    final startDateTime = _getCombinedDateTime(_startDate, _startTime);
    final endDateTime = _getCombinedDateTime(_endDate, _endTime);

    if (startDateTime == null || endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.rentalSelectDates),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.rentalEndAfterStart),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate cost
    final cost = listing.pricing.calculateCost(
      startTime: startDateTime,
      endTime: endDateTime,
    );

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.rentalConfirmRequest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.rentalBikeLabel(listing.title)),
            const SizedBox(height: 8),
            Text('From: ${startDateTime.day}/${startDateTime.month} at ${startDateTime.hour}:${startDateTime.minute.toString().padLeft(2, '0')}'),
            Text('To: ${endDateTime.day}/${endDateTime.month} at ${endDateTime.hour}:${endDateTime.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 16),
            Text(
              'Rental Cost: ${cost.toStringAsFixed(0)} DKK',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Deposit: ${listing.pricing.depositAmount.toStringAsFixed(0)} DKK',
              style: const TextStyle(fontSize: 14),
            ),
            const Divider(height: 24),
            Text(
              'Total: ${(cost + listing.pricing.depositAmount).toStringAsFixed(0)} DKK',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.buddySendRequest),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(bikeRentalServiceProvider);
      await service.createRentalRequest(
        listingId: listing.id,
        startTime: startDateTime,
        endTime: endDateTime,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.rentalRequestSent),
            backgroundColor: Colors.green,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(bikeListingProvider(widget.listingId));
    final reviewsAsync = ref.watch(listingReviewsProvider(widget.listingId));

    return listingAsync.when(
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.rentalListingNotFound)),
          );
        }
        return Scaffold(
          body: _buildContent(listing, reviewsAsync),
          bottomNavigationBar: _buildBookingSheet(listing),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.errorPrefix(error.toString()))),
      ),
    );
  }

  Widget _buildContent(
    BikeListing listing,
    AsyncValue<List<BikeReview>> reviewsAsync,
  ) {
    return CustomScrollView(
      slivers: [
        // Photos
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: listing.hasPhotos
                ? PageView.builder(
                    itemCount: listing.photoUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return CachedImage(
                        imageUrl: listing.photoUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : _buildPlaceholder(),
          ),
        ),

        // Photo indicator
        if (listing.hasPhotos && listing.photoUrls.length > 1)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  listing.photoUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPhotoIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and type
                Row(
                  children: [
                    Text(
                      listing.bikeType.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            listing.bikeType.displayName,
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
                const SizedBox(height: 16),

                // Rating
                if (listing.hasReviews)
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < listing.averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${listing.averageRating.toStringAsFixed(1)} (${listing.totalReviews} reviews)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${listing.totalRentals} rentals',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        listing.locationName,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pricing
                _buildSection(
                  title: 'Pricing',
                  child: Column(
                    children: [
                      _buildPriceRow('Hourly Rate', listing.pricing.formattedHourlyRate),
                      _buildPriceRow('Daily Rate', listing.pricing.formattedDailyRate),
                      if (listing.pricing.weeklyRate != null)
                        _buildPriceRow('Weekly Rate', listing.pricing.formattedWeeklyRate!),
                      const Divider(),
                      _buildPriceRow(
                        'Security Deposit',
                        listing.pricing.formattedDeposit,
                        subtitle: 'Refunded after return',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                _buildSection(
                  title: 'Description',
                  child: Text(listing.description),
                ),
                const SizedBox(height: 24),

                // Details
                _buildSection(
                  title: 'Details',
                  child: Column(
                    children: [
                      if (listing.brand != null)
                        _buildDetailRow('Brand', listing.brand!),
                      if (listing.model != null)
                        _buildDetailRow('Model', listing.model!),
                      if (listing.year != null)
                        _buildDetailRow('Year', listing.year.toString()),
                      if (listing.color != null)
                        _buildDetailRow('Color', listing.color!),
                      _buildDetailRow('Size', listing.size.displayName),
                      _buildDetailRow('Condition', listing.condition.displayName),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Features
                if (listing.features.featuresList.isNotEmpty)
                  _buildSection(
                    title: 'Features',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: listing.features.featuresList.map((feature) {
                        return Chip(
                          label: Text(feature),
                          avatar: const Icon(Icons.check, size: 16),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 24),

                // Rental Terms
                _buildSection(
                  title: 'Rental Terms',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Minimum Rental',
                        '${listing.minimumRentalHours} hours',
                      ),
                      if (listing.maximumRentalDays != null)
                        _buildDetailRow(
                          'Maximum Rental',
                          '${listing.maximumRentalDays} days',
                        ),
                      if (listing.pickupInstructions != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Pickup Instructions:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(listing.pickupInstructions!),
                      ],
                      if (listing.rules != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Rules:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(listing.rules!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reviews
                reviewsAsync.when(
                  data: (reviews) {
                    if (reviews.isEmpty) return const SizedBox.shrink();
                    return _buildSection(
                      title: 'Reviews (${reviews.length})',
                      child: Column(
                        children: reviews.take(3).map((review) {
                          return _ReviewCard(review: review);
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.pedal_bike,
          size: 80,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildBookingSheet(BikeListing listing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date/Time pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectStartTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _startTime != null
                            ? '${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _endTime != null
                            ? '${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Request button
            ElevatedButton(
              onPressed: () => _requestRental(listing),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(context.l10n.rentalRequestButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final BikeReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
                const Spacer(),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (review.hasComment) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            if (review.cleanliness != null || review.condition != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (review.cleanliness != null)
                    _DetailChip(
                      label: 'Cleanliness',
                      rating: review.cleanliness!,
                    ),
                  if (review.condition != null) ...[
                    const SizedBox(width: 8),
                    _DetailChip(
                      label: 'Condition',
                      rating: review.condition!,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.rating,
  });

  final String label;
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label $rating/5'),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: const TextStyle(fontSize: 11),
    );
  }
}
