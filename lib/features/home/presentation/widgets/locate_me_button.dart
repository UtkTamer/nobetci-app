import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class LocateMeButton extends StatelessWidget {
  const LocateMeButton({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

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
              duration: AppConstants.animationFast,
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
