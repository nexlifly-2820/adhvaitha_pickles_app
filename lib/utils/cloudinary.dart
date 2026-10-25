import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

String cloudinaryThumb(String url, {int size = 160}) {
  if (url.isEmpty) return url;
  if (!url.contains('cloudinary.com') && !url.contains('res.cloudinary.com')) {
    return url;
  }
  if (url.contains('/upload/w_') || url.contains('/upload/c_')) {
    return url;
  }
  final uploadIndex = url.indexOf('/upload/');
  if (uploadIndex == -1) return url;

  final transform = 'w_$size,h_$size,c_fill,g_auto,f_auto,q_auto/';
  return url.replaceRange(
      uploadIndex + '/upload/'.length, uploadIndex + '/upload/'.length, transform);
}

Color getCategoryColor(String category) {
  final cat = category.toLowerCase().trim();
  if (cat.contains('pickle')) return const Color(0xFFD97706);
  if (cat.contains('podi')) return const Color(0xFF9A3412);
  if (cat.contains('snack') || cat.contains('mixture')) return const Color(0xFFCA8A04);
  if (cat.contains('sweet') || cat.contains('jamun')) return const Color(0xFFB91C1C);
  return const Color(0xFFC2410C);
}

Future<void> precacheOrderImages(
    BuildContext context, List<String> imageUrls) async {
  if (!context.mounted) return;
  final futures = <Future<void>>[];

  for (final rawUrl in imageUrls) {
    if (rawUrl.isEmpty) continue;
    final thumbUrl = cloudinaryThumb(rawUrl, size: 160);
    if (thumbUrl.startsWith('http')) {
      try {
        final provider = CachedNetworkImageProvider(thumbUrl);
        futures.add(precacheImage(provider, context));
      } catch (_) {}
    }
  }

  if (futures.isEmpty) return;

  try {
    await Future.wait(futures).timeout(const Duration(milliseconds: 1500));
  } catch (_) {}
}
