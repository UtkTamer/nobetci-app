import '../models/city_option.dart';
import '../models/pharmacy_feed.dart';

abstract class PharmacyRepository {
  const PharmacyRepository();

  Future<List<CityOption>> fetchCities();

  Future<PharmacyFeed> fetchOnDutyPharmacies(String citySlug);
}
