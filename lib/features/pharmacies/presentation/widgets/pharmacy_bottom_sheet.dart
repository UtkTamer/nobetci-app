import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/widgets/sheet_drag_handle.dart';
import '../../domain/pharmacy.dart';
import 'pharmacy_list_item.dart';

class PharmacyBottomSheetController {
  Future<void> Function(double targetSize)? _animateTo;

  void _bind(Future<void> Function(double targetSize) animateTo) {
    _animateTo = animateTo;
  }

  void _unbind() {
    _animateTo = null;
  }

  Future<void> collapseToInitial(double initialSize) async {
    await _animateTo?.call(initialSize);
  }

  Future<void> expandToMax(double maxSize) async {
    await _animateTo?.call(maxSize);
  }
}

class PharmacyBottomSheet extends StatefulWidget {
  const PharmacyBottomSheet({
    required this.pharmacies,
    required this.selectedPharmacyId,
    required this.onPharmacySelected,
    required this.minChildSize,
    required this.initialChildSize,
    required this.maxChildSize,
    required this.controller,
    this.onExtentChanged,
    super.key,
  });

  final List<Pharmacy> pharmacies;
  final String? selectedPharmacyId;
  final ValueChanged<String> onPharmacySelected;
  final double minChildSize;
  final double initialChildSize;
  final double maxChildSize;
  final PharmacyBottomSheetController controller;
  final ValueChanged<double>? onExtentChanged;

  @override
  State<PharmacyBottomSheet> createState() => _PharmacyBottomSheetState();
}

class _PharmacyBottomSheetState extends State<PharmacyBottomSheet> {
  final _draggableController = DraggableScrollableController();
  final _searchController = TextEditingController();
  late final Map<String, GlobalKey> _itemKeys;
  bool _isAutoSnapping = false;
  double _downwardPullDistance = 0;
  double _handleDragDistance = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _itemKeys = {
      for (final pharmacy in widget.pharmacies) pharmacy.id: GlobalKey(),
    };
    widget.controller._bind(_animateSheetTo);
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.controller._unbind();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PharmacyBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPharmacyId == widget.selectedPharmacyId ||
        widget.selectedPharmacyId == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_revealSelectedPharmacy());
    });
  }

  Future<void> _animateSheetTo(double targetSize) async {
    if (!_draggableController.isAttached || _isAutoSnapping) {
      return;
    }

    _isAutoSnapping = true;
    try {
      await _draggableController.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isAutoSnapping = false;
    }
  }

  Future<void> _revealSelectedPharmacy() async {
    await _animateSheetTo(widget.maxChildSize);

    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 60));

    if (!mounted) {
      return;
    }

    final selectedPharmacyId = widget.selectedPharmacyId;
    if (selectedPharmacyId == null) {
      return;
    }

    final selectedItemContext = _itemKeys[selectedPharmacyId]?.currentContext;
    if (selectedItemContext == null || !selectedItemContext.mounted) {
      return;
    }

    await Scrollable.ensureVisible(
      selectedItemContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _handleHeaderDragStart(DragStartDetails details) {
    _handleDragDistance = 0;
  }

  void _handleHeaderDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    _handleDragDistance += delta;
  }

  void _handleHeaderDragEnd(DragEndDetails details) {
    if (_handleDragDistance < -10) {
      unawaited(_animateSheetTo(widget.maxChildSize));
    } else if (_handleDragDistance > 10) {
      unawaited(_animateSheetTo(widget.initialChildSize));
    }

    _handleDragDistance = 0;
  }

  bool _handleListDragForCollapse(ScrollNotification notification) {
    if (_isAutoSnapping) {
      return false;
    }

    final isExpanded =
        _draggableController.isAttached &&
        _draggableController.size > widget.initialChildSize + 0.02;

    if (!isExpanded) {
      _downwardPullDistance = 0;
      return false;
    }

    if (notification is ScrollStartNotification) {
      _downwardPullDistance = 0;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final atTop = notification.metrics.pixels <=
          notification.metrics.minScrollExtent + 0.5;
      final delta = notification.scrollDelta ?? 0;

      if (atTop && delta < 0) {
        _downwardPullDistance += -delta;
      } else if (delta > 0) {
        _downwardPullDistance = 0;
      }

      if (_downwardPullDistance > 22) {
        _downwardPullDistance = 0;
        unawaited(_animateSheetTo(widget.initialChildSize));
      }

      return false;
    }

    if (notification is OverscrollNotification) {
      final atTop = notification.metrics.pixels <=
          notification.metrics.minScrollExtent + 0.5;

      if (atTop && notification.overscroll < 0) {
        _downwardPullDistance += -notification.overscroll;
      }

      if (_downwardPullDistance > 22) {
        _downwardPullDistance = 0;
        unawaited(_animateSheetTo(widget.initialChildSize));
      }

      return false;
    }

    if (notification is ScrollEndNotification) {
      _downwardPullDistance = 0;
    }

    return false;
  }

  List<Pharmacy> get _filteredPharmacies {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return widget.pharmacies;
    }

    return widget.pharmacies.where((pharmacy) {
      final haystack =
          '${pharmacy.name} ${pharmacy.address} ${pharmacy.phoneNumber}'
              .toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPharmacies = _filteredPharmacies;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        widget.onExtentChanged?.call(notification.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _draggableController,
        minChildSize: widget.minChildSize,
        initialChildSize: widget.initialChildSize,
        maxChildSize: widget.maxChildSize,
        snap: true,
        snapSizes: [widget.initialChildSize, widget.maxChildSize],
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 36,
                  offset: Offset(0, -14),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleListDragForCollapse,
                        child: CustomScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Açık Eczaneler',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.5,
                                            color: Colors.white,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2C2C2E),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        decoration: InputDecoration(
                                          hintText: 'Eczane ara',
                                          hintStyle: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: const Color(0xFF8E8E93),
                                              ),
                                          prefixIcon: const Icon(
                                            Icons.search_rounded,
                                            color: Color(0xFF8E8E93),
                                          ),
                                          suffixIcon: _searchQuery.isEmpty
                                              ? null
                                              : IconButton(
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() {
                                                      _searchQuery = '';
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    color: Color(0xFF8E8E93),
                                                  ),
                                                ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 13,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              sliver: filteredPharmacies.isEmpty
                                  ? SliverToBoxAdapter(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF242426),
                                          borderRadius:
                                              BorderRadius.circular(22),
                                        ),
                                        child: Text(
                                          'Aramaya uygun eczane bulunamadı.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: const Color(0xFFAEAEB2),
                                              ),
                                        ),
                                      ),
                                    )
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          if (index.isOdd) {
                                            return const SizedBox(height: 10);
                                          }

                                          final pharmacy =
                                              filteredPharmacies[index ~/ 2];
                                          final isExpanded = pharmacy.id ==
                                              widget.selectedPharmacyId;

                                          return KeyedSubtree(
                                            key: _itemKeys[pharmacy.id],
                                            child: PharmacyListItem(
                                              pharmacy: pharmacy,
                                              isExpanded: isExpanded,
                                              onTap: () =>
                                                  widget.onPharmacySelected(
                                                    pharmacy.id,
                                                  ),
                                            ),
                                          );
                                        },
                                        childCount:
                                            filteredPharmacies.length * 2 - 1,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _PinnedHandleHeader(
                      onTap: () {
                        final isExpanded =
                            _draggableController.isAttached &&
                            _draggableController.size >
                                widget.initialChildSize + 0.02;

                        unawaited(
                          _animateSheetTo(
                            isExpanded
                                ? widget.initialChildSize
                                : widget.maxChildSize,
                          ),
                        );
                      },
                      onVerticalDragStart: _handleHeaderDragStart,
                      onVerticalDragUpdate: _handleHeaderDragUpdate,
                      onVerticalDragEnd: _handleHeaderDragEnd,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PinnedHandleHeader extends StatelessWidget {
  const _PinnedHandleHeader({
    required this.onTap,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  final VoidCallback onTap;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Container(
        height: 42,
        alignment: Alignment.topCenter,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        padding: const EdgeInsets.only(top: 10),
        child: const SheetDragHandle(),
      ),
    );
  }
}
