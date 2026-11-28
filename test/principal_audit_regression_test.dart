import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mashwar/core/config/app_environment.dart';
import 'package:mashwar/core/localization/app_strings.dart';
import 'package:mashwar/data/services/media_upload_service.dart';
import 'package:mashwar/data/services/qatar_city_matcher.dart';
import 'package:mashwar/state/admin_provider.dart';
import 'package:mashwar/state/parcels_provider.dart';

void main() {
  final arabicCharRegex = RegExp(r'[\u0600-\u06FF]');

  group('1. AppStrings Date & Admin Status Localization Regression', () {
    test('translateDate preserves صباحاً, مساءً, and الخميس without corrupting ص/م inside words', () {
      final morningEn = AppStrings.translateDate('الخميس صباحاً 8:30 ص', isArabic: false);
      expect(morningEn, contains('Thu'));
      expect(morningEn, contains('صباحاً'));
      expect(morningEn, contains('8:30 AM'));
      expect(morningEn, isNot(contains('AMباحاً')));
      expect(morningEn, isNot(contains('الخميس')));
      expect(morningEn, isNot(contains('PM')));

      final eveningEn = AppStrings.translateDate('الخميس مساءً 7:45 م', isArabic: false);
      expect(eveningEn, contains('Thu'));
      expect(eveningEn, contains('مساءً'));
      expect(eveningEn, contains('7:45 PM'));
      expect(eveningEn, isNot(contains('PMساءً')));
      expect(eveningEn, isNot(contains('الخPMيس')));
    });

    test('translateDate translates all 12 months in both AR -> EN and EN -> AR', () {
      const arToEnMonths = <String, String>{
        'يناير': 'Jan',
        'فبراير': 'Feb',
        'مارس': 'Mar',
        'أبريل': 'Apr',
        'مايو': 'May',
        'يونيو': 'Jun',
        'يوليو': 'Jul',
        'أغسطس': 'Aug',
        'سبتمبر': 'Sep',
        'أكتوبر': 'Oct',
        'نوفمبر': 'Nov',
        'ديسمبر': 'Dec',
      };

      for (final entry in arToEnMonths.entries) {
        final en = AppStrings.translateDate('15 ${entry.key} 2026', isArabic: false);
        expect(en, equals('15 ${entry.value} 2026'), reason: 'AR->EN failed for ${entry.key}');
        expect(arabicCharRegex.hasMatch(en), isFalse);

        final backToAr = AppStrings.translateDate(en, isArabic: true);
        expect(backToAr, equals('15 ${entry.key} 2026'), reason: 'EN->AR failed for ${entry.value}');
      }
    });

    test('translateStatus covers all Admin portal status badges in English mode', () {
      const adminStatuses = <String, String>{
        'مفتوح': 'Open',
        'محلول': 'Resolved',
        'محظور': 'Banned',
        'مرفوض': 'Rejected',
        'مرفوضة': 'Rejected',
        'مقبول': 'Accepted',
        'مقبولة': 'Accepted',
        'منشورة': 'Published',
        'مكتملة الحجز': 'Fully Booked',
        'جارية': 'In Progress',
        'ذروة عالية': 'High Peak',
        'متوقف مؤقتاً': 'Paused',
        'قيد المراجعة': 'Under Review',
        'نشط': 'Active',
        'موقوف': 'Suspended',
      };

      for (final entry in adminStatuses.entries) {
        final translated = AppStrings.translateStatus(entry.key, isArabic: false);
        expect(translated, equals(entry.value), reason: 'Status failed: ${entry.key}');
        expect(arabicCharRegex.hasMatch(translated), isFalse);
      }
    });
  });

  group('2. MediaUploadService Raster MIME Allowlist & SVG Blocking', () {
    final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final webpBytes = Uint8List.fromList([
      0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00,
      0x57, 0x45, 0x42, 0x50,
    ]);
    final svgBytes = Uint8List.fromList(utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'));

    test('rejects image/svg+xml by explicit MIME and by .svg extension', () {
      expect(
        () => MediaUploadService.resolveAndValidateImageMime(
          bytes: svgBytes,
          fileName: 'payload.svg',
          explicitMimeType: 'image/svg+xml',
        ),
        throwsA(
          isA<MediaUploadException>().having((e) => e.code, 'code', 'invalid-mime-type'),
        ),
      );

      expect(
        () => MediaUploadService.resolveAndValidateImageMime(
          bytes: svgBytes,
          fileName: 'payload.svg',
        ),
        throwsA(
          isA<MediaUploadException>().having((e) => e.code, 'code', 'invalid-mime-type'),
        ),
      );
    });

    test('allows raster image/jpeg, image/png, and image/webp via explicit MIME, extension, and magic bytes', () {
      expect(
        MediaUploadService.resolveAndValidateImageMime(
          bytes: jpegBytes,
          fileName: 'receipt.jpg',
          explicitMimeType: 'image/jpeg',
        ),
        equals('image/jpeg'),
      );
      expect(
        MediaUploadService.resolveAndValidateImageMime(
          bytes: pngBytes,
          fileName: 'qid_front.png',
          explicitMimeType: 'image/png',
        ),
        equals('image/png'),
      );
      expect(
        MediaUploadService.resolveAndValidateImageMime(
          bytes: webpBytes,
          fileName: 'proof.webp',
          explicitMimeType: 'image/webp',
        ),
        equals('image/webp'),
      );

      // Magic-byte sniffing fallback when extension & explicit MIME are omitted
      expect(
        MediaUploadService.resolveAndValidateImageMime(bytes: jpegBytes, fileName: 'upload'),
        equals('image/jpeg'),
      );
      expect(
        MediaUploadService.resolveAndValidateImageMime(bytes: pngBytes, fileName: 'upload'),
        equals('image/png'),
      );
      expect(
        MediaUploadService.resolveAndValidateImageMime(bytes: webpBytes, fileName: 'upload'),
        equals('image/webp'),
      );
    });
  });

  group('3. AdminProvider 14-Module RBAC & Zero-Arabic English KPI/Period Helpers', () {
    test('roleHasMenuAccess covers all 14 modules (0..13) across all 5 roles and denies out-of-range', () {
      expect(AdminProvider.modulesCatalog.length, equals(14));
      final catalogIndices = AdminProvider.modulesCatalog.map((m) => m.index).toSet();
      expect(catalogIndices, equals({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}));

      const expectedMatrix = <AdminRole, Set<int>>{
        AdminRole.superAdmin: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13},
        AdminRole.reviewAdmin: {0, 1, 13},
        AdminRole.supportAdmin: {0, 2, 3, 4, 12, 13},
        AdminRole.financeAdmin: {0, 3, 7, 8, 10, 13},
        AdminRole.devopsAdmin: {0, 5, 7, 8, 9, 11},
      };

      for (final role in AdminRole.values) {
        final allowed = expectedMatrix[role]!;
        for (var idx = 0; idx <= 13; idx++) {
          expect(
            AdminProvider.roleHasMenuAccess(role, idx),
            equals(allowed.contains(idx)),
            reason: 'RBAC mismatch for role=$role module=$idx',
          );
        }
        expect(AdminProvider.roleHasMenuAccess(role, -1), isFalse);
        expect(AdminProvider.roleHasMenuAccess(role, 14), isFalse);
      }
    });

    test('periodLabelFor and kpi*For helpers emit zero Arabic in English mode across all periods', () {
      final admin = AdminProvider.forTesting();

      for (final period in const ['اليوم', '7 أيام', '30 يوم']) {
        admin.setPeriod(period);

        final enStrings = [
          admin.periodLabelFor(false),
          admin.kpiNewUsersSubtextFor(false),
          admin.kpiPublishedRidesSubtextFor(false),
          admin.kpiConversionRateFor(false),
          admin.kpiParcelSuccessRateFor(false),
        ];

        for (final text in enStrings) {
          expect(text.trim(), isNotEmpty);
          expect(
            arabicCharRegex.hasMatch(text),
            isFalse,
            reason: 'Arabic leakage in English KPI/period helper for period="$period": "$text"',
          );
        }

        // Arabic mode should produce non-empty localized labels
        expect(admin.periodLabelFor(true).trim(), isNotEmpty);
        expect(admin.kpiConversionRateFor(true), contains('نسبة التحويل'));
        expect(admin.kpiParcelSuccessRateFor(true), contains('نجاح'));
      }
    });
  });

  group('4. ParcelsProvider Live Clean-Slate & QatarCityMatcher Bilingual Consistency', () {
    test('ParcelsProvider does NOT leak MockData.activeParcel when live Firebase mode is active', () {
      addTearDown(() => AppEnvironment.setFirebaseRuntimeActive(false));
      AppEnvironment.setFirebaseRuntimeActive(true);

      final provider = ParcelsProvider();
      expect(provider.parcels, isEmpty);
      expect(provider.activeTrackingParcel, isNull);
      expect(provider.currentTrackingParcel, isNull);
    });

    test('QatarCityMatcher resolves bilingual Qatar hubs consistently', () {
      expect(QatarCityMatcher.areCitiesEquivalent('الدوحة', 'Doha'), isTrue);
      expect(QatarCityMatcher.areCitiesEquivalent('الدوحة', 'West Bay'), isTrue);
      expect(QatarCityMatcher.areCitiesEquivalent('المنطقة الصناعية', 'Industrial Area'), isTrue);
      expect(QatarCityMatcher.areCitiesEquivalent('لوسيل', 'Lusail'), isTrue);
      expect(QatarCityMatcher.areCitiesEquivalent('الخور', 'Al Khor'), isTrue);
      expect(QatarCityMatcher.areCitiesEquivalent('الوكرة', 'Al Wakrah'), isTrue);
      expect(QatarCityMatcher.areCitiesEquivalent('مطار حمد الدولي', 'HIA'), isTrue);
      expect(QatarCityMatcher.areCitiesEquivalent('الدوحة', 'الخور'), isFalse);

      expect(
        QatarCityMatcher.matchesCityField('Industrial Area', ['المنطقة الصناعية — بوابة 4']),
        isTrue,
      );
      expect(
        QatarCityMatcher.matchesCityField('لوسيل', ['Lusail Marina District']),
        isTrue,
      );
      expect(
        QatarCityMatcher.matchesCityField('Al Khor', ['Doha Corniche']),
        isFalse,
      );
    });
  });

  group('5. Vercel Security Headers & Health Metadata Contracts', () {
    test('vercel.json includes HSTS and allows SAMEORIGIN framing on /maps/(.*) and /admin/maps/(.*)', () {
      final file = File('vercel.json');
      expect(file.existsSync(), isTrue);
      final config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final headersList = (config['headers'] as List<dynamic>).cast<Map<String, dynamic>>();

      Map<String, String> headersForSource(String source) {
        final match = headersList.firstWhere(
          (entry) => entry['source'] == source,
          orElse: () => <String, dynamic>{},
        );
        final list = (match['headers'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
        return {
          for (final h in list) h['key'].toString(): h['value'].toString(),
        };
      }

      final globalHeaders = headersForSource('/(.*)');
      expect(globalHeaders['Strict-Transport-Security'], contains('max-age=63072000'));
      expect(globalHeaders['X-Frame-Options'], equals('DENY'));

      for (final mapSource in const ['/maps/(.*)', '/admin/maps/(.*)']) {
        final mapHeaders = headersForSource(mapSource);
        expect(mapHeaders['X-Frame-Options'], equals('SAMEORIGIN'), reason: 'Missing SAMEORIGIN on $mapSource');
        expect(
          mapHeaders['Content-Security-Policy'],
          contains("frame-ancestors 'self'"),
          reason: 'Missing frame-ancestors on $mapSource',
        );
      }
    });

    test('web/health.json reports 14 adminModules and direct-settlement metadata', () {
      final file = File('web/health.json');
      expect(file.existsSync(), isTrue);
      final health = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final security = health['security'] as Map<String, dynamic>;

      expect(health['adminModules'], equals(14));
      expect(security['settlementMode'], equals('direct-cod-and-verified-bank-transfer'));
      expect(security['handoverVerification'], equals('salted-sha256-and-dual-otp'));
      expect(security.containsKey('escrowProtection'), isFalse);
    });
  });
}
