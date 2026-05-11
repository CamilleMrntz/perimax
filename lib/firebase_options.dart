// Config Web : renseignée depuis la console Firebase.
// Pour Android / iOS : complétez les `appId` (et fichiers natifs) via
// `flutterfire configure` ou Projet Firebase > Paramètres > Vos applications.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Configurez Firebase pour cette plateforme avec flutterfire configure, '
          'ou testez sur Android / iOS / Web.',
        );
    }
  }

  /// Même app Android que `android/app/google-services.json` (package `company.perimax`).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJ7a1kAiXXsk03UxYfiGubanu5oVn5PHU',
    appId: '1:630492228715:android:4ffc32ad5e3b5ff97b152e',
    messagingSenderId: '630492228715',
    projectId: 'perimax',
    storageBucket: 'perimax.firebasestorage.app',
  );

  /// À aligner sur l’app iOS enregistrée dans Firebase (appId + GoogleService-Info.plist).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAO1WGLFCK35XQ3LRYFSpRfAVJ6FAl64GI',
    appId: '1:630492228715:ios:0000000000000000000000',
    messagingSenderId: '630492228715',
    projectId: 'perimax',
    storageBucket: 'perimax.firebasestorage.app',
    iosBundleId: 'com.perimax.app.perimax',
  );

  static const FirebaseOptions macos = ios;

  /// Configuration Web (équivalent du snippet `initializeApp` JavaScript).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAO1WGLFCK35XQ3LRYFSpRfAVJ6FAl64GI',
    appId: '1:630492228715:web:082f9206fe6ed61d7b152e',
    messagingSenderId: '630492228715',
    projectId: 'perimax',
    authDomain: 'perimax.firebaseapp.com',
    storageBucket: 'perimax.firebasestorage.app',
  );
}
