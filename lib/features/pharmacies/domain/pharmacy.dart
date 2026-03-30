import 'package:latlong2/latlong.dart';

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.district,
    required this.distanceKm,
    required this.lastVerifiedAt,
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.sourceUrl,
    this.dutyStart,
    this.dutyEnd,
  });

  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final String district;
  final double distanceKm;
  final DateTime lastVerifiedAt;
  final DateTime? dutyStart;
  final DateTime? dutyEnd;
  final double? latitude;
  final double? longitude;
  final String source;
  final String sourceUrl;

  bool get hasCoordinates => latitude != null && longitude != null;

  LatLng get location => LatLng(latitude!, longitude!);

  Pharmacy copyWith({
    double? distanceKm,
  }) {
    return Pharmacy(
      id: id,
      name: name,
      address: address,
      phoneNumber: phoneNumber,
      district: district,
      distanceKm: distanceKm ?? this.distanceKm,
      lastVerifiedAt: lastVerifiedAt,
      dutyStart: dutyStart,
      dutyEnd: dutyEnd,
      latitude: latitude,
      longitude: longitude,
      source: source,
      sourceUrl: sourceUrl,
    );
  }
}
