import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/auth/auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({
    required GoogleSignIn googleSignIn,
    required GoogleSignInAccount googleSignInAccount,
  }) {
    _googleSignIn = googleSignIn;
    _googleSignInAccount = googleSignInAccount;
  }

  final _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;
  late final GoogleSignInAccount _googleSignInAccount;

  UserModel? _userFromSupabase(User? user) {
    if (user == null) {
      return null;
    }
    return UserModel(user.id, user.email);
  }

  Stream<UserModel?>? get user {
    return _supabase.auth.onAuthStateChange.map(
      (event) => _userFromSupabase(event.session?.user),
    );
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _supabase.auth.signInWithPassword(
      password: password,
      email: email,
    );

    return _userFromSupabase(credential.user);
  }

  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _supabase.auth.signUp(
      password: password,
      email: email,
    );

    return _userFromSupabase(credential.user);
  }

  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    _googleSignInAccount = googleUser;

    final googleAuth = await googleUser.authentication;
    final credential = await _supabase.auth.signInWithIdToken(
      provider: Provider.google,
      idToken: '${googleAuth.idToken}',
    );

    return _userFromSupabase(credential.user);
  }

  Future<UserModel?> signInWithApple() async {
    final result = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    if (result.identityToken?.isEmpty ?? false) return null;

    final credential = await _supabase.auth.signInWithIdToken(
      provider: Provider.apple,
      idToken: '${result.identityToken}',
    );

    return _userFromSupabase(credential.user);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut(scope: SignOutScope.local);
  }
}
