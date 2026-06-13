import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const _releasesUrl =
      'https://github.com/christried/snackbert/releases/latest';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get();

      final minVersion = doc.data()?['minVersion'] as String?;
      if (minVersion == null) return;

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "1.0.2"

      if (_isOutdated(currentVersion, minVersion)) {
        if (context.mounted) showUpdateDialog(context);
      }
    } catch (e) {
      // silently ignore — update check should never crash the app
    }
  }

  static bool _isOutdated(String current, String minimum) {
    return current != minimum;
  }

  static void showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: Image.asset(
          'assets/snackbert_mascot_face.png',
          width: 64,
          height: 64,
        ),
        title: const Text('Update verfügbar!'),
        content: const Text(
          'Eine neue Version von Snackbert ist verfügbar. Die alte Version ist mindestens schlechter, aber realistisch brennt hier jetzt alles lichterloh, wenn du einen Button drückst.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Später'),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(_releasesUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Herunterladen'),
          ),
        ],
      ),
    );
  }
}
