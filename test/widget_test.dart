import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nobetci_app/app/app.dart';
import 'package:nobetci_app/core/services/location_service.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationService implements LocationService {
  const _FakeLocationService(this.location);

  final LatLng location;

  @override
  Future<LatLng> determinePosition() async => location;
}

void main() {
  testWidgets('home screen renders pharmacy list', (tester) async {
    await tester.pumpWidget(const NobetciApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('city_dropdown')), findsOneWidget);
    expect(find.text('İstanbul'), findsWidgets);
    expect(find.text('Merkez Eczanesi'), findsWidgets);
    expect(find.text('0.6 km'), findsOneWidget);
    expect(find.text('Açık Eczaneler'), findsOneWidget);
    expect(find.text('Eczane ara'), findsOneWidget);
    expect(
      find.text('Osmanağa Mah. Söğütlüçeşme Cad. No:42 Kadıköy / İstanbul'),
      findsNothing,
    );
    expect(find.text('Son doğrulama: 27.03.2026 00:45'), findsNothing);
    expect(
      find.text('Caferağa Mah. Moda Cad. No:118 Kadıköy / İstanbul'),
      findsNothing,
    );
  });

  testWidgets('pharmacy list can be searched', (tester) async {
    await tester.pumpWidget(const NobetciApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'olmayan');
    await tester.pumpAndSettle();

    expect(find.text('Aramaya uygun eczane bulunamadı.'), findsOneWidget);
  });

  testWidgets('tapping a map marker expands and opens pharmacy details', (
    tester,
  ) async {
    await tester.pumpWidget(const NobetciApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('map_marker_kadikoy-merkez')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('Osmanağa Mah. Söğütlüçeşme Cad. No:42 Kadıköy / İstanbul'),
      findsOneWidget,
    );
    expect(find.text('Son doğrulama: 27.03.2026 00:45'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('Yol Tarifi'), findsOneWidget);
  });

  testWidgets('location button centers map and shows user point', (
    tester,
  ) async {
    await tester.pumpWidget(
      const NobetciApp(
        locationService: _FakeLocationService(LatLng(40.9899, 29.0301)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('locate_me_button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('user_location_marker')), findsOneWidget);
  });
}
