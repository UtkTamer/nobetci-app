import '../domain/pharmacy.dart';

class MockPharmacyRepository {
  const MockPharmacyRepository();

  List<Pharmacy> getPharmacies() {
    // TODO(api): Replace this mock source with a remote pharmacy datasource.
    // TODO(api): Map API response fields into the Pharmacy domain model.
    return [
      Pharmacy(
        id: 'kadikoy-merkez',
        name: 'Merkez Eczanesi',
        address: 'Osmanağa Mah. Söğütlüçeşme Cad. No:42 Kadıköy / İstanbul',
        phoneNumber: '+902163450101',
        district: 'Kadıköy',
        distanceKm: 0.6,
        lastVerifiedAt: DateTime(2026, 3, 27, 0, 45),
        dutyStart: DateTime(2026, 3, 26, 18),
        dutyEnd: DateTime(2026, 3, 27, 8),
        latitude: 40.9906,
        longitude: 29.0287,
        source: 'Mock Data',
        sourceUrl: 'https://example.com/mock',
      ),
      Pharmacy(
        id: 'moda-sifa',
        name: 'Şifa Eczanesi',
        address: 'Caferağa Mah. Moda Cad. No:118 Kadıköy / İstanbul',
        phoneNumber: '+902163450202',
        district: 'Kadıköy',
        distanceKm: 1.1,
        lastVerifiedAt: DateTime(2026, 3, 27, 0, 32),
        dutyStart: DateTime(2026, 3, 26, 18),
        dutyEnd: DateTime(2026, 3, 27, 8),
        latitude: 40.9857,
        longitude: 29.0319,
        source: 'Mock Data',
        sourceUrl: 'https://example.com/mock',
      ),
      Pharmacy(
        id: 'rasimpasa-hayat',
        name: 'Hayat Eczanesi',
        address: 'Rasimpaşa Mah. Karakolhane Cad. No:19 Kadıköy / İstanbul',
        phoneNumber: '+902163450303',
        district: 'Kadıköy',
        distanceKm: 1.8,
        lastVerifiedAt: DateTime(2026, 3, 27, 0, 20),
        dutyStart: DateTime(2026, 3, 26, 18),
        dutyEnd: DateTime(2026, 3, 27, 8),
        latitude: 40.9923,
        longitude: 29.0374,
        source: 'Mock Data',
        sourceUrl: 'https://example.com/mock',
      ),
      Pharmacy(
        id: 'feneryolu-yakamoz',
        name: 'Yakamoz Eczanesi',
        address:
            'Feneryolu Mah. Ahmet Mithat Efendi Cad. No:57 Kadıköy / İstanbul',
        phoneNumber: '+902163450404',
        district: 'Kadıköy',
        distanceKm: 2.4,
        lastVerifiedAt: DateTime(2026, 3, 26, 23, 58),
        dutyStart: DateTime(2026, 3, 26, 18),
        dutyEnd: DateTime(2026, 3, 27, 8),
        latitude: 40.9804,
        longitude: 29.0524,
        source: 'Mock Data',
        sourceUrl: 'https://example.com/mock',
      ),
    ];
  }
}
