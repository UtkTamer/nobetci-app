import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/pharmacy.dart';
import '../models/city_option.dart';
import '../models/pharmacy_feed.dart';
import 'pharmacy_repository.dart';

class RemotePharmacyRepository extends PharmacyRepository {
  RemotePharmacyRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'NOBETCI_API_BASE_URL',
            defaultValue: 'https://utktamer.github.io/nobetci-app/api',
          );

  final http.Client _client;
  final String _baseUrl;

  static const _citiesCacheKey = '_cache_cities';
  static const _pharmacyCachePrefix = '_cache_pharmacies_';

  @override
  Future<List<CityOption>> fetchCities() async {
    try {
      final uri = Uri.parse('$_baseUrl/cities.json');
      final response = await _get(uri);

      if (response.statusCode != 200) {
        throw _mapException(response.statusCode);
      }

      final cities = _parseCities(response.body);
      await _saveToCache(_citiesCacheKey, response.body);
      return cities;
    } catch (_) {
      final cached = await _loadFromCache(_citiesCacheKey);
      if (cached != null) return _parseCities(cached);
      rethrow;
    }
  }

  @override
  Future<PharmacyFeed> fetchOnDutyPharmacies(String citySlug) async {
    final cacheKey = '$_pharmacyCachePrefix$citySlug';

    try {
      final uri = Uri.parse('$_baseUrl/$citySlug.json');
      final response = await _get(uri);

      if (response.statusCode != 200) {
        throw _mapException(response.statusCode);
      }

      final feed = _parseFeed(response.body, citySlug);
      await _saveToCache(cacheKey, response.body);
      return feed;
    } catch (_) {
      final cached = await _loadFromCache(cacheKey);
      if (cached != null) {
        return _parseFeed(cached, citySlug, forceStale: true);
      }
      rethrow;
    }
  }

  List<CityOption> _parseCities(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const PharmacyRepositoryException(
        'Şehir listesi formatı geçersiz.',
      );
    }

    return decoded.whereType<Map<String, dynamic>>().map((item) {
      final slug = item['slug'] as String?;
      final name = item['name'] as String?;
      if (slug == null || name == null) {
        throw const PharmacyRepositoryException(
          'Şehir listesi formatı geçersiz.',
        );
      }

      return CityOption(slug: slug, name: name);
    }).toList();
  }

  PharmacyFeed _parseFeed(
    String body,
    String citySlug, {
    bool forceStale = false,
  }) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const PharmacyRepositoryException(
        'Eczane verisi formatı geçersiz.',
      );
    }

    final pharmaciesJson = decoded['pharmacies'];
    if (pharmaciesJson is! List) {
      throw const PharmacyRepositoryException(
        'Eczane listesi formatı geçersiz.',
      );
    }

    return PharmacyFeed(
      city: decoded['cityDisplayName'] as String? ?? citySlug,
      updatedAt: DateTime.parse(decoded['updatedAt'] as String),
      isStale: forceStale || (decoded['isStale'] as bool? ?? false),
      pharmacies: pharmaciesJson
          .whereType<Map<String, dynamic>>()
          .map(_pharmacyFromJson)
          .toList(),
    );
  }

  Pharmacy _pharmacyFromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? 'Telefon bilgisi yok',
      district: json['district'] as String? ?? '',
      distanceKm: 0,
      lastVerifiedAt: DateTime.parse(
        json['lastVerifiedAt'] as String? ?? json['updatedAt'] as String,
      ),
      dutyStart: DateTime.tryParse(json['dutyStart'] as String? ?? ''),
      dutyEnd: DateTime.tryParse(json['dutyEnd'] as String? ?? ''),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      source: json['source'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
    );
  }

  Future<void> _saveToCache(String key, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, body);
    } catch (_) {
      // Cache yazma hatası kritik değil, sessizce geç.
    }
  }

  Future<String?> _loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> _get(Uri uri) async => _client.get(uri);

  PharmacyRepositoryException _mapException(int statusCode) {
    return const PharmacyRepositoryException(
      'Nöbetçi eczane verisi alınamadı. Lütfen tekrar deneyin.',
    );
  }
}

class PharmacyRepositoryException implements Exception {
  const PharmacyRepositoryException(this.message);

  final String message;
}
