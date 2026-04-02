import '../../domain/pharmacy.dart';
import '../models/city_option.dart';
import '../models/pharmacy_feed.dart';
import 'pharmacy_repository.dart';

class MockApiPharmacyRepository extends PharmacyRepository {
  const MockApiPharmacyRepository();

  static const _cities = [
    CityOption(slug: 'istanbul', name: 'İstanbul'),
    CityOption(slug: 'ankara', name: 'Ankara'),
    CityOption(slug: 'izmir', name: 'İzmir'),
    CityOption(slug: 'bursa', name: 'Bursa'),
    CityOption(slug: 'antalya', name: 'Antalya'),
  ];

  @override
  Future<List<CityOption>> fetchCities() async => _cities;

  @override
  Future<PharmacyFeed> fetchOnDutyPharmacies(String citySlug) async {
    final city =
        _cities.where((option) => option.slug == citySlug).firstOrNull?.name ??
        citySlug;
    final pharmacies = <Pharmacy>[
      Pharmacy(
        id: '$citySlug-merkez',
        name: 'Merkez Eczanesi',
        address: '$city Merkez Mah. Sağlık Cad. No:42',
        phoneNumber: '+902120001111',
        district: 'Merkez',
        distanceKm: 0,
        lastVerifiedAt: DateTime(2026, 3, 30, 8, 45),
        dutyStart: DateTime(2026, 3, 30, 18),
        dutyEnd: DateTime(2026, 3, 31, 8),
        latitude: 40.9906,
        longitude: 29.0287,
        source: '$city Eczacı Odası',
        sourceUrl: 'https://example.com/$citySlug',
      ),
      Pharmacy(
        id: '$citySlug-sifa',
        name: 'Şifa Eczanesi',
        address: '$city Çarşı Mah. Belediye Sok. No:12',
        phoneNumber: '+902120002222',
        district: 'Çarşı',
        distanceKm: 0,
        lastVerifiedAt: DateTime(2026, 3, 30, 8, 30),
        dutyStart: DateTime(2026, 3, 30, 18),
        dutyEnd: DateTime(2026, 3, 31, 8),
        latitude: 40.9857,
        longitude: 29.0319,
        source: '$city Eczacı Odası',
        sourceUrl: 'https://example.com/$citySlug',
      ),
      Pharmacy(
        id: '$citySlug-hayat',
        name: 'Hayat Eczanesi',
        address: '$city Hastane Mah. Acil Sok. No:19',
        phoneNumber: '+902120003333',
        district: 'Hastane',
        distanceKm: 0,
        lastVerifiedAt: DateTime(2026, 3, 30, 8, 20),
        dutyStart: DateTime(2026, 3, 30, 18),
        dutyEnd: DateTime(2026, 3, 31, 8),
        latitude: null,
        longitude: null,
        source: '$city Eczacı Odası',
        sourceUrl: 'https://example.com/$citySlug',
      ),
    ];

    return PharmacyFeed(
      city: city,
      updatedAt: DateTime(2026, 3, 30, 9),
      isStale: false,
      pharmacies: pharmacies,
    );
  }
}
