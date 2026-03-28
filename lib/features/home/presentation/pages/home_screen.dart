import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/helpers/platform_launcher.dart';
import '../../../../core/services/location_service.dart';
import '../../../pharmacies/data/mock_pharmacy_repository.dart';
import '../../../pharmacies/domain/pharmacy.dart';
import '../../../pharmacies/presentation/widgets/pharmacy_bottom_sheet.dart';
import '../widgets/home_map_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.locationService = const GeolocatorLocationService(),
    super.key,
  });

  final LocationService locationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = const MockPharmacyRepository();
  final _mapController = MapController();
  final _sheetController = PharmacyBottomSheetController();
  late final List<Pharmacy> _pharmacies;
  late final Pharmacy _nearestPharmacy;
  double _mapViewportHeight = 0;
  double _sheetExtent = AppConstants.initialSheetSize;
  double _mapDragDistance = 0;
  String? _selectedPharmacyId;
  LatLng? _userLocation;
  bool _isLocatingUser = false;

  @override
  void initState() {
    super.initState();
    _pharmacies = _repository.getPharmacies();
    _pharmacies.sort(
      (left, right) => left.distanceKm.compareTo(right.distanceKm),
    );
    _nearestPharmacy = _pharmacies.first;
  }

  void _onPharmacySelected(String pharmacyId) {
    final isSamePharmacy = _selectedPharmacyId == pharmacyId;
    final nextSelectedPharmacyId = isSamePharmacy ? null : pharmacyId;

    setState(() {
      _selectedPharmacyId = nextSelectedPharmacyId;
    });

    if (nextSelectedPharmacyId == null) {
      _sheetController.collapseToInitial(AppConstants.initialSheetSize);
      return;
    }

    final selectedPharmacy = _pharmacies.firstWhere(
      (pharmacy) => pharmacy.id == nextSelectedPharmacyId,
    );
    final visibleMapCenterOffset = Offset(
      0,
      -(_mapViewportHeight * AppConstants.initialSheetSize) / 2,
    );
    _mapController.move(
      selectedPharmacy.location,
      AppConstants.focusZoom,
      offset: visibleMapCenterOffset,
    );
    _sheetController.expandToMax(AppConstants.maxSheetSize);
  }

  Future<void> _centerOnUserLocation() async {
    if (_isLocatingUser) {
      return;
    }

    setState(() {
      _isLocatingUser = true;
    });

    try {
      final currentLocation = await widget.locationService.determinePosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = currentLocation;
      });

      _mapController.move(currentLocation, AppConstants.userLocationZoom);
    } on LocationFailure catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum alinirken bir sorun olustu.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            _mapViewportHeight = constraints.maxHeight;
            final sheetInset = constraints.maxHeight * _sheetExtent;
            final isSheetExpanded =
                _sheetExtent > AppConstants.initialSheetSize + 0.02;
            final showMapAttribution = !isSheetExpanded;

            return Stack(
              children: [
                HomeMapSection(
                  mapController: _mapController,
                  pharmacies: _pharmacies,
                  selectedPharmacyId: _selectedPharmacyId,
                  userLocation: _userLocation,
                  onPharmacySelected: _onPharmacySelected,
                ),
                Positioned(
                  left: 12,
                  bottom: sheetInset + 10,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    opacity: showMapAttribution ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !showMapAttribution,
                      child: const _MapAttribution(),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: sheetInset + 10,
                  child: _LocateMeButton(
                    isLoading: _isLocatingUser,
                    onPressed: _centerOnUserLocation,
                  ),
                ),
                if (isSheetExpanded)
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: sheetInset,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragStart: (_) {
                        _mapDragDistance = 0;
                      },
                      onVerticalDragUpdate: (details) {
                        final delta = details.primaryDelta ?? 0;
                        if (delta <= 0) {
                          return;
                        }

                        _mapDragDistance += delta;
                        if (_mapDragDistance > 16) {
                          _mapDragDistance = 0;
                          _sheetController.collapseToInitial(
                            AppConstants.initialSheetSize,
                          );
                        }
                      },
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yakindaki Nobetci Eczaneler',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_pharmacies.length} eczane listeleniyor',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFCBD5E1)),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF020617,
                              ).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Chip(
                              side: BorderSide.none,
                              backgroundColor: Colors.transparent,
                              label: Text(
                                '${_nearestPharmacy.distanceKm.toStringAsFixed(1)} km uzakta',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PharmacyBottomSheet(
                  controller: _sheetController,
                  pharmacies: _pharmacies,
                  selectedPharmacyId: _selectedPharmacyId,
                  onPharmacySelected: _onPharmacySelected,
                  minChildSize: AppConstants.minSheetSize,
                  initialChildSize: AppConstants.initialSheetSize,
                  maxChildSize: AppConstants.maxSheetSize,
                  onExtentChanged: (extent) {
                    if (_sheetExtent == extent) {
                      return;
                    }

                    setState(() {
                      _sheetExtent = extent;
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  static const _legalUrl = 'https://www.openstreetmap.org/copyright';

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('© OpenStreetMap', style: textStyle),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => PlatformLauncher.openExternalUrl(_legalUrl),
              child: Text(
                'Legal',
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

class _LocateMeButton extends StatelessWidget {
  const _LocateMeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('locate_me_button'),
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF020617).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('locate_loading'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF38BDF8),
                        ),
                      ),
                    )
                  : const Icon(
                      key: ValueKey('locate_icon'),
                      Icons.near_me_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
