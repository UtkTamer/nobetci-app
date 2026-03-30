import '../models/pharmacy_feed.dart';

abstract class PharmacyRepository {
  const PharmacyRepository();

  Future<List<String>> fetchCities();

  Future<PharmacyFeed> fetchOnDutyPharmacies(String city);
}
