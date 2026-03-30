import 'package:flutter/material.dart';

import '../core/services/location_service.dart';
import '../features/pharmacies/data/repositories/pharmacy_repository.dart';
import '../features/pharmacies/data/repositories/remote_pharmacy_repository.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class NobetciApp extends StatelessWidget {
  NobetciApp({
    this.locationService = const GeolocatorLocationService(),
    PharmacyRepository? pharmacyRepository,
    super.key,
  }) : pharmacyRepository = pharmacyRepository ?? RemotePharmacyRepository();

  final LocationService locationService;
  final PharmacyRepository pharmacyRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nobetci',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(
            settings,
            locationService: locationService,
            pharmacyRepository: pharmacyRepository,
          ),
      initialRoute: AppRouter.home,
    );
  }
}
