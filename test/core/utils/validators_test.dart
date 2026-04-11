/// Unit tests for AppValidators
/// Tests all validator functions with valid and invalid inputs
/// These are widget tests because validators now require BuildContext for l10n

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cykel/core/utils/validators.dart';
import 'package:cykel/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget(Widget Function(BuildContext) builder) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) => Scaffold(body: builder(context))),
    );
  }

  group('AppValidators', () {
    group('email', () {
      testWidgets('returns null for valid emails', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.email(context);
          expect(validator('test@example.com'), isNull);
          expect(validator('user@domain.co'), isNull);
          expect(validator('  valid@email.com  '), isNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid emails', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.email(context);
          expect(validator(null), isNotNull);
          expect(validator(''), isNotNull);
          expect(validator('   '), isNotNull);
          expect(validator('notanemail'), isNotNull);
          expect(validator('missing@domain'), isNotNull);
          expect(validator('@example.com'), isNotNull);
          expect(validator('test@'), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('password', () {
      testWidgets('returns null for valid passwords', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.password(context);
          expect(validator('12345678'), isNull);
          expect(validator('longerpassword'), isNull);
          expect(validator('Complex!Pass123'), isNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid passwords', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.password(context);
          expect(validator(null), isNotNull);
          expect(validator(''), isNotNull);
          expect(validator('1234567'), isNotNull); // Less than 8 chars
          expect(validator('short'), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('confirmPassword', () {
      testWidgets('returns null when passwords match', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.confirmPassword(context, 'password123');
          expect(validator('password123'), isNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error when passwords do not match', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.confirmPassword(context, 'password123');
          expect(validator('password456'), isNotNull);
          expect(validator('TEST'), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error when confirm password is empty', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.confirmPassword(context, 'password');
          expect(validator(null), isNotNull);
          expect(validator(''), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('name', () {
      testWidgets('returns null for valid names', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.name(context);
          expect(validator('John'), isNull);
          expect(validator('Jane Doe'), isNull);
          expect(validator('Lars Nielsen'), isNull);
          expect(validator('  Trimmed  '), isNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid names', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.name(context);
          expect(validator(null), isNotNull);
          expect(validator(''), isNotNull);
          expect(validator('   '), isNotNull);
          expect(validator('A'), isNotNull);
          expect(validator(' B '), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('danishPhone', () {
      testWidgets('returns null for valid Danish phone numbers', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.danishPhone(context);
          expect(validator('23456789'), isNull);
          expect(validator('87654321'), isNull);
          expect(validator('4523456789'), isNull);
          expect(validator('+4523456789'), isNull);
          expect(validator('23 45 67 89'), isNull);
          expect(validator('23-45-67-89'), isNull);
          expect(validator(null), isNull); // Optional
          expect(validator(''), isNull); // Optional
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid Danish phone numbers', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.danishPhone(context);
          expect(validator('1234567'), isNotNull); // Too short
          expect(validator('123456789'), isNotNull); // Too long
          expect(validator('02345678'), isNotNull); // Starts with 0
          expect(validator('12345678'), isNotNull); // Starts with 1
          expect(validator('abcd1234'), isNotNull); // Contains letters
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('danishPostalCode', () {
      testWidgets('returns null for valid postal codes', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.danishPostalCode(context);
          expect(validator('1000'), isNull);
          expect(validator('2100'), isNull);
          expect(validator('8000'), isNull);
          expect(validator('9990'), isNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid postal codes', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.danishPostalCode(context);
          expect(validator(null), isNotNull);
          expect(validator(''), isNotNull);
          expect(validator('999'), isNotNull);
          expect(validator('10000'), isNotNull);
          expect(validator('abcd'), isNotNull);
          expect(validator('0999'), isNotNull);
          expect(validator('9991'), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('required', () {
      testWidgets('returns null for non-empty values', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.required(context);
          expect(validator('value'), isNull);
          expect(validator('test'), isNull);
          expect(validator(' non-empty '), isNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for empty values', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.required(context);
          expect(validator(null), isNotNull);
          expect(validator(''), isNotNull);
          expect(validator('   '), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('price', () {
      testWidgets('returns null for valid prices', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.price(context);
          expect(validator('0'), isNull);
          expect(validator('100'), isNull);
          expect(validator('1234.56'), isNull);
          expect(validator('999999'), isNull);
          expect(validator('100,00'), isNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid prices', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.price(context);
          expect(validator(null), isNotNull);
          expect(validator(''), isNotNull);
          expect(validator('-10'), isNotNull);
          expect(validator('abc'), isNotNull);
          expect(validator('1000000'), isNotNull);
          expect(validator('9999999'), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('serialNumber', () {
      testWidgets('returns null for valid serial numbers', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.serialNumber(context);
          expect(validator('1234'), isNull);
          expect(validator('ABC123XYZ'), isNull);
          expect(validator('A' * 50), isNull);
          expect(validator(null), isNull); // Optional
          expect(validator(''), isNull); // Optional
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid serial numbers', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.serialNumber(context);
          expect(validator('123'), isNotNull);
          expect(validator('ABC'), isNotNull);
          expect(validator('   '), isNotNull);
          expect(validator('A' * 51), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });

    group('url', () {
      testWidgets('returns null for valid URLs', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.url(context);
          expect(validator('https://example.com'), isNull);
          expect(validator('http://test.org'), isNull);
          expect(validator('https://sub.domain.com/path'), isNull);
          expect(validator('http://localhost:8080'), isNull);
          expect(validator('https://example.com/path/to/page?query=1'), isNull);
          expect(validator(null), isNull); // Optional
          expect(validator(''), isNull); // Optional
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });

      testWidgets('returns error for invalid URLs', (tester) async {
        await tester.pumpWidget(buildTestWidget((context) {
          final validator = AppValidators.url(context);
          expect(validator('not-a-url'), isNotNull);
          expect(validator('ftp://example.com'), isNotNull);
          expect(validator('example.com'), isNotNull);
          expect(validator('http://'), isNotNull);
          return const SizedBox();
        }));
        await tester.pumpAndSettle();
      });
    });
  });
}
