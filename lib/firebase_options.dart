// FlutterFire CLI で上書きするまでのプレースホルダーです。
// ターミナルでプロジェクトルートから次を実行してください:
//   firebase login
//   flutterfire configure --project=<FirebaseのプロジェクトID> -y --platforms=android,ios,web
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [flutterfire configure] が生成する内容に置き換えてください。
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
        throw UnsupportedError(
          'macOS は未設定です。flutterfire configure に --platforms=macos を追加してください。',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows は未設定です。flutterfire configure に --platforms=windows を追加してください。',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux は未設定です。flutterfire configure に --platforms=linux を追加してください。',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions はこのプラットフォームではサポートされていません。',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCaZdwO-rEAPTvbjycEJgCZtIfd-DcPY8Q',
    appId: '1:775681177017:android:230afcac4c9a702c587268',
    messagingSenderId: '775681177017',
    projectId: 'graviblast-6723f',
    storageBucket: 'graviblast-6723f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDiXx4V9zhmHMO0gA4mm75Jve0uHvNn4U8',
    appId: '1:775681177017:ios:049c305cff6bbfd2587268',
    messagingSenderId: '775681177017',
    projectId: 'graviblast-6723f',
    storageBucket: 'graviblast-6723f.firebasestorage.app',
    iosBundleId: 'com.graviblast.graviblast',
  );

  /// Firebase Console で Web アプリ「graviblast-web」として登録済み。
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAx3NidBwug4vkARFE5KHxCaku56EAP8FU',
    appId: '1:775681177017:web:c648034cc348151f587268',
    messagingSenderId: '775681177017',
    projectId: 'graviblast-6723f',
    authDomain: 'graviblast-6723f.firebaseapp.com',
    storageBucket: 'graviblast-6723f.firebasestorage.app',
    measurementId: 'G-2NNSVHFE31',
  );
}