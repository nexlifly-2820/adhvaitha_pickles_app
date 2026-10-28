// image_util.dart
// Smart Image Loader for resolving live API network images vs offline fallback assets.

import 'package:flutter/material.dart';

const String kAdminBaseUrl = 'https://admin.adhvaithafoods.in';

Widget buildSmartImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Alignment alignment = Alignment.center,
  Widget? errorWidget,
}) {
  if (path.trim().isEmpty) {
    return errorWidget ?? SizedBox(width: width, height: height);
  }

  final String cleanPath = path.trim();
  final String fullUrl = cleanPath.startsWith('http')
      ? cleanPath
      : '$kAdminBaseUrl/${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';

  return Image.network(
    fullUrl,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    errorBuilder: (context, error, stackTrace) {
      final String assetPath =
          cleanPath.startsWith('assets/') ? cleanPath : 'assets/images/$cleanPath';
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? SizedBox(width: width, height: height),
      );
    },
  );
}
