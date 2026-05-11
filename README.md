# Perimax

Application Flutter : lecture de la date de péremption sur l’emballage (OCR), saisie du nom du produit, enregistrement dans **Cloud Firestore**.

## Prérequis Firebase

1. Créez un projet sur [Firebase Console](https://console.firebase.google.com/).
2. Installez [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) puis à la racine du dépôt :  
   `dart pub global activate flutterfire_cli`  
   `flutterfire configure`  
   Cela remplace `lib/firebase_options.dart` et les fichiers natifs (`google-services.json`, `GoogleService-Info.plist`).
3. Dans la console : activez **Firestore** ; dans **Authentication** > **Sign-in method**, activez **Anonyme**.
4. Déployez les règles du fichier `firebase/firestore.rules` (menu Firestore > Règles), ou via Firebase CLI si vous avez un `firebase.json`.

## Lancer l’app

```bash
flutter pub get
flutter run
```

Sur un appareil ou émulateur **Android** ou **iOS** (caméra + ML Kit).

## Structure des données

Documents : `users/{uid}/products/{id}` avec les champs `name`, `expirationDate`, `createdAt`.
