/// A destination PlaceResult set from outside MapScreen (e.g. Quick Routes on Home).
/// MapScreen reads and clears this on creation.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/discover/data/places_service.dart';

final pendingRouteProvider = StateProvider<PlaceResult?>((ref) => null);

/// Which POI layer to activate when the map tab is opened from Discover.
/// Values: 'charging' | 'service' | 'shop' | 'rental' | null (no-op).
final pendingLayerProvider = StateProvider<String?>((ref) => null);
