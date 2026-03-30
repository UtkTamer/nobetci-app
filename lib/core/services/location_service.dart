import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationFailure implements Exception {
  const LocationFailure(this.message);

  final String message;
}

abstract class LocationService {
  Future<LatLng> determinePosition();
}

class FixedLocationService implements LocationService {
  const FixedLocationService(this.location);

  final LatLng location;

  @override
  Future<LatLng> determinePosition() async => location;
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LatLng> determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure('Konum servisleri kapalı.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure('Konum izni verilmedi.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Konum izni kalici olarak reddedildi. Ayarlardan izin verebilirsiniz.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }
}
