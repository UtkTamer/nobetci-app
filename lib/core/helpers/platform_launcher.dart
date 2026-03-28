import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../../features/pharmacies/domain/pharmacy.dart';

class PlatformLauncher {
  const PlatformLauncher._();

  static Future<void> callPhone(String phoneNumber) async {
    // TODO(api): Track failed launch attempts when analytics is introduced.
    final phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openDirections(Pharmacy pharmacy) async {
    // TODO(api): Prefer backend-provided deep links if different providers are supported.
    final lat = pharmacy.latitude;
    final lng = pharmacy.longitude;
    final label = Uri.encodeComponent(pharmacy.name);

    final preferredUri = Platform.isIOS
        ? Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&q=$label')
        : Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');

    final didLaunchPreferred = await launchUrl(
      preferredUri,
      mode: LaunchMode.externalApplication,
    );

    if (didLaunchPreferred) {
      return;
    }

    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }
}
