import 'package:flutter/material.dart';

import '../../core/services/location_service.dart';
import '../../features/home/presentation/pages/home_screen.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required LocationService locationService,
  }) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => HomeScreen(locationService: locationService),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => HomeScreen(locationService: locationService),
          settings: settings,
        );
    }
  }
}
