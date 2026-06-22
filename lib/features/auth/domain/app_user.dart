/// Represents an authenticated user in Smart Naam Jap.
///
/// Wraps the relevant fields from Appwrite's User model into a
/// domain-specific class that the rest of the app depends on.
/// This keeps the Appwrite SDK import confined to the auth layer.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  /// Display name with fallback to email prefix.
  String get displayName {
    if (name.isNotEmpty) return name;
    final atIndex = email.indexOf('@');
    return atIndex > 0 ? email.substring(0, atIndex) : email;
  }

  /// First initial for avatar placeholder.
  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppUser(id: $id, name: $displayName)';
}
