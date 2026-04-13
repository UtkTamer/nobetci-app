import 'package:flutter/material.dart';

import '../../../../core/helpers/platform_launcher.dart';

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  static const _cartoUrl = 'https://carto.com/attributions';
  static const _osmLegalUrl = 'https://www.openstreetmap.org/copyright';

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFFE2E8F0),
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => PlatformLauncher.openExternalUrl(_cartoUrl),
              child: Text(
                '© CARTO',
                style: textStyle?.copyWith(color: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => PlatformLauncher.openExternalUrl(_osmLegalUrl),
              child: Text(
                '© OpenStreetMap',
                style: textStyle?.copyWith(
                  color: const Color(0xFFBFDBFE),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFBFDBFE),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
