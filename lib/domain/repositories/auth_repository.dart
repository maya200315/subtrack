abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  String? get currentUserEmail;
  bool get isEmailVerified;

  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
}