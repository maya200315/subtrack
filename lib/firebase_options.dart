// File generated for Subtrack App.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCgw_idUMWQIkh60QLSDctmsCNn4TBX-1E',
    appId: '1:549611421510:web:721fe69b3f83f7ce322f47',
    messagingSenderId: '549611421510',
    projectId: 'subtrack-maya-26',
    authDomain: 'subtrack-maya-26.firebaseapp.com',
    storageBucket: 'subtrack-maya-26.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgw_idUMWQIkh60QLSDctmsCNn4TBX-1E',
    appId: '1:549611421510:android:721fe69b3f83f7ce322f47',
    messagingSenderId: '549611421510',
    projectId: 'subtrack-maya-26',
    storageBucket: 'subtrack-maya-26.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgw_idUMWQIkh60QLSDctmsCNn4TBX-1E',
    appId: '1:549611421510:ios:721fe69b3f83f7ce322f47',
    messagingSenderId: '549611421510',
    projectId: 'subtrack-maya-26',
    storageBucket: 'subtrack-maya-26.firebasestorage.app',
    iosBundleId: 'com.maya.subtrack.subtrack',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCgw_idUMWQIkh60QLSDctmsCNn4TBX-1E',
    appId: '1:549611421510:ios:721fe69b3f83f7ce322f47',
    messagingSenderId: '549611421510',
    projectId: 'subtrack-maya-26',
    storageBucket: 'subtrack-maya-26.firebasestorage.app',
    iosBundleId: 'com.maya.subtrack.subtrack',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgw_idUMWQIkh60QLSDctmsCNn4TBX-1E',
    appId: '1:549611421510:web:721fe69b3f83f7ce322f47',
    messagingSenderId: '549611421510',
    projectId: 'subtrack-maya-26',
    authDomain: 'subtrack-maya-26.firebaseapp.com',
    storageBucket: 'subtrack-maya-26.firebasestorage.app',
  );
}