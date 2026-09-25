import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// Convenience accessor for the generated localizations.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
