import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../pharmacies/domain/pharmacy.dart';

class HomeMapSection extends StatelessWidget {
  const HomeMapSection({
    required this.mapController,
    required this.pharmacies,
    required this.selectedPharmacyId,
    required this.userLocation,
    required this.onPharmacySelected,
    super.key,
  });

  final MapController mapController;
  final List<Pharmacy> pharmacies;
  final String? selectedPharmacyId;
  final LatLng? userLocation;
  final ValueChanged<String> onPharmacySelected;

  @override
  Widget build(BuildContext context) {
    final pharmacyWithCoordinates = pharmacies.where(
      (item) => item.hasCoordinates,
    );
    final center = pharmacyWithCoordinates.isNotEmpty
        ? pharmacyWithCoordinates.first.location
        : const LatLng(39.0, 35.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: AppConstants.defaultZoom,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'com.example.nobetci_app',
              maxZoom: 20,
            ),
            MarkerLayer(
              markers: [
                for (final pharmacy in pharmacies)
                  if (pharmacy.hasCoordinates)
                    Marker(
                      width: 64,
                      height: 64,
                      point: pharmacy.location,
                      child: _MapMarker(
                        key: ValueKey('map_marker_${pharmacy.id}'),
                        label: pharmacy.name,
                        isSelected: pharmacy.id == selectedPharmacyId,
                        onTap: () => onPharmacySelected(pharmacy.id),
                      ),
                    ),
                if (userLocation != null)
                  Marker(
                    width: 64,
                    height: 64,
                    point: userLocation!,
                    child: const _UserLocationMarker(),
                  ),
              ],
            ),
          ],
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF020617).withValues(alpha: 0.28),
                  const Color(0xFF020617).withValues(alpha: 0.08),
                  const Color(0xFF020617).withValues(alpha: 0.38),
                ],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.34),
                radius: 0.95,
                colors: [
                  const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(_controller.value);
        final pulseScale = 0.9 + (progress * 1.6);
        final pulseOpacity = 0.28 * (1 - progress);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: pulseOpacity),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        key: const ValueKey('user_location_marker'),
        width: 28,
        height: 28,
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF38BDF8),
            border: Border.all(color: Colors.white, width: 4),
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? const Color(0xFF38BDF8)
        : const Color(0xFF020617);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66020617),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFBAE6FD).withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ],
      ),
    );
  }
}
