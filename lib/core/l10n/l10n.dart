/// Convenience extension so all widgets can do `context.l10n.xxx`
/// instead of `AppLocalizations.of(context)!.xxx`.

import 'package:flutter/widgets.dart';
import 'package:cykel/l10n/app_localizations.dart';

export 'package:cykel/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
