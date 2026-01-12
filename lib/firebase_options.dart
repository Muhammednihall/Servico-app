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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCMrxrT3ycIej5MYRc-2C2l4kbKLfEyimw',
    appId: '1:927804136818:web:71ec2039832332f41651eb',
    messagingSenderId: '927804136818',
    projectId: 'servico-1967',
    authDomain: 'servico-1967.firebaseapp.com',
    storageBucket: 'servico-1967.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMrxrT3ycIej5MYRc-2C2l4kbKLfEyimw',
    appId: '1:927804136818:android:71ec2039832332f41651eb',
    messagingSenderId: '927804136818',
    projectId: 'servico-1967',
    storageBucket: 'servico-1967.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMrxrT3ycIej5MYRc-2C2l4kbKLfEyimw',
    appId: '1:927804136818:ios:71ec2039832332f41651eb',
    messagingSenderId: '927804136818',
    projectId: 'servico-1967',
    storageBucket: 'servico-1967.firebasestorage.app',
    iosBundleId: 'com.example.servicoAppFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCMrxrT3ycIej5MYRc-2C2l4kbKLfEyimw',
    appId: '1:927804136818:ios:71ec2039832332f41651eb',
    messagingSenderId: '927804136818',
    projectId: 'servico-1967',
    storageBucket: 'servico-1967.firebasestorage.app',
    iosBundleId: 'com.example.servicoAppFlutter',
  );
}
