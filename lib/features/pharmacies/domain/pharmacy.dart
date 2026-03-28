import 'package:latlong2/latlong.dart';

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.distanceKm,
    required this.lastVerifiedAt,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final double distanceKm;
  final DateTime lastVerifiedAt;
  final double latitude;
  final double longitude;

  LatLng get location => LatLng(latitude, longitude);
}
