import 'package:flutter/material.dart';

class UiMessages {
  static void _show(
    BuildContext ctx,
    String text, {
    Color? color,
    IconData icon = Icons.info_outline,
    int seconds = 2,
    List<Widget>? actions,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    final bg = color ?? cs.primary;

    final messenger = ScaffoldMessenger.of(ctx);
    messenger.hideCurrentMaterialBanner();

    messenger.showMaterialBanner(
      MaterialBanner(
        elevation: 6,
        backgroundColor: bg,
        leading: Icon(icon, color: Colors.white),
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions:
            actions ??
            [
              TextButton(
                onPressed: () => messenger.hideCurrentMaterialBanner(),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
        dividerColor: Colors.white24,
        forceActionsBelow: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    Future.delayed(Duration(seconds: seconds), () {
      // Ocultar automáticamente si sigue visible
      messenger.hideCurrentMaterialBanner();
    });
  }

  static void success(BuildContext ctx, String text) => _show(
    ctx,
    text,
    color: const Color(0xFF2E7D32),
    icon: Icons.check_circle,
  );
  static void info(BuildContext ctx, String text) =>
      _show(ctx, text, color: const Color(0xFF1565C0), icon: Icons.info);
  static void error(BuildContext ctx, String text) => _show(
    ctx,
    text,
    color: const Color(0xFFD32F2F),
    icon: Icons.error_outline,
  );
}
