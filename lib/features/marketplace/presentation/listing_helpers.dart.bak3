/// CYKEL — Shared Marketplace Listing Helpers
/// Extracted from create_listing_screen.dart and listing_detail_screen.dart
/// to avoid duplication.

import 'package:flutter/material.dart';
import 'package:cykel/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/marketplace_listing.dart';

String conditionLabel(AppLocalizations l10n, ListingCondition c) => switch (c) {
      ListingCondition.newItem => l10n.listingConditionNew,
      ListingCondition.likeNew => l10n.listingConditionLikeNew,
      ListingCondition.good => l10n.listingConditionGood,
      ListingCondition.fair => l10n.listingConditionFair,
    };

Color conditionColor(ListingCondition c) => switch (c) {
      ListingCondition.newItem => AppColors.success,
      ListingCondition.likeNew => AppColors.info,
      ListingCondition.good => AppColors.warning,
      ListingCondition.fair => AppColors.textSecondary,
    };
