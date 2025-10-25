import 'package:flutter/material.dart';

void showTopMessage(
  BuildContext context,
  String message, {
  bool ok = true,
  String? actionLabel,
}) {
  final cs = Theme.of(context).colorScheme;
  final bg = ok ? cs.secondaryContainer : cs.errorContainer;
  final fg = ok ? cs.onSecondaryContainer : cs.onErrorContainer;

  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..clearMaterialBanners()
    ..showMaterialBanner(
      MaterialBanner(
        elevation: 2,
        backgroundColor: bg,
        content: Text(message, style: TextStyle(color: fg)),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: Text(actionLabel ?? 'OK', style: TextStyle(color: fg)),
          ),
        ],
      ),
    );
}

/// Oculta cualquier banner/snackbar activo.
void clearTopMessages(BuildContext context) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentMaterialBanner();
  m.clearMaterialBanners();
  m.clearSnackBars();
}
