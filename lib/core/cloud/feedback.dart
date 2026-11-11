import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';

import '../app_info.dart';
import 'account.dart';

enum FeedbackType { bug, idea, other, diagnostics }

/// Sends bug reports and feature ideas to Firestore (`feedback/{id}`), with
/// up to [maxImages] screenshots stored as chunks. Works signed out: a silent
/// anonymous account is created so the security rules can require auth.
class FeedbackService {
  static const maxImages = 3;
  static const maxMessage = 4000;
  static const maxDiagnostics = 20000;
  static const _imageBudget = 700 * 1024;
  static const minGap = Duration(seconds: 30);
  static DateTime? _last;

  static bool get available => AccountService.instance.available;

  /// Downscales and re-encodes an image to JPEG under ~700 KB. Runs in the
  /// caller's isolate; fine for a handful of screenshots.
  static Uint8List? compress(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    var width = decoded.width > 1280 ? 1280 : decoded.width;
    var quality = 80;
    for (var i = 0; i < 8; i++) {
      final scaled = decoded.width > width
          ? img.copyResize(decoded, width: width)
          : decoded;
      final out = Uint8List.fromList(img.encodeJpg(scaled, quality: quality));
      if (out.length <= _imageBudget) return out;
      quality = quality > 50 ? quality - 10 : quality;
      if (quality <= 50) width = (width * 0.8).round();
    }
    return null;
  }

  /// Returns null on success or a user-readable problem.
  static Future<String?> submit({
    required FeedbackType type,
    required String message,
    String email = '',
    List<Uint8List> images = const [],
    String diagnostics = '',
  }) async {
    if (!available) return 'Feedback is not available in this build.';
    final text = message.trim();
    if (text.isEmpty) return 'Please describe the problem or idea.';
    final now = DateTime.now();
    if (_last != null && now.difference(_last!) < minGap) {
      return 'Please wait a moment before sending another report.';
    }
    try {
      var user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (user == null) return 'Could not start a feedback session.';
      final info = await PackageInfo.fromPlatform();
      final id = '${now.millisecondsSinceEpoch}-${user.uid.substring(0, 6)}';
      final doc = FirebaseFirestore.instance.collection('feedback').doc(id);
      final shown = images.take(maxImages).toList();
      await doc.set({
        'type': type.name,
        'message': text.length > maxMessage
            ? text.substring(0, maxMessage)
            : text,
        'email': email.trim().length > 200
            ? email.trim().substring(0, 200)
            : email.trim(),
        'app': info.version,
        'build': displayBuild(info.buildNumber),
        'os': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'locale': Platform.localeName,
        'uid': user.uid,
        'created': now.millisecondsSinceEpoch,
        'images': shown.length,
        'diagnostics': diagnostics.length > maxDiagnostics
            ? diagnostics.substring(0, maxDiagnostics)
            : diagnostics,
      });
      _last = now;
      try {
        for (var i = 0; i < shown.length; i++) {
          await doc.collection('chunks').doc('$i').set({
            'i': i,
            'data': Blob(shown[i]),
          });
        }
      } catch (_) {
        return 'Your report was sent, but the screenshots could not be uploaded.';
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'operation-not-allowed' ||
          e.code == 'admin-restricted-operation') {
        return 'Feedback is not enabled yet (${e.code}).';
      }
      if (e.code == 'permission-denied') return 'The report was rejected.';
      if (e.code == 'network-request-failed' || e.code == 'unavailable') {
        return 'No connection. Check your internet and try again.';
      }
      return 'Could not send feedback (${e.code}).';
    } catch (e) {
      return 'Could not send feedback: $e';
    }
  }
}
