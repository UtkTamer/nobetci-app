import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nobetci_app/app/app.dart';
import 'package:nobetci_app/core/services/location_service.dart';
import 'package:nobetci_app/features/pharmacies/data/repositories/mock_api_pharmacy_repository.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationService implements LocationService {
  const _FakeLocationService(this.location);

  final LatLng location;

  @override
  Future<LatLng> determinePosition() async => location;
}

void main() {
  testWidgets('home screen renders pharmacy list', (tester) async {
    await tester.pumpWidget(
      NobetciApp(pharmacyRepository: const MockApiPharmacyRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('city_dropdown')), findsOneWidget);
    expect(find.text('Ankara'), findsWidgets);
    expect(find.text('Merkez Eczanesi'), findsWidgets);
    expect(find.text('Ankara için 3 eczane listeleniyor'), findsOneWidget);
    expect(find.text('Açık Eczaneler'), findsOneWidget);
    expect(find.text('Eczane ara'), findsOneWidget);
    expect(find.text('Son güncelleme: 30.03.2026 09:00'), findsOneWidget);
  });

  testWidgets('pharmacy list can be searched', (tester) async {
    await tester.pumpWidget(
      NobetciApp(pharmacyRepository: const MockApiPharmacyRepository()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'olmayan');
    await tester.pumpAndSettle();

    expect(find.text('Aramaya uygun eczane bulunamadı.'), findsOneWidget);
  });

  testWidgets('city dropdown switches to another city feed', (tester) async {
    await tester.pumpWidget(
      NobetciApp(pharmacyRepository: const MockApiPharmacyRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('city_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İzmir').last);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('İzmir için 3 eczane listeleniyor'), findsOneWidget);
    expect(find.text('İzmir Merkez Mah. Sağlık Cad. No:42'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('map_marker_izmir-merkez')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('İzmir Merkez Mah. Sağlık Cad. No:42'), findsOneWidget);
  });

  testWidgets('tapping a map marker expands and opens pharmacy details', (
    tester,
  ) async {
    await tester.pumpWidget(
      NobetciApp(pharmacyRepository: const MockApiPharmacyRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('map_marker_ankara-merkez')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Ankara Merkez Mah. Sağlık Cad. No:42'), findsOneWidget);
    expect(find.text('Son doğrulama: 30.03.2026 08:45'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('Yol Tarifi'), findsOneWidget);
  });

  testWidgets('location button centers map and shows user point', (
    tester,
  ) async {
    await tester.pumpWidget(
      NobetciApp(
        locationService: _FakeLocationService(LatLng(40.9899, 29.0301)),
        pharmacyRepository: MockApiPharmacyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('locate_me_button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('user_location_marker')), findsOneWidget);
  });
}
