/// CYKEL — Input Validators & Form Utilities

import 'package:flutter/widgets.dart';
import '../constants/denmark_constants.dart';
import '../l10n/l10n.dart';

class AppValidators {
  AppValidators._();

  // --- Email ---
  static String? Function(String?) email(BuildContext context) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return context.l10n.validationEmailRequired;
      }
      final emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return context.l10n.validationEmailInvalid;
      }
      return null;
    };
  }

  // --- Password ---
  static String? Function(String?) password(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return context.l10n.validationPasswordRequired;
      }
      if (value.length < 8) {
        return context.l10n.validationPasswordTooShort;
      }
      return null;
    };
  }

  static String? Function(String?) confirmPassword(
      BuildContext context, String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return context.l10n.validationConfirmPasswordRequired;
      }
      if (value != password) {
        return context.l10n.validationPasswordsDoNotMatch;
      }
      return null;
    };
  }

  // --- Name ---
  static String? Function(String?) name(BuildContext context) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return context.l10n.validationNameRequired;
      }
      if (value.trim().length < 2) {
        return context.l10n.validationNameTooShort;
      }
      return null;
    };
  }

  // --- Phone (Denmark) ---
  static String? Function(String?) danishPhone(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) return null; // Optional
      final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
      // Danish numbers: 8 digits, optionally starting with +45
      final dkRegex = RegExp(r'^(45)?[2-9]\d{7}$');
      if (!dkRegex.hasMatch(cleaned)) {
        return context.l10n.validationPhoneInvalid;
      }
      return null;
    };
  }

  // --- Danish Postal Code ---
  static String? Function(String?) danishPostalCode(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return context.l10n.validationPostalCodeRequired;
      }
      if (!DenmarkConstants.postalCodeRegex.hasMatch(value)) {
        return context.l10n.validationPostalCodeInvalid;
      }
      final code = int.tryParse(value);
      if (code == null ||
          code < DenmarkConstants.postalCodeMin ||
          code > DenmarkConstants.postalCodeMax) {
        return context.l10n.validationPostalCodeRange;
      }
      return null;
    };
  }

  // --- Required Field ---
  static String? Function(String?) required(BuildContext context,
      {String label = 'This field'}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return context.l10n.validationFieldRequired(label);
      }
      return null;
    };
  }

  // --- Price ---
  static String? Function(String?) price(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return context.l10n.validationPriceRequired;
      }
      final parsed = double.tryParse(value.replaceAll(',', '.'));
      if (parsed == null || parsed < 0) {
        return context.l10n.validationPriceInvalid;
      }
      if (parsed > 999999) {
        return context.l10n.validationPriceTooHigh;
      }
      return null;
    };
  }

  // --- Serial Number ---
  static String? Function(String?) serialNumber(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) return null; // Optional
      if (value.trim().length < 4) {
        return context.l10n.validationSerialTooShort;
      }
      if (value.trim().length > 50) {
        return context.l10n.validationSerialTooLong;
      }
      return null;
    };
  }

  // --- URL ---
  static String? Function(String?) url(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) return null; // Optional
      final urlRegex = RegExp(
        r'^https?://([\w.-]+)(:[0-9]+)?(/.*)?$',
        caseSensitive: false,
      );
      if (!urlRegex.hasMatch(value)) {
        return context.l10n.validationUrlInvalid;
      }
      return null;
    };
  }
}
