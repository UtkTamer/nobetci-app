import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/pharmacy.dart';
import '../models/pharmacy_feed.dart';
import 'pharmacy_repository.dart';

class RemotePharmacyRepository extends PharmacyRepository {
  RemotePharmacyRepository({
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'NOBETCI_API_BASE_URL',
             defaultValue: 'http://localhost:3000',
           );

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<String>> fetchCities() async {
    final uri = Uri.parse('$_baseUrl/cities');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw const PharmacyRepositoryException(
        'Şehir listesi alınamadı. Lütfen tekrar deneyin.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const PharmacyRepositoryException('Şehir listesi formatı geçersiz.');
    }

    return decoded
        .map((item) => item is Map<String, dynamic> ? item['name'] : null)
        .whereType<String>()
        .toList();
  }

  @override
  Future<PharmacyFeed> fetchOnDutyPharmacies(String city) async {
    final citySlug = _slugify(city);
    final uri = Uri.parse('$_baseUrl/pharmacies/on-duty?city=$citySlug');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw const PharmacyRepositoryException(
        'Nöbetçi eczane verisi alınamadı. Lütfen tekrar deneyin.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const PharmacyRepositoryException('Eczane verisi formatı geçersiz.');
    }

    final pharmaciesJson = decoded['pharmacies'];
    if (pharmaciesJson is! List) {
      throw const PharmacyRepositoryException('Eczane listesi formatı geçersiz.');
    }

    return PharmacyFeed(
      city: decoded['cityDisplayName'] as String? ?? city,
      updatedAt: DateTime.parse(decoded['updatedAt'] as String),
      isStale: decoded['isStale'] as bool? ?? false,
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

  String _slugify(String value) {
    const replacements = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'c',
      'Ğ': 'g',
      'İ': 'i',
      'Ö': 'o',
      'Ş': 's',
      'Ü': 'u',
    };

    final normalized = value
        .split('')
        .map((char) => replacements[char] ?? char)
        .join()
        .toLowerCase();

    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-').trim();
  }
}

class PharmacyRepositoryException implements Exception {
  const PharmacyRepositoryException(this.message);

  final String message;
}
