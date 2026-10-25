/// Organizer login (prototype).
///
/// Only organizers (HR / facilities admins) log in to RideLine. For the
/// midterm prototype we accept one hardcoded account. In the final version
/// this will be replaced by a real backend with hashed passwords (NFR-01).
class AuthService {
  static const String demoEmail = 'organizer@rideline.uz';
  static const String demoPassword = 'demo123';
  static const String demoName = 'Organizer (HR)';

  String? _currentUser;

  String? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Returns null on success, or an error message to show on screen.
  String? login(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) {
      return 'Please enter your email and password.';
    }
    if (email.trim().toLowerCase() != demoEmail || password != demoPassword) {
      return 'Wrong email or password.';
    }
    _currentUser = demoName;
    return null;
  }

  void logout() => _currentUser = null;
}
