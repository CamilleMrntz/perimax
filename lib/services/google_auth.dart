import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ID client **Web** OAuth (application Web dans Firebase) :
/// Paramètres du projet > Général > Vos applications > SDK Web > ID client OAuth
/// (se termine souvent par `.apps.googleusercontent.com`).
///
/// Souvent **obligatoire sur Android** pour obtenir un `idToken` utilisable par Firebase.
/// Exemple : `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=123456-xxx.apps.googleusercontent.com`
const String _webClientIdFromEnv = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);

bool _googleSignInInitialized = false;

/// A appeler une fois au demarrage (avant tout flux Google).
Future<void> ensureGoogleSignInInitialized() async {
  if (_googleSignInInitialized) return;
  await GoogleSignIn.instance.initialize(
    serverClientId: _webClientIdFromEnv.isEmpty ? null : _webClientIdFromEnv,
  );
  _googleSignInInitialized = true;
}

Future<UserCredential?> signInWithGoogle() async {
  await ensureGoogleSignInInitialized();

  try {
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: const <String>['email', 'profile'],
    );

    final auth = account.authentication;
    if (auth.idToken == null) {
      throw StateError(
        'idToken Google absent. Ajoutez l\'ID client Web OAuth dans Firebase '
        '(app Web), puis lancez avec --dart-define=GOOGLE_WEB_CLIENT_ID=... '
        'ou renseignez serverClientId dans ensureGoogleSignInInitialized.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) {
      return null;
    }
    rethrow;
  }
}

Future<void> signOutGoogle() async {
  await ensureGoogleSignInInitialized();
  await GoogleSignIn.instance.signOut();
  await FirebaseAuth.instance.signOut();
}
