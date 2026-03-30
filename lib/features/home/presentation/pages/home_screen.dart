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
  static const List<String> _cities = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya',
  ];

  final _repository = const MockPharmacyRepository();
  final _mapController = MapController();
  final _sheetController = PharmacyBottomSheetController();
  late final List<Pharmacy> _pharmacies;
  late final Pharmacy _nearestPharmacy;
  double _mapViewportHeight = 0;
  double _sheetExtent = AppConstants.initialSheetSize;
  double _mapDragDistance = 0;
  String? _selectedPharmacyId;
  String _selectedCity = _cities.first;
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
                        _CityDropdown(
                          value: _selectedCity,
                          items: _cities,
                          onChanged: (city) {
                            if (city == null || city == _selectedCity) {
                              return;
                            }

                            setState(() {
                              _selectedCity = city;
                            });
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_selectedCity için ${_pharmacies.length} eczane listeleniyor',
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

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const dropdownRadius = 22.0;
    final borderRadius = BorderRadius.circular(dropdownRadius);
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.3,
    );
    return IntrinsicWidth(
      child: Builder(
        builder: (context) {
          return Material(
            color: const Color(0xFF242426),
            borderRadius: borderRadius,
            child: InkWell(
              key: const ValueKey('city_dropdown'),
              borderRadius: borderRadius,
              onTap: () async {
                final button = context.findRenderObject() as RenderBox;
                final overlay = Overlay.of(context).context.findRenderObject()
                    as RenderBox;
                const menuOffset = 8.0;
                final position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(
                      Offset(0, button.size.height + menuOffset),
                      ancestor: overlay,
                    ),
                    button.localToGlobal(
                      Offset(
                        button.size.width,
                        button.size.height + menuOffset,
                      ),
                      ancestor: overlay,
                    ),
                  ),
                  Offset.zero & overlay.size,
                );

                final selectedCity = await showMenu<String>(
                  context: context,
                  position: position,
                  constraints: BoxConstraints(minWidth: button.size.width),
                  elevation: 8,
                  shadowColor: const Color(0xFF020617).withValues(alpha: 0.2),
                  color: const Color(0xFF242426),
                  surfaceTintColor: Colors.transparent,
                  menuPadding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  items: items
                      .where((city) => city != value)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final city = entry.value;
                    final isLast = index == items.length - 1;

                    return PopupMenuItem<String>(
                      value: city,
                      padding: EdgeInsets.zero,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          city,
                          style: textStyle?.copyWith(
                            color: const Color(0xFFD1D1D6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );

                if (selectedCity != null) {
                  onChanged(selectedCity);
                }
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: textStyle),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8E8E93),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

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
                style: textStyle?.copyWith(
                  color: const Color(0xFFE2E8F0),
                ),
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

class _LocateMeButton extends StatelessWidget {
  const _LocateMeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF242426),
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey('locate_me_button'),
        onTap: isLoading ? null : onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF020617).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
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
                          Color(0xFF34C759),
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
