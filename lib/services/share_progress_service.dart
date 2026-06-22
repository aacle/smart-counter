import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utils/app_logger.dart';

/// Service to capture a widget as an image and share it
class ShareProgressService {
  static final ShareProgressService instance = ShareProgressService._();
  ShareProgressService._();

  /// Capture the widget behind [boundaryKey] as a PNG and share it
  Future<void> shareWidgetAsImage(
    GlobalKey boundaryKey, {
    String subject = 'My Practice Progress',
    String text = 'Check out my practice progress on Smart Naam Jap!',
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/practice_progress.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: subject,
          text: text,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('ShareProgressService', 'Failed to share widget as image', e, stackTrace);
    }
  }

  /// Share plain text summary
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, title: subject));
    } catch (e, stackTrace) {
      AppLogger.error('ShareProgressService', 'Failed to share text', e, stackTrace);
    }
  }
}
