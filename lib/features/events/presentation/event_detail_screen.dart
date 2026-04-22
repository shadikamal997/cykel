/// CYKEL — Event Detail Screen
/// View event details, join/leave, see participants

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/pending_route_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../discover/data/places_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/app_image.dart';
import '../../../services/calendar_service.dart';
import '../data/events_provider.dart';
import '../domain/event.dart';
import 'event_chat_screen.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kPrimaryColor = AppColors.primary;
const _kPrimaryPressed = AppColors.primaryDark;
const _kPrimaryText = AppColors.textPrimary;
const _kSecondaryText = AppColors.textSecondary;
const _kBackground = AppColors.background;
const _kCardBackground = AppColors.surface;
const _kSoftElements = AppColors.surfaceVariant;

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  // ignore: unused_field - kept for future map interaction features
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {

    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final user = ref.watch(currentUserProvider);

    return eventAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.eventError)),
        body: Center(child: Text('${context.l10n.eventError}: $e')),
      ),
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.eventNotFound)),
            body: Center(child: Text(context.l10n.eventNotFoundMessage)),
          );
        }

        final isOrganizer = user?.uid == event.organizerId;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final heroHeight = MediaQuery.of(context).size.height * 0.45;

        return Scaffold(
          backgroundColor: isDark ? AppColors.surfaceDark : _kBackground,
          body: Stack(
            children: [
              // ─── Hero Image (Full width, 40-50% screen height) ───────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main image or map preview
                    if (event.imageUrl != null)
                      CachedImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                        height: heroHeight,
                      )
                    else
                      _buildMapPreviewBackground(event),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Top Navigation Icons ────────────────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: Icons.calendar_today,
                          onTap: () => _addToCalendar(event),
                        ),
                        const SizedBox(width: 8),
                        _buildCircleButton(
                          icon: Icons.share,
                          onTap: () => _shareEvent(event),
                        ),
                        if (isOrganizer) ...[
                          const SizedBox(width: 8),
                          _buildOrganizerMenu(event, isDark),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Bottom Sheet (Overlapping Hero) ─────────────────────────────
              DraggableScrollableSheet(
                initialChildSize: 0.62,
                minChildSize: 0.55,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : _kBackground,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        bottom: 100 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pull indicator
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 20),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? AppColors.mutedForeground 
                                    : AppColors.muted,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildPremiumHeader(event, isDark),
                          _buildParticipantsRow(event, isDark),
                          const SizedBox(height: 24),
                          _buildPremiumInfoRows(event, isDark),
                          if (event.description != null) 
                            _buildPremiumDescription(event, isDark),
                          _buildPremiumOrganizerSection(event, isDark),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          bottomSheet: _buildBottomButton(event, user, isOrganizer),
        );
      },
    );
  }

  Widget _buildMapPreviewBackground(RideEvent event) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: event.meetingPoint.latLng,
        zoom: 15,
      ),
      onMapCreated: (c) => _mapController = c,
      markers: {
        Marker(
          markerId: const MarkerId('meeting'),
          position: event.meetingPoint.latLng,
        ),
      },
      zoomControlsEnabled: false,
      scrollGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
    );
  }

  // ─── Premium UI Helpers ────────────────────────────────────────────────────

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildOrganizerMenu(RideEvent event, bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
        onSelected: (value) => _handleMenuAction(value, event),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: _kCardBackground,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        offset: const Offset(0, 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'edit',
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 22, color: _kSecondaryText),
                const SizedBox(width: 14),
                Text(ctx.l10n.editEvent, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kSecondaryText)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'cancel',
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, size: 22, color: _kSecondaryText),
                const SizedBox(width: 14),
                Text(ctx.l10n.cancelEvent, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kSecondaryText)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'delete',
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 22, color: AppColors.error),
                const SizedBox(width: 14),
                Text(ctx.l10n.deleteEvent, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(RideEvent event, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPremiumBadge(
                text: '${event.eventType.icon} ${event.eventType.localizedLabel(context)}',
                isDark: isDark,
              ),
              _buildPremiumBadge(
                text: '${event.difficulty.icon} ${event.difficulty.localizedLabel(context)}',
                isDark: isDark,
              ),
              if (event.isNoDrop)
                _buildPremiumBadge(
                  text: '👥 ${context.l10n.noDropPolicy}',
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            event.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : _kPrimaryText,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge({required String text, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.cardDark 
            : _kCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? AppColors.mutedForeground 
              : _kSoftElements,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : _kSecondaryText,
        ),
      ),
    );
  }

  Widget _buildParticipantsRow(RideEvent event, bool isDark) {
    final participantsAsync = ref.watch(eventParticipantsProvider(event.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: participantsAsync.when(
        loading: () => const SizedBox(height: 36),
        error: (_, _) => const SizedBox(height: 36),
        data: (participants) {
          return Row(
            children: [
              // Stacked avatars
              SizedBox(
                width: 20 + (participants.take(4).length - 1).clamp(0, 3) * 16.0,
                height: 36,
                child: Stack(
                  children: List.generate(
                    participants.take(4).length,
                    (index) {
                      final p = participants[index];
                      return Positioned(
                        left: index * 16.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: [
                              _kPrimaryColor,
                              _kPrimaryPressed,
                              _kSecondaryText,
                              _kSoftElements,
                            ][index % 4],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              width: 2,
                            ),
                            image: AppImage.decorationImage(
                              url: p.userPhotoUrl,
                              thumbnailUrl: null,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: p.userPhotoUrl == null
                              ? Center(
                                  child: Text(
                                    p.userName.isNotEmpty ? p.userName[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${event.currentParticipants} ${context.l10n.peopleJoined}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark 
                      ? AppColors.textSecondary 
                      : _kSecondaryText,
                ),
              ),
              if (event.isFull) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.l10n.eventFull,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumInfoRows(RideEvent event, bool isDark) {
    return Column(
      children: [
        // Date & Time row
        _buildInfoRow(
          icon: Icons.calendar_today_outlined,
          label: context.l10n.dateAndTime,
          value: '${event.formattedDate} • ${event.formattedTime}',
          subtitle: event.durationMinutes != null
              ? context.l10n.estimatedDuration(
                  (event.durationMinutes! / 60).toStringAsFixed(1))
              : null,
          isDark: isDark,
          onTap: null,
        ),

        // Location row
        _buildInfoRow(
          icon: Icons.location_on_outlined,
          label: context.l10n.meetingPoint,
          value: event.meetingPoint.name ?? event.meetingPoint.address,
          subtitle: event.meetingPoint.name != null ? event.meetingPoint.address : null,
          isDark: isDark,
          onTap: () => _openInMaps(event.meetingPoint),
          showArrow: true,
        ),

        // Distance & Pace row (if available)
        if (event.distanceKm != null || event.paceKmh != null)
          _buildInfoRow(
            icon: Icons.straighten_outlined,
            label: context.l10n.rideDetails,
            value: [
              if (event.distanceKm != null) '${event.distanceKm!.toStringAsFixed(1)} ${context.l10n.kmUnit}',
              if (event.paceKmh != null) '${event.paceKmh!.toStringAsFixed(0)} ${context.l10n.kmhUnit}',
            ].join(' • '),
            isDark: isDark,
            onTap: null,
          ),

        // Requirements row (if lights required)
        if (event.requiresLights)
          _buildInfoRow(
            icon: Icons.lightbulb_outline,
            label: context.l10n.lightsRequired,
            value: context.l10n.lightsRequired,
            isDark: isDark,
            onTap: null,
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required bool isDark,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.mutedForeground
                    : _kCardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDark
                    ? AppColors.textSecondary
                    : _kPrimaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondary
                          : _kSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : _kPrimaryText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textHint
                            : _kSecondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.mutedForeground
                    : _kSoftElements,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumDescription(RideEvent event, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.eventDescription,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark 
                  ? AppColors.textSecondary
                  : _kSecondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description!,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : _kPrimaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOrganizerSection(RideEvent event, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kPrimaryColor,
              shape: BoxShape.circle,
              image: AppImage.decorationImage(
                url: event.organizerPhotoUrl,
                thumbnailUrl: event.organizerPhotoThumbnail,
                preferThumbnail: true,
              ),
            ),
            child: event.organizerPhotoUrl == null
                ? Center(
                    child: Text(
                      event.organizerName.isNotEmpty
                          ? event.organizerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.eventOrganizer,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondary
                        : _kSecondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.organizerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : _kPrimaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(RideEvent event, user, bool isOrganizer) {
    final statusAsync = ref.watch(participationStatusProvider(event.id));

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildJoinButton(event, user),
        data: (status) {
          if (isOrganizer) {
            return ElevatedButton.icon(
              onPressed: () => _showChat(event),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat),
              label: Text(
                context.l10n.openChat,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          if (status == ParticipantStatus.confirmed) {
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _leaveEvent(event),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: context.colors.border,
                        width: 1.5,
                      ),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      context.l10n.leaveEvent,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChat(event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat),
                    label: Text(
                      context.l10n.chat,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return _buildJoinButton(event, user);
        },
      ),
    );
  }

  Widget _buildJoinButton(RideEvent event, user) {
    final isDisabled = event.isFull || 
                       event.status != EventStatus.upcoming ||
                       user == null;

    return ElevatedButton(
      onPressed: isDisabled ? null : () => _joinEvent(event),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? AppColors.border : _kPrimaryColor,
        foregroundColor: isDisabled ? AppColors.textHint : Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
        ),
        elevation: 0,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textHint,
      ),
      child: Text(
        event.isFull ? context.l10n.eventIsFull : context.l10n.joinEvent,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _joinEvent(RideEvent event) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref.read(eventsServiceProvider).joinEvent(
        eventId: event.id,
        userId: user.uid,
        userName: user.displayName,
        userPhotoUrl: user.photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.youAreJoined)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.eventError}: $e')),
        );
      }
    }
  }

  Future<void> _leaveEvent(RideEvent event) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.leaveEventQuestion),
        content: Text(ctx.l10n.leaveEventConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ctx.l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ctx.l10n.leaveEvent),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(eventsServiceProvider).leaveEvent(event.id, user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.youAreLeft)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.eventError}: $e')),
        );
      }
    }
  }

  void _shareEvent(RideEvent event) {
    SharePlus.instance.share(
      ShareParams(
        text: '🚴 ${event.title}\n'
            '📅 ${event.formattedDate} ${context.l10n.timePrefix} ${event.formattedTime}\n'
            '📍 ${event.meetingPoint.name ?? event.meetingPoint.address}\n\n'
            '${context.l10n.shareEventText}',
      ),
    );
  }

  Future<void> _addToCalendar(RideEvent event) async {
    try {
      final success = await CalendarService.addEventToCalendar(event);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Event added to calendar'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // User cancelled - no need to show error
          debugPrint('[EventDetail] User cancelled adding to calendar');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openInMaps(MeetingPoint point) async {
    // Create a PlaceResult from the meeting point
    final destination = PlaceResult(
      placeId: 'event_${point.latitude}_${point.longitude}',
      text: point.name ?? point.address,
      subtitle: point.address,
      lat: point.latitude,
      lng: point.longitude,
    );

    // Set the pending route provider so MapScreen picks it up
    ref.read(pendingRouteProvider.notifier).state = destination;

    // Navigate to the map tab
    context.go(AppRoutes.map);
  }

  void _showChat(RideEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventChatScreen(
          eventId: event.id,
          eventTitle: event.title,
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action, RideEvent event) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (action) {
      case 'edit':
        context.push('${AppRoutes.editEvent}/${event.id}');
        break;
      case 'cancel':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.l10n.cancelEventQuestion),
            content: Text(ctx.l10n.cancelEventConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(ctx.l10n.cancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: context.colors.textPrimary),
                child: Text(ctx.l10n.confirmCancel),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(eventsServiceProvider).cancelEvent(event.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.eventCancelled)),
            );
          }
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.l10n.deleteEventQuestion),
            content: Text(ctx.l10n.deleteEventConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(ctx.l10n.cancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: context.colors.textPrimary),
                child: Text(ctx.l10n.confirmDelete),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(eventsServiceProvider).deleteEvent(event.id);
          if (mounted) {
            context.pop();
          }
        }
        break;
    }
  }
}


