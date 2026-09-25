// Файл сгенерирован вручную по формату FlutterFire CLI (`flutterfire configure`),
// на основе google-services.json (Android) и конфига веб-приложения из
// Firebase Console. Нужен, чтобы Firebase.initializeApp() работал одинаково
// и в вебе, и на Android с одними и теми же настройками проекта.
// ignore_for_file: type=lint

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions не настроены для этой платформы.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyASVEsHYn590RQichZ2-BSuHRtFWqWU4lo',
    appId: '1:489726420615:web:503749023aed4604f57a22',
    messagingSenderId: '489726420615',
    projectId: 'carspot-35d67',
    authDomain: 'carspot-35d67.firebaseapp.com',
    storageBucket: 'carspot-35d67.firebasestorage.app',
    measurementId: 'G-7X1J91BZ2N',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAv4BgRhn0SryBRTF8u7RymExe784cZCtw',
    appId: '1:489726420615:android:7c43ab6121f8325af57a22',
    messagingSenderId: '489726420615',
    projectId: 'carspot-35d67',
    storageBucket: 'carspot-35d67.firebasestorage.app',
  );
}
