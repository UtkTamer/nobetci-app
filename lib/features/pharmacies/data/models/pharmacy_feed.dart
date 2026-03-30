import '../../domain/pharmacy.dart';

class PharmacyFeed {
  const PharmacyFeed({
    required this.city,
    required this.updatedAt,
    required this.isStale,
    required this.pharmacies,
  });

  final String city;
  final DateTime updatedAt;
  final bool isStale;
  final List<Pharmacy> pharmacies;
}
