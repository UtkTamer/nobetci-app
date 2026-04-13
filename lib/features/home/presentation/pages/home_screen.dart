import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_service.dart';
import '../models/home_screen_status.dart';
import '../../../pharmacies/data/models/city_option.dart';
import '../../../pharmacies/data/models/pharmacy_feed.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../pharmacies/data/repositories/pharmacy_repository.dart';
import '../../../pharmacies/data/repositories/remote_pharmacy_repository.dart';
import '../../../pharmacies/domain/pharmacy.dart';
import '../../../pharmacies/presentation/widgets/pharmacy_bottom_sheet.dart';
import '../widgets/city_dropdown.dart';
import '../widgets/home_map_section.dart';
import '../widgets/locate_me_button.dart';
import '../widgets/map_attribution.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({
    this.locationService = const GeolocatorLocationService(),
    PharmacyRepository? pharmacyRepository,
    super.key,
  }) : pharmacyRepository = pharmacyRepository ?? RemotePharmacyRepository();

  final LocationService locationService;
  final PharmacyRepository pharmacyRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mapController = MapController();
  final _sheetController = PharmacyBottomSheetController();
  final _sheetExtentNotifier = ValueNotifier<double>(AppConstants.initialSheetSize);
  List<CityOption> _cities = const [];
  Map<String, CityOption> _cityMap = const {};
  List<Pharmacy> _pharmacies = const [];
  Map<String, Pharmacy> _pharmacyMap = const {};
  double _mapViewportHeight = 0;
  double _mapDragDistance = 0;
  String? _selectedPharmacyId;
  String? _selectedCitySlug;
  LatLng? _userLocation;
  bool _isLocatingUser = false;
  HomeScreenStatus _status = HomeScreenStatus.idle;
  String? _errorMessage;
  DateTime? _updatedAt;
  bool _isStale = false;

  // Distance sort memoization
  List<Pharmacy>? _distanceSortCache;
  List<Pharmacy>? _distanceSortInput;
  LatLng? _distanceSortLocation;

  @override
  void initState() {
    super.initState();
    _primeUserLocation();
    _loadInitialData();
  }

  @override
  void dispose() {
    _sheetExtentNotifier.dispose();
    super.dispose();
  }

  Future<void> _primeUserLocation() async {
    try {
      final currentLocation = await widget.locationService.determinePosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = currentLocation;
        _updatePharmacies(_applyDistanceSorting(_pharmacies, currentLocation));
      });
    } catch (_) {
      // Keep initial load resilient if location cannot be resolved.
    }
  }

  void _onPharmacySelected(String pharmacyId) {
    if (_pharmacies.isEmpty) {
      return;
    }

    final isSamePharmacy = _selectedPharmacyId == pharmacyId;
    final nextSelectedPharmacyId = isSamePharmacy ? null : pharmacyId;

    setState(() {
      _selectedPharmacyId = nextSelectedPharmacyId;
    });

    if (nextSelectedPharmacyId == null) {
      _sheetController.collapseToInitial(AppConstants.initialSheetSize);
      return;
    }

    final selectedPharmacy = _pharmacyMap[nextSelectedPharmacyId];
    if (selectedPharmacy == null) return;

    if (selectedPharmacy.hasCoordinates) {
      final visibleMapCenterOffset = Offset(
        0,
        -(_mapViewportHeight * AppConstants.initialSheetSize) / 2,
      );
      _mapController.move(
        selectedPharmacy.location,
        AppConstants.focusZoom,
        offset: visibleMapCenterOffset,
      );
    }

    _sheetController.expandToMax(AppConstants.maxSheetSize);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _status = HomeScreenStatus.loading;
      _errorMessage = null;
    });

    try {
      final cities = await widget.pharmacyRepository.fetchCities();
      if (!mounted) {
        return;
      }

      final selectedCity = _preferredInitialCity(cities);
      PharmacyFeed? feed;
      if (selectedCity != null) {
        feed = await widget.pharmacyRepository.fetchOnDutyPharmacies(
          selectedCity.slug,
        );
      }

      if (!mounted) {
        return;
      }

      final pharmacies = _applyDistanceSorting(
        feed?.pharmacies ?? const [],
        _userLocation,
      );
      _syncMapToFirstCoordinate(pharmacies);

      setState(() {
        _updateCities(cities);
        _selectedCitySlug = selectedCity?.slug;
        _updatePharmacies(pharmacies);
        _updatedAt = feed?.updatedAt;
        _isStale = feed?.isStale ?? false;
        _status = HomeScreenStatus.loaded;
      });
    } on PharmacyRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = HomeScreenStatus.error;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = HomeScreenStatus.error;
        _errorMessage = 'Veri yüklenirken bir sorun oluştu.';
      });
    }
  }

  Future<void> _loadCity(CityOption city, {bool isRefresh = false}) async {
    setState(() {
      _status = isRefresh
          ? HomeScreenStatus.refreshing
          : HomeScreenStatus.loading;
      _selectedCitySlug = city.slug;
      _errorMessage = null;
      _selectedPharmacyId = null;
    });

    try {
      final feed = await widget.pharmacyRepository.fetchOnDutyPharmacies(
        city.slug,
      );
      if (!mounted) {
        return;
      }

      final pharmacies = _applyDistanceSorting(feed.pharmacies, _userLocation);
      _syncMapToFirstCoordinate(pharmacies);

      setState(() {
        _updatePharmacies(pharmacies);
        _updatedAt = feed.updatedAt;
        _isStale = feed.isStale;
        _status = HomeScreenStatus.loaded;
      });
    } on PharmacyRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = HomeScreenStatus.error;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = HomeScreenStatus.error;
        _errorMessage = 'Seçilen şehir için veri alınamadı.';
      });
    }
  }

  CityOption? _preferredInitialCity(List<CityOption> cities) {
    if (cities.isEmpty) {
      return null;
    }

    for (final city in cities) {
      if (city.slug == 'ankara') {
        return city;
      }
    }

    return cities.first;
  }

  void _syncMapToFirstCoordinate(List<Pharmacy> pharmacies) {
    final firstWithCoordinates = pharmacies.where(
      (item) => item.hasCoordinates,
    );
    if (firstWithCoordinates.isEmpty) {
      return;
    }

    _mapController.move(
      firstWithCoordinates.first.location,
      AppConstants.defaultZoom,
    );
  }

  List<Pharmacy> _applyDistanceSorting(
    List<Pharmacy> pharmacies,
    LatLng? userLocation,
  ) {
    if (userLocation == null) {
      return pharmacies;
    }

    final locationChanged = _distanceSortLocation == null ||
        _distanceSortLocation!.latitude != userLocation.latitude ||
        _distanceSortLocation!.longitude != userLocation.longitude;

    if (!locationChanged &&
        identical(_distanceSortInput, pharmacies) &&
        _distanceSortCache != null) {
      return _distanceSortCache!;
    }

    const distance = Distance();
    final withDistance = pharmacies.map((pharmacy) {
      if (!pharmacy.hasCoordinates) {
        return pharmacy.copyWith(distanceKm: double.infinity);
      }
      final meters = distance(userLocation, pharmacy.location);
      return pharmacy.copyWith(distanceKm: meters / 1000);
    }).toList();

    withDistance.sort(
      (left, right) => left.distanceKm.compareTo(right.distanceKm),
    );

    _distanceSortCache = withDistance;
    _distanceSortInput = pharmacies;
    _distanceSortLocation = userLocation;
    return withDistance;
  }

  void _updatePharmacies(List<Pharmacy> pharmacies) {
    _pharmacies = pharmacies;
    _pharmacyMap = {for (final p in pharmacies) p.id: p};
  }

  void _updateCities(List<CityOption> cities) {
    _cities = cities;
    _cityMap = {for (final c in cities) c.slug: c};
  }

  Pharmacy? get _nearestPharmacy {
    for (final pharmacy in _pharmacies) {
      if (pharmacy.distanceKm.isFinite) {
        return pharmacy;
      }
    }

    return null;
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
        _updatePharmacies(_applyDistanceSorting(_pharmacies, currentLocation));
      });

      _mapController.move(currentLocation, AppConstants.userLocationZoom);
    } on LocationFailure catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum alinirken bir sorun olustu.')),
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
    final selectedCity = _selectedCityOption;
    final hasData =
        _status == HomeScreenStatus.loaded ||
        _status == HomeScreenStatus.refreshing;
    final nearestPharmacy = _nearestPharmacy;

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

            return Stack(
              children: [
                HomeMapSection(
                  mapController: _mapController,
                  pharmacies: _pharmacies,
                  selectedPharmacyId: _selectedPharmacyId,
                  userLocation: _userLocation,
                  onPharmacySelected: _onPharmacySelected,
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _sheetExtentNotifier,
                  builder: (context, extent, _) {
                    final sheetInset = constraints.maxHeight * extent;
                    final isSheetExpanded =
                        extent > AppConstants.initialSheetSize + 0.02;
                    final showMapAttribution = !isSheetExpanded;

                    return Stack(
                      children: [
                        Positioned(
                          left: 12,
                          bottom: sheetInset + 10,
                          child: AnimatedOpacity(
                            duration: AppConstants.animationFast,
                            curve: Curves.easeOutCubic,
                            opacity: showMapAttribution ? 1 : 0,
                            child: IgnorePointer(
                              ignoring: !showMapAttribution,
                              child: const MapAttribution(),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: sheetInset + 10,
                          child: LocateMeButton(
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
                                if (_mapDragDistance >
                                    AppConstants.mapDragCollapseThreshold) {
                                  _mapDragDistance = 0;
                                  _sheetController.collapseToInitial(
                                    AppConstants.initialSheetSize,
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  },
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
                        if (_cities.isNotEmpty && selectedCity != null)
                          CityDropdown(
                            value: selectedCity,
                            items: _cities,
                            onChanged: (city) {
                              if (city == null ||
                                  city.slug == _selectedCitySlug) {
                                return;
                              }

                              _loadCity(city);
                            },
                          ),
                        const SizedBox(height: 6),
                        Text(
                          _buildStatusSummary(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFCBD5E1)),
                        ),
                        if (_updatedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _isStale
                                ? 'Son güncelleme eski olabilir: ${DateTimeFormatter.formatShort(_updatedAt!)}'
                                : 'Son güncelleme: ${DateTimeFormatter.formatShort(_updatedAt!)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _isStale
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF94A3B8),
                                ),
                          ),
                        ],
                        const Spacer(),
                        if (nearestPharmacy != null)
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
                                  '${nearestPharmacy.distanceKm.toStringAsFixed(1)} km uzakta',
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
                  pharmacies: hasData ? _pharmacies : const [],
                  selectedPharmacyId: _selectedPharmacyId,
                  onPharmacySelected: _onPharmacySelected,
                  minChildSize: AppConstants.minSheetSize,
                  initialChildSize: AppConstants.initialSheetSize,
                  maxChildSize: AppConstants.maxSheetSize,
                  status: _status,
                  errorMessage: _errorMessage,
                  onRetry: selectedCity == null
                      ? null
                      : () => _loadCity(selectedCity),
                  onRefresh: selectedCity == null
                      ? null
                      : () => _loadCity(selectedCity, isRefresh: true),
                  onExtentChanged: (extent) {
                    _sheetExtentNotifier.value = extent;
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildStatusSummary() {
    final selectedCityName = _selectedCityOption?.name ?? 'Seçili şehir';

    if (_status == HomeScreenStatus.loading) {
      return 'Nöbetçi eczane verileri yükleniyor';
    }

    if (_status == HomeScreenStatus.refreshing) {
      return '$selectedCityName için veriler yenileniyor';
    }

    if (_status == HomeScreenStatus.error) {
      return _errorMessage ?? 'Veri alınamadı';
    }

    return '$selectedCityName için ${_pharmacies.length} eczane listeleniyor';
  }

  CityOption? get _selectedCityOption =>
      _selectedCitySlug != null ? _cityMap[_selectedCitySlug] : null;
}
