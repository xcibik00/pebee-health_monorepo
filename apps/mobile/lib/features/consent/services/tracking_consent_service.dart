import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/consent_repository.dart';

/// Handles the platform-specific tracking consent flow.
///
/// - **iOS**: Requests native ATT authorization via the system dialog
/// - **Android**: Shows a custom dialog explaining analytics tracking
///
/// After the user responds, saves the result to the backend.
class TrackingConsentService {
  const TrackingConsentService(this._consentRepository);

  final ConsentRepository _consentRepository;

  /// Requests tracking consent from the user and saves the result.
  ///
  /// @param context - BuildContext for showing the Android dialog
  /// @returns true if the user granted consent, false otherwise
  Future<bool> requestTrackingConsent(BuildContext context) async {
    final bool granted;
    final String platform;

    if (Platform.isIOS) {
      granted = await _requestIosAttConsent();
      platform = 'ios';
    } else {
      granted = await _requestAndroidConsent(context);
      platform = 'android';
    }

    try {
      await _consentRepository.saveConsent(
        consentType: 'att',
        granted: granted,
        platform: platform,
      );
    } catch (e) {
      debugPrint('Failed to save tracking consent: $e');
    }

    return granted;
  }

  /// Requests iOS ATT authorization via the native system dialog.
  Future<bool> _requestIosAttConsent() async {
    final status =
        await AppTrackingTransparency.requestTrackingAuthorization();
    return status == TrackingStatus.authorized;
  }

  /// Shows a custom dialog on Android asking about analytics tracking.
  Future<bool> _requestAndroidConsent(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('consent.tracking.title'.tr()),
        content: Text('consent.tracking.message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('consent.tracking.deny'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('consent.tracking.allow'.tr()),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
