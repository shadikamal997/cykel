/// CYKEL Input Validation & Sanitization
/// Protects against XSS, injection attacks, and data corruption

class InputValidator {
  InputValidator._();

  // ─── Text Sanitization ────────────────────────────────────────────────────
  
  /// Sanitize user input to prevent XSS attacks
  static String sanitize(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .trim();
  }

  /// Remove all HTML tags from input
  static String stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  /// Limit string length and sanitize
  static String sanitizeWithLimit(String input, int maxLength) {
    final sanitized = sanitize(input);
    if (sanitized.length > maxLength) {
      return sanitized.substring(0, maxLength);
    }
    return sanitized;
  }

  // ─── Event Validation ─────────────────────────────────────────────────────

  /// Validate event title
  static ValidationResult validateEventTitle(String title) {
    final trimmed = title.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Event title cannot be empty');
    }
    
    if (trimmed.length < 3) {
      return ValidationResult.error('Event title must be at least 3 characters');
    }
    
    if (trimmed.length > 100) {
      return ValidationResult.error('Event title must be 100 characters or less');
    }
    
    // Check for suspicious patterns
    if (_containsSuspiciousPatterns(trimmed)) {
      return ValidationResult.error('Event title contains invalid characters');
    }
    
    return ValidationResult.success(sanitize(trimmed));
  }

  /// Validate event description
  static ValidationResult validateEventDescription(String description) {
    final trimmed = description.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Event description cannot be empty');
    }
    
    if (trimmed.length < 10) {
      return ValidationResult.error('Event description must be at least 10 characters');
    }
    
    if (trimmed.length > 2000) {
      return ValidationResult.error('Event description must be 2000 characters or less');
    }
    
    return ValidationResult.success(sanitize(trimmed));
  }

  // ─── Marketplace Validation ───────────────────────────────────────────────

  /// Validate marketplace listing title
  static ValidationResult validateListingTitle(String title) {
    final trimmed = title.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Listing title cannot be empty');
    }
    
    if (trimmed.length < 3) {
      return ValidationResult.error('Listing title must be at least 3 characters');
    }
    
    if (trimmed.length > 100) {
      return ValidationResult.error('Listing title must be 100 characters or less');
    }
    
    if (_containsSuspiciousPatterns(trimmed)) {
      return ValidationResult.error('Listing title contains invalid characters');
    }
    
    return ValidationResult.success(sanitize(trimmed));
  }

  /// Validate marketplace listing description
  static ValidationResult validateListingDescription(String description) {
    final trimmed = description.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Listing description cannot be empty');
    }
    
    if (trimmed.length < 10) {
      return ValidationResult.error('Listing description must be at least 10 characters');
    }
    
    if (trimmed.length > 2000) {
      return ValidationResult.error('Listing description must be 2000 characters or less');
    }
    
    return ValidationResult.success(sanitize(trimmed));
  }

  /// Validate price (must be positive)
  static ValidationResult<double> validatePrice(double price) {
    if (price < 0) {
      return ValidationResult.error('Price cannot be negative');
    }
    
    if (price > 1000000) {
      return ValidationResult.error('Price is unreasonably high');
    }
    
    return ValidationResult.success(price);
  }

  // ─── User Profile Validation ──────────────────────────────────────────────

  /// Validate display name
  static ValidationResult validateDisplayName(String name) {
    final trimmed = name.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Display name cannot be empty');
    }
    
    if (trimmed.length < 2) {
      return ValidationResult.error('Display name must be at least 2 characters');
    }
    
    if (trimmed.length > 50) {
      return ValidationResult.error('Display name must be 50 characters or less');
    }
    
    if (_containsSuspiciousPatterns(trimmed)) {
      return ValidationResult.error('Display name contains invalid characters');
    }
    
    return ValidationResult.success(sanitize(trimmed));
  }

  /// Validate bio/about text
  static ValidationResult validateBio(String bio) {
    final trimmed = bio.trim();
    
    if (trimmed.length > 500) {
      return ValidationResult.error('Bio must be 500 characters or less');
    }
    
    return ValidationResult.success(sanitize(trimmed));
  }

  /// Validate URL
  static ValidationResult validateUrl(String url) {
    final trimmed = url.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.success('');
    }
    
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlPattern.hasMatch(trimmed)) {
      return ValidationResult.error('Invalid URL format');
    }
    
    if (trimmed.length > 500) {
      return ValidationResult.error('URL is too long');
    }
    
    return ValidationResult.success(trimmed);
  }

  // ─── Provider Validation ──────────────────────────────────────────────────

  /// Validate business name
  static ValidationResult validateBusinessName(String name) {
    final trimmed = name.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Business name cannot be empty');
    }
    
    if (trimmed.length < 2) {
      return ValidationResult.error('Business name must be at least 2 characters');
    }
    
    if (trimmed.length > 100) {
      return ValidationResult.error('Business name must be 100 characters or less');
    }
    
    return ValidationResult.success(sanitize(trimmed));
  }

  /// Validate phone number (basic)
  static ValidationResult validatePhoneNumber(String phone) {
    final trimmed = phone.trim();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Phone number cannot be empty');
    }
    
    // Remove common formatting characters
    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    if (cleaned.length < 7 || cleaned.length > 15) {
      return ValidationResult.error('Invalid phone number length');
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return ValidationResult.error('Phone number contains invalid characters');
    }
    
    return ValidationResult.success(trimmed);
  }

  // ─── Helper Methods ───────────────────────────────────────────────────────

  /// Check for suspicious patterns (script tags, SQL injection attempts, etc.)
  static bool _containsSuspiciousPatterns(String input) {
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'onerror=', caseSensitive: false),
      RegExp(r'onclick=', caseSensitive: false),
      RegExp(r'onload=', caseSensitive: false),
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'eval\(', caseSensitive: false),
      RegExp(r'expression\(', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'onmouseover=', caseSensitive: false),
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }
    
    return false;
  }

  /// Validate email format (basic)
  static ValidationResult validateEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    
    if (trimmed.isEmpty) {
      return ValidationResult.error('Email cannot be empty');
    }
    
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailPattern.hasMatch(trimmed)) {
      return ValidationResult.error('Invalid email format');
    }
    
    if (trimmed.length > 254) {
      return ValidationResult.error('Email is too long');
    }
    
    return ValidationResult.success(trimmed);
  }
}

// ─── Validation Result ────────────────────────────────────────────────────────

class ValidationResult<T> {
  final bool isValid;
  final String? errorMessage;
  final T? value;

  ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.value,
  });

  factory ValidationResult.success(T value) {
    return ValidationResult._(
      isValid: true,
      value: value,
    );
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }

  /// Throws an exception if validation failed
  T getOrThrow() {
    if (!isValid) {
      throw ValidationException(errorMessage ?? 'Validation failed');
    }
    return value as T;
  }
}

// ─── Validation Exception ─────────────────────────────────────────────────────

class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
