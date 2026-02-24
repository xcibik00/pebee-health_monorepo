/// A consent record from the backend (`public.user_consents`).
class UserConsent {
  const UserConsent({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.granted,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [UserConsent] from a JSON map returned by the backend.
  factory UserConsent.fromJson(Map<String, dynamic> json) {
    return UserConsent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      consentType: json['consentType'] as String,
      granted: json['granted'] as bool,
      platform: json['platform'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  final String id;
  final String userId;
  final String consentType;
  final bool granted;
  final String platform;
  final String createdAt;
  final String updatedAt;
}
