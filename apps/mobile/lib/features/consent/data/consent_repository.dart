import '../../../core/network/api_client.dart';
import '../models/user_consent.dart';

/// Repository for consent-related API calls.
/// All backend communication for consents goes through this class.
class ConsentRepository {
  const ConsentRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches all consent records for the authenticated user.
  Future<List<UserConsent>> getConsents() async {
    final response = await _apiClient.get('/consents');
    final list = response as List<dynamic>;
    return list
        .map((item) => UserConsent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Creates or updates a consent record.
  ///
  /// @param consentType - The type of consent (e.g. 'att')
  /// @param granted - Whether the user granted consent
  /// @param platform - The platform ('ios' or 'android')
  Future<UserConsent> saveConsent({
    required String consentType,
    required bool granted,
    required String platform,
  }) async {
    final response = await _apiClient.post('/consents', {
      'consentType': consentType,
      'granted': granted,
      'platform': platform,
    });
    return UserConsent.fromJson(response as Map<String, dynamic>);
  }
}
