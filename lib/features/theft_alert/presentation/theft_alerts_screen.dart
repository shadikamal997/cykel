import '../../../core/widgets/app_image.dart';
import '../../auth/domain/app_user.dart';
/// CYKEL — Theft Alerts Screen
/// View and report bike thefts in the area

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/location_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/data/bikes_provider.dart';
import '../data/theft_alert_provider.dart';
import '../domain/theft_alert.dart';

class TheftAlertsScreen extends ConsumerStatefulWidget {
  const TheftAlertsScreen({super.key});

  @override
  ConsumerState<TheftAlertsScreen> createState() => _TheftAlertsScreenState();
}

class _TheftAlertsScreenState extends ConsumerState<TheftAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng? _userLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      setState(() {
        _userLocation = LatLng(location.latitude, location.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        // Default to Copenhagen if location fails
        _userLocation = const LatLng(55.6761, 12.5683);
        _loadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.theftAlerts),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: l10n.theftNearby),
            Tab(text: l10n.theftAll),
            Tab(text: l10n.theftMine),
          ],
        ),
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _NearbyTab(userLocation: _userLocation!),
                const _AllReportsTab(),
                const _MyReportsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportTheftSheet(context),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.warning_rounded),
        label: Text(l10n.theftReport),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _TheftAlertSettingsSheet(),
    );
  }

  void _showReportTheftSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportTheftSheet(userLocation: _userLocation),
    );
  }
}

// ─── Nearby Tab ───────────────────────────────────────────────────────────────

class _NearbyTab extends ConsumerWidget {
  const _NearbyTab({required this.userLocation});

  final LatLng userLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settingsAsync = ref.watch(theftAlertSettingsProvider);
    final radius = settingsAsync.valueOrNull?.radiusKm ?? 5.0;
    
    final reportsAsync = ref.watch(nearbyTheftReportsProvider((
      center: userLocation,
      radiusKm: radius,
    )));

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      data: (reports) {
        if (reports.isEmpty) {
          return _EmptyState(
            icon: '🎉',
            title: l10n.theftNoNearby,
            subtitle: l10n.theftNoNearbyDesc(radius.toStringAsFixed(0)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: reports.length,
          itemBuilder: (context, index) => RepaintBoundary(
            child: _TheftReportCard(
              report: reports[index],
              userLocation: userLocation,
              onTap: () => _showReportDetails(context, reports[index]),
            ),
          ),
        );
      },
    );
  }

  void _showReportDetails(BuildContext context, TheftReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TheftReportDetailsSheet(report: report),
    );
  }
}

// ─── All Reports Tab ──────────────────────────────────────────────────────────

class _AllReportsTab extends ConsumerWidget {
  const _AllReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reportsAsync = ref.watch(activeTheftReportsProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.theftError(e.toString()))),
      data: (reports) {
        if (reports.isEmpty) {
          return _EmptyState(
            icon: '🔒',
            title: l10n.theftNoActive,
            subtitle: l10n.theftNoActiveDesc,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: reports.length,
          itemBuilder: (context, index) => RepaintBoundary(
            child: _TheftReportCard(
              report: reports[index],
              onTap: () => _showReportDetails(context, reports[index]),
            ),
          ),
        );
      },
    );
  }

  void _showReportDetails(BuildContext context, TheftReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TheftReportDetailsSheet(report: report),
    );
  }
}

// ─── My Reports Tab ───────────────────────────────────────────────────────────

class _MyReportsTab extends ConsumerWidget {
  const _MyReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reportsAsync = ref.watch(userTheftReportsProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.theftError(e.toString()))),
      data: (reports) {
        if (reports.isEmpty) {
          return _EmptyState(
            icon: '✅',
            title: l10n.theftNoReports,
            subtitle: l10n.theftNoReportsDesc,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: reports.length,
          itemBuilder: (context, index) => _TheftReportCard(
            report: reports[index],
            isOwnReport: true,
            onTap: () => _showReportDetails(context, ref, reports[index]),
          ),
        );
      },
    );
  }

  void _showReportDetails(BuildContext context, WidgetRef ref, TheftReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TheftReportDetailsSheet(report: report, isOwnReport: true),
    );
  }
}

// ─── Theft Report Card ────────────────────────────────────────────────────────

class _TheftReportCard extends StatelessWidget {
  const _TheftReportCard({
    required this.report,
    required this.onTap,
    this.userLocation,
    this.isOwnReport = false,
  });

  final TheftReport report;
  final VoidCallback onTap;
  final LatLng? userLocation;
  final bool isOwnReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: report.status == TheftReportStatus.active
              ? context.colors.border.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Bike Photo or Placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.border.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  image: AppImage.decorationImage(
                    url: report.bikePhotoUrl,
                    thumbnailUrl: AppUser.getThumbnailUrl(report.bikePhotoUrl),
                    preferThumbnail: true,
                  ),
                ),
                child: report.bikePhotoUrl == null
                    ? const Center(
                        child: Text('🚲', style: TextStyle(fontSize: 28)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(report.status.icon),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.bikeName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.bikeDescription,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: context.colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(context, report.reportedAt),
                          style: AppTextStyles.caption.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        if (report.cityArea != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            report.cityArea!,
                            style: AppTextStyles.caption.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: context.colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(BuildContext context, DateTime date) {
    final diff = DateTime.now().difference(date);
    final l10n = context.l10n;
    if (diff.inMinutes < 60) return l10n.theftMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.theftHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.theftDaysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report Theft Sheet ───────────────────────────────────────────────────────

class _ReportTheftSheet extends ConsumerStatefulWidget {
  const _ReportTheftSheet({this.userLocation});

  final LatLng? userLocation;

  @override
  ConsumerState<_ReportTheftSheet> createState() => _ReportTheftSheetState();
}

class _ReportTheftSheetState extends ConsumerState<_ReportTheftSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBikeId;
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _contactController = TextEditingController();
  final _frameNumberController = TextEditingController();
  final _cityAreaController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _contactController.dispose();
    _frameNumberController.dispose();
    _cityAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bikesAsync = ref.watch(bikesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(l10n.theftReportTitle, style: AppTextStyles.headline3),
                ],
              ),
              const SizedBox(height: 24),

              // Select Bike
              bikesAsync.when(
                data: (bikes) {
                  if (bikes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.border.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.theftNoBikes,
                        style: AppTextStyles.bodySmall,
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedBikeId,
                    decoration: InputDecoration(
                      labelText: l10n.theftSelectBike,
                      border: const OutlineInputBorder(),
                    ),
                    items: bikes.map((bike) {
                      return DropdownMenuItem(
                        value: bike.id,
                        child: Text(bike.name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedBikeId = value),
                    validator: (value) => value == null ? l10n.theftSelectBikeError : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(l10n.theftCouldNotLoadBikes),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.theftBikeDescription,
                  hintText: l10n.theftBikeDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? l10n.theftDescriptionRequired : null,
              ),
              const SizedBox(height: 16),

              // Frame Number (Optional)
              TextFormField(
                controller: _frameNumberController,
                decoration: InputDecoration(
                  labelText: l10n.theftFrameNumber,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // City Area
              TextFormField(
                controller: _cityAreaController,
                decoration: InputDecoration(
                  labelText: l10n.theftArea,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Additional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.theftAdditionalNotes,
                  hintText: l10n.theftAdditionalNotesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Info
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: l10n.theftContactInfo,
                  hintText: l10n.theftContactInfoHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.textPrimary,
                  foregroundColor: context.colors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.background,
                        ),
                      )
                    : Text(l10n.theftReport),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBikeId == null) return;

    setState(() => _saving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception(context.l10n.theftNotLoggedIn);

      final bikes = ref.read(bikesProvider).valueOrNull ?? [];
      final selectedBike = bikes.firstWhere((b) => b.id == _selectedBikeId);

      await ref.read(theftAlertServiceProvider).reportTheft(
        uid: user.uid,
        bikeId: _selectedBikeId!,
        bikeName: selectedBike.name,
        bikeDescription: _descriptionController.text,
        location: widget.userLocation ?? const LatLng(55.6761, 12.5683),
        additionalNotes: _notesController.text.isEmpty ? null : _notesController.text,
        contactInfo: _contactController.text.isEmpty ? null : _contactController.text,
        frameNumber: _frameNumberController.text.isEmpty ? null : _frameNumberController.text,
        cityArea: _cityAreaController.text.isEmpty ? null : _cityAreaController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.theftReportSuccess),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.theftError(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Theft Report Details Sheet ───────────────────────────────────────────────

class _TheftReportDetailsSheet extends ConsumerWidget {
  const _TheftReportDetailsSheet({
    required this.report,
    this.isOwnReport = false,
  });

  final TheftReport report;
  final bool isOwnReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(context, report.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(report.status.icon),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusName(context, report.status),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _statusColor(context, report.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(context, report.reportedAt),
                    style: AppTextStyles.caption.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bike Name
              Text(report.bikeName, style: AppTextStyles.headline2),
              const SizedBox(height: 8),
              Text(
                report.bikeDescription,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Details
              if (report.cityArea != null)
                _DetailRow(icon: Icons.location_on, label: l10n.theftAreaLabel, value: report.cityArea!),
              if (report.frameNumber != null)
                _DetailRow(icon: Icons.tag, label: l10n.theftFrameNumberLabel, value: report.frameNumber!),
              if (report.additionalNotes != null)
                _DetailRow(icon: Icons.notes, label: l10n.theftNotesLabel, value: report.additionalNotes!),
              if (report.contactInfo != null && !isOwnReport)
                _DetailRow(icon: Icons.phone, label: l10n.theftContactLabel, value: report.contactInfo!),

              const SizedBox(height: 24),

              // Actions
              if (isOwnReport && report.status == TheftReportStatus.active) ...[
                ElevatedButton.icon(
                  onPressed: () => _markRecovered(context, ref),
                  icon: const Icon(Icons.check_circle),
                  label: Text(l10n.theftMarkRecovered),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.textPrimary,
                    foregroundColor: context.colors.background,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _closeReport(context, ref),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.theftCloseReport),
                ),
              ] else if (!isOwnReport && report.status == TheftReportStatus.active) ...[
                ElevatedButton.icon(
                  onPressed: () => _reportSighting(context, ref),
                  icon: const Icon(Icons.visibility),
                  label: Text(l10n.theftSeenThisBike),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.textPrimary,
                    foregroundColor: context.colors.background,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(BuildContext context, TheftReportStatus status) {
    switch (status) {
      case TheftReportStatus.active:
        return context.colors.textPrimary;
      case TheftReportStatus.recovered:
        return context.colors.textPrimary.withValues(alpha: 0.7);
      case TheftReportStatus.closed:
        return context.colors.textSecondary;
    }
  }

  String _getStatusName(BuildContext context, TheftReportStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case TheftReportStatus.active:
        return l10n.theftStatusActive;
      case TheftReportStatus.recovered:
        return l10n.theftStatusRecovered;
      case TheftReportStatus.closed:
        return l10n.theftStatusClosed;
    }
  }

  String _timeAgo(BuildContext context, DateTime date) {
    final diff = DateTime.now().difference(date);
    final l10n = context.l10n;
    if (diff.inMinutes < 60) return l10n.theftMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.theftHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.theftDaysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _markRecovered(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(theftAlertServiceProvider).updateReportStatus(
        report.id,
        TheftReportStatus.recovered,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.theftRecoveredSuccess),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorPrefix(e.toString()))),
        );
      }
    }
  }

  Future<void> _closeReport(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(theftAlertServiceProvider).updateReportStatus(
        report.id,
        TheftReportStatus.closed,
      );
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.theftError(e.toString()))),
        );
      }
    }
  }

  Future<void> _reportSighting(BuildContext context, WidgetRef ref) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !context.mounted) return;
      await ref.read(theftAlertServiceProvider).reportSighting(
        reportId: report.id,
        reporterId: user.uid,
        location: LatLng(pos.latitude, pos.longitude),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.theftSightingThanks)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not report sighting: $e')),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Sheet ───────────────────────────────────────────────────────────

class _TheftAlertSettingsSheet extends ConsumerWidget {
  const _TheftAlertSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settingsAsync = ref.watch(theftAlertSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const TheftAlertSettings();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          const SizedBox(height: 16),

          Text(l10n.theftAlarmSettings, style: AppTextStyles.headline3),
          const SizedBox(height: 24),

          SwitchListTile(
            title: Text(l10n.theftEnableAlarms),
            value: settings.enabled,
            onChanged: (value) => _updateSettings(ref, settings.copyWith(enabled: value)),
          ),

          ListTile(
            title: Text(l10n.theftRadius),
            subtitle: Text(l10n.theftRadiusKm(settings.radiusKm.toStringAsFixed(0))),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.radiusKm,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(radiusKm: value)),
              ),
            ),
          ),

          SwitchListTile(
            title: Text(l10n.theftNewThefts),
            subtitle: Text(l10n.theftNewTheftsDesc),
            value: settings.notifyNewThefts,
            onChanged: (value) => _updateSettings(ref, settings.copyWith(notifyNewThefts: value)),
          ),

          SwitchListTile(
            title: Text(l10n.theftSightings),
            subtitle: Text(l10n.theftSightingsDesc),
            value: settings.notifySightings,
            onChanged: (value) => _updateSettings(ref, settings.copyWith(notifySightings: value)),
          ),

          SwitchListTile(
            title: Text(l10n.theftRecoveries),
            subtitle: Text(l10n.theftRecoveriesDesc),
            value: settings.notifyRecoveries,
            onChanged: (value) => _updateSettings(ref, settings.copyWith(notifyRecoveries: value)),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _updateSettings(WidgetRef ref, TheftAlertSettings settings) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(theftAlertServiceProvider).updateSettings(user.uid, settings);
  }
}
