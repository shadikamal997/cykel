/// CYKEL — My Rentals Screen
/// Manage bike rentals (as renter and owner)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/bike_listing.dart';
import '../domain/rental_agreement.dart';
import '../application/bike_rental_providers.dart';
import 'create_bike_listing_screen.dart';
import 'bike_detail_screen.dart';

enum RentalTab { asRenter, asOwner, myListings }

class MyRentalsScreen extends ConsumerStatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  ConsumerState<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends ConsumerState<MyRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('My Rentals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Renting', icon: Icon(Icons.pedal_bike)),
            Tab(text: 'My Bikes', icon: Icon(Icons.two_wheeler)),
            Tab(text: 'Listings', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AsRenterTab(),
          _AsOwnerTab(),
          _MyListingsTab(),
        ],
      ),
    );
  }
}

// ─── As Renter Tab ──────────────────────────────────────────────────────────

class _AsRenterTab extends ConsumerWidget {
  const _AsRenterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRentalRequestsProvider);
    final rentalsAsync = ref.watch(myRentalsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics
        _buildStatsCard(ref),
        const SizedBox(height: 24),

        // Pending Requests
        const Text(
          'Pending Requests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        requestsAsync.when(
          data: (requests) {
            final pendingRequests =
                requests.where((r) => r.status == RentalRequestStatus.pending).toList();
            if (pendingRequests.isEmpty) {
              return const _EmptyState(
                message: 'No pending requests',
                icon: Icons.check_circle_outline,
              );
            }
            return Column(
              children: pendingRequests.map((request) {
                return _RentalRequestCard(request: request);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
        const SizedBox(height: 24),

        // Active Rentals
        const Text(
          'Active Rentals',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        rentalsAsync.when(
          data: (rentals) {
            final activeRentals = rentals
                .where((r) =>
                    r.status == RentalAgreementStatus.active ||
                    r.status == RentalAgreementStatus.upcoming)
                .toList();
            if (activeRentals.isEmpty) {
              return const _EmptyState(
                message: 'No active rentals',
                icon: Icons.pedal_bike,
              );
            }
            return Column(
              children: activeRentals.map((rental) {
                return _RentalAgreementCard(
                  rental: rental,
                  isOwner: false,
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
        const SizedBox(height: 24),

        // History
        const Text(
          'Rental History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        rentalsAsync.when(
          data: (rentals) {
            final completedRentals =
                rentals.where((r) => r.status == RentalAgreementStatus.completed).toList();
            if (completedRentals.isEmpty) {
              return const _EmptyState(
                message: 'No rental history',
                icon: Icons.history,
              );
            }
            return Column(
              children: completedRentals.take(5).map((rental) {
                return _RentalAgreementCard(
                  rental: rental,
                  isOwner: false,
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildStatsCard(WidgetRef ref) {
    final statsAsync = ref.watch(myRentalStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total',
                  value: stats.totalRentals.toString(),
                  icon: Icons.pedal_bike,
                ),
                _StatItem(
                  label: 'Active',
                  value: stats.activeRentals.toString(),
                  icon: Icons.directions_bike,
                ),
                _StatItem(
                  label: 'Spent',
                  value: '${stats.totalSpent.toStringAsFixed(0)} DKK',
                  icon: Icons.payments,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── As Owner Tab ───────────────────────────────────────────────────────────

class _AsOwnerTab extends ConsumerWidget {
  const _AsOwnerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(receivedRentalRequestsProvider);
    final rentalsAsync = ref.watch(myBikeRentalsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics
        _buildStatsCard(ref),
        const SizedBox(height: 24),

        // Pending Requests
        const Text(
          'Rental Requests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return const _EmptyState(
                message: 'No pending requests',
                icon: Icons.inbox,
              );
            }
            return Column(
              children: requests.map((request) {
                return _OwnerRequestCard(request: request);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
        const SizedBox(height: 24),

        // Active Rentals
        const Text(
          'Active Rentals',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        rentalsAsync.when(
          data: (rentals) {
            final activeRentals = rentals
                .where((r) =>
                    r.status == RentalAgreementStatus.active ||
                    r.status == RentalAgreementStatus.upcoming)
                .toList();
            if (activeRentals.isEmpty) {
              return const _EmptyState(
                message: 'No active rentals',
                icon: Icons.two_wheeler,
              );
            }
            return Column(
              children: activeRentals.map((rental) {
                return _RentalAgreementCard(
                  rental: rental,
                  isOwner: true,
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
        const SizedBox(height: 24),

        // History
        const Text(
          'Rental History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        rentalsAsync.when(
          data: (rentals) {
            final completedRentals =
                rentals.where((r) => r.status == RentalAgreementStatus.completed).toList();
            if (completedRentals.isEmpty) {
              return const _EmptyState(
                message: 'No rental history',
                icon: Icons.history,
              );
            }
            return Column(
              children: completedRentals.take(5).map((rental) {
                return _RentalAgreementCard(
                  rental: rental,
                  isOwner: true,
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildStatsCard(WidgetRef ref) {
    final statsAsync = ref.watch(myBikeRentalStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total',
                  value: stats.totalRentals.toString(),
                  icon: Icons.trending_up,
                ),
                _StatItem(
                  label: 'Active',
                  value: stats.activeRentals.toString(),
                  icon: Icons.directions_bike,
                ),
                _StatItem(
                  label: 'Earned',
                  value: '${stats.totalSpent.toStringAsFixed(0)} DKK',
                  icon: Icons.account_balance_wallet,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── My Listings Tab ────────────────────────────────────────────────────────

class _MyListingsTab extends ConsumerWidget {
  const _MyListingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myBikeListingsProvider);

    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pedal_bike, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No listings yet'),
                const SizedBox(height: 8),
                const Text('List your bike to start earning!'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateBikeListingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Listing'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildStatsCard(listings, context);
            }
            final listing = listings[index - 1];
            return _ListingCard(listing: listing);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatsCard(List<BikeListing> listings, BuildContext context) {
    final activeCount = listings.where((l) => l.status == ListingStatus.active).length;
    final rentedCount = listings.where((l) => l.status == ListingStatus.rented).length;
    final totalRentals = listings.fold<int>(0, (sum, l) => sum + l.totalRentals);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Active',
                  value: activeCount.toString(),
                  icon: Icons.check_circle,
                ),
                _StatItem(
                  label: 'Rented',
                  value: rentedCount.toString(),
                  icon: Icons.pedal_bike,
                ),
                _StatItem(
                  label: 'Total Rentals',
                  value: totalRentals.toString(),
                  icon: Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBikeListingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Listing'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RentalRequestCard extends ConsumerWidget {
  const _RentalRequestCard({required this.request});

  final RentalRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(bikeListingProvider(request.listingId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${request.status.icon} ${request.status.displayName}',
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${request.totalCost.toStringAsFixed(0)} DKK',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            listingAsync.when(
              data: (listing) {
                if (listing == null) return const Text('Listing not found');
                return Text(
                  listing.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              },
              loading: () => const Text('Loading...'),
              error: (_, _) => const Text('Error loading listing'),
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${request.startTime.day}/${request.startTime.month} ${request.startTime.hour}:${request.startTime.minute.toString().padLeft(2, '0')}',
            ),
            Text(
              'To: ${request.endTime.day}/${request.endTime.month} ${request.endTime.hour}:${request.endTime.minute.toString().padLeft(2, '0')}',
            ),
            if (request.message != null) ...[
              const SizedBox(height: 8),
              Text(
                request.message!,
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RentalRequestStatus status) {
    switch (status) {
      case RentalRequestStatus.pending:
        return Colors.orange;
      case RentalRequestStatus.approved:
        return Colors.green;
      case RentalRequestStatus.declined:
        return Colors.red;
      case RentalRequestStatus.cancelled:
        return Colors.grey;
      case RentalRequestStatus.expired:
        return Colors.grey;
    }
  }
}

class _OwnerRequestCard extends ConsumerWidget {
  const _OwnerRequestCard({required this.request});

  final RentalRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(bikeRentalServiceProvider);
    final listingAsync = ref.watch(bikeListingProvider(request.listingId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            listingAsync.when(
              data: (listing) {
                if (listing == null) return const Text('Listing not found');
                return Text(
                  listing.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              },
              loading: () => const Text('Loading...'),
              error: (_, _) => const Text('Error loading listing'),
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${request.startTime.day}/${request.startTime.month} ${request.startTime.hour}:${request.startTime.minute.toString().padLeft(2, '0')}',
            ),
            Text(
              'To: ${request.endTime.day}/${request.endTime.month} ${request.endTime.hour}:${request.endTime.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 8),
            Text(
              'Rental: ${request.totalCost.toStringAsFixed(0)} DKK',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (request.message != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  request.message!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Decline Request'),
                          content: const Text('Are you sure you want to decline this request?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Decline'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await service.declineRentalRequest(request.id, 'Not available');
                      }
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Approve Request'),
                          content: const Text(
                            'Are you sure you want to approve this rental request?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await service.approveRentalRequest(request.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request approved! Renter has been notified.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalAgreementCard extends ConsumerWidget {
  const _RentalAgreementCard({
    required this.rental,
    required this.isOwner,
  });

  final RentalAgreement rental;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(bikeListingProvider(rental.listingId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(rental.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${rental.status.icon} ${rental.status.displayName}',
                    style: TextStyle(
                      color: _getStatusColor(rental.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${rental.rentalCost.toStringAsFixed(0)} DKK',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            listingAsync.when(
              data: (listing) {
                if (listing == null) return const Text('Listing not found');
                return Text(
                  listing.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              },
              loading: () => const Text('Loading...'),
              error: (_, _) => const Text('Error loading listing'),
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${rental.startTime.day}/${rental.startTime.month} ${rental.startTime.hour}:${rental.startTime.minute.toString().padLeft(2, '0')}',
            ),
            Text(
              'To: ${rental.endTime.day}/${rental.endTime.month} ${rental.endTime.hour}:${rental.endTime.minute.toString().padLeft(2, '0')}',
            ),
            if (rental.isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'OVERDUE by ${rental.overdueBy!.inHours} hours',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RentalAgreementStatus status) {
    switch (status) {
      case RentalAgreementStatus.upcoming:
        return Colors.blue;
      case RentalAgreementStatus.active:
        return Colors.green;
      case RentalAgreementStatus.completed:
        return Colors.grey;
      case RentalAgreementStatus.cancelled:
        return Colors.red;
      case RentalAgreementStatus.disputed:
        return Colors.orange;
    }
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.listing});

  final BikeListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(bikeRentalServiceProvider);

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BikeDetailScreen(listingId: listing.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          listing.bikeType.displayName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(listing.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(listing.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoItem(
                    icon: Icons.star,
                    label: listing.averageRating.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 16),
                  _InfoItem(
                    icon: Icons.trending_up,
                    label: '${listing.totalRentals} rentals',
                  ),
                  const Spacer(),
                  Text(
                    '${listing.pricing.hourlyRate.toStringAsFixed(0)} DKK/hr',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateBikeListingScreen(listing: listing),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Listing'),
                            content: const Text(
                              'Are you sure you want to delete this listing? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await service.deleteListing(listing.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Listing deleted'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return Colors.green;
      case ListingStatus.rented:
        return Colors.blue;
      case ListingStatus.unavailable:
        return Colors.orange;
      case ListingStatus.archived:
        return Colors.grey;
    }
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
