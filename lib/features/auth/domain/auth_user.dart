/// Persona con sesión iniciada.
class AuthUser {
  const AuthUser({required this.uid, this.displayName, this.email});

  final String uid;
  final String? displayName;
  final String? email;

  /// Nombre para mostrar: el de la cuenta o, si no tiene, el correo.
  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email ?? 'Tu cuenta';
  }

  /// Hasta dos iniciales para el avatar.
  String get initials {
    final words = label
        .split(RegExp(r'[\s@._-]+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final letters = words.map((word) => word[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.uid == uid &&
      other.displayName == displayName &&
      other.email == email;

  @override
  int get hashCode => Object.hash(uid, displayName, email);
}
