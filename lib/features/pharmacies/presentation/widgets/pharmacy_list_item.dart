import 'package:flutter/material.dart';

import '../../../../core/helpers/platform_launcher.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../domain/pharmacy.dart';

class PharmacyListItem extends StatelessWidget {
  const PharmacyListItem({
    required this.pharmacy,
    required this.isExpanded,
    required this.onTap,
    super.key,
  });

  final Pharmacy pharmacy;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.3,
    );
    final distanceStyle = textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF8E8E93),
      fontWeight: FontWeight.w600,
    );

    return Card(
        color: const Color(0xFF242426),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PharmacyListItemHeader(
                    name: pharmacy.name,
                    distanceLabel: pharmacy.distanceKm.isFinite
                        ? '${pharmacy.distanceKm.toStringAsFixed(1)} km'
                        : 'Konum yok',
                    isExpanded: isExpanded,
                    titleStyle: titleStyle,
                    distanceStyle: distanceStyle,
                  ),
                  ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      reverseDuration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.topCenter,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: isExpanded
                          ? Padding(
                              key: ValueKey(pharmacy.id),
                              padding: const EdgeInsets.only(top: 14),
                              child: _ExpandedPharmacyDetails(
                                pharmacy: pharmacy,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('collapsed')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _PharmacyListItemHeader extends StatelessWidget {
  const _PharmacyListItemHeader({
    required this.name,
    required this.distanceLabel,
    required this.isExpanded,
    required this.titleStyle,
    required this.distanceStyle,
  });

  final String name;
  final String distanceLabel;
  final bool isExpanded;
  final TextStyle? titleStyle;
  final TextStyle? distanceStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(name, style: titleStyle)),
        const SizedBox(width: 12),
        Text(distanceLabel, style: distanceStyle),
        const SizedBox(width: 8),
        AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }
}

class _ExpandedPharmacyDetails extends StatelessWidget {
  const _ExpandedPharmacyDetails({required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pharmacy.address,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFD1D1D6),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          pharmacy.phoneNumber,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        if (pharmacy.district.isNotEmpty) ...[
          Text(
            pharmacy.district,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Son doğrulama: ${DateTimeFormatter.formatShort(pharmacy.lastVerifiedAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8E8E93)),
        ),
        if (pharmacy.source.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Kaynak: ${pharmacy.source}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8E8E93)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2E),
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    PlatformLauncher.callPhone(pharmacy.phoneNumber),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Ara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: const Color(0xFF04130A),
                ),
                onPressed: pharmacy.hasCoordinates
                    ? () => PlatformLauncher.openDirections(pharmacy)
                    : null,
                icon: const Icon(Icons.directions_outlined),
                label: Text(
                  pharmacy.hasCoordinates ? 'Yol Tarifi' : 'Konum Yok',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
