import 'package:flutter/material.dart';

import '../../../pharmacies/data/models/city_option.dart';

class CityDropdown extends StatelessWidget {
  const CityDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final CityOption value;
  final List<CityOption> items;
  final ValueChanged<CityOption?> onChanged;

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
                final availableCities = items
                    .where((city) => city.slug != value.slug)
                    .toList();
                if (availableCities.isEmpty) {
                  return;
                }

                final button = context.findRenderObject() as RenderBox;
                final overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
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

                final selectedCity = await showMenu<CityOption>(
                  context: context,
                  position: position,
                  constraints: BoxConstraints(
                    minWidth: button.size.width,
                    maxHeight: 5 * 48.0 + 12.0,
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF020617).withValues(alpha: 0.2),
                  color: const Color(0xFF242426),
                  surfaceTintColor: Colors.transparent,
                  menuPadding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  items: availableCities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final city = entry.value;
                    final isLast = index == availableCities.length - 1;

                    return PopupMenuItem<CityOption>(
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
                          city.name,
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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value.name, style: textStyle),
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
