import 'dart:async';

import 'package:flutter/material.dart';

class SheetStatusCard extends StatelessWidget {
  const SheetStatusCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242426),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

class SheetLoadingState extends StatelessWidget {
  const SheetLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Nöbetçi eczane verileri yükleniyor...',
            style: TextStyle(color: Color(0xFFAEAEB2)),
          ),
        ),
      ],
    );
  }
}

class SheetErrorState extends StatelessWidget {
  const SheetErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFAEAEB2)),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Tekrar Dene'),
        ),
      ],
    );
  }
}

class SheetEmptyState extends StatelessWidget {
  const SheetEmptyState({required this.onRefresh, super.key});

  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bu şehir için aktif nöbetçi eczane verisi bulunamadı.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFAEAEB2)),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onRefresh == null ? null : () => unawaited(onRefresh!()),
          child: const Text('Yeniden Yükle'),
        ),
      ],
    );
  }
}
