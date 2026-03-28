import 'package:flutter/material.dart';

import '../core/services/location_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class NobetciApp extends StatelessWidget {
  const NobetciApp({
    this.locationService = const GeolocatorLocationService(),
    super.key,
  });

  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nobetci',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, locationService: locationService),
      initialRoute: AppRouter.home,
    );
  }
}
