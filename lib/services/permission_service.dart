import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<PermissionStatus> requestSmsPermission(
      BuildContext context) async {
    PermissionStatus status = await Permission.sms.status;

    if (status.isGranted) {
      return status;
    }

    if (status.isPermanentlyDenied) {
      await _showPermanentlyDeniedDialog(context);
      status = await Permission.sms.status;
    } else {
      status = await Permission.sms.request();
      if (status.isPermanentlyDenied) {
        await _showPermanentlyDeniedDialog(context);
        status = await Permission.sms.status;
      }
    }

    return status;
  }

  static Future<void> _showPermanentlyDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'SMS permission is permanently denied. Please enable it in the app settings to use the auto-sync feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
