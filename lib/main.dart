import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_app/app/app.dart';
import 'package:flutter/material.dart';

void main() async {
  // Ensure Flutter framework is initialized before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization for Android
  await Firebase.initializeApp(
    // options: const FirebaseOptions(
    //   apiKey: "AIzaSyBjqC1H5QV4DrRYnP6buubn4NPhXqTHikQ",
    //   appId: "1:661343486324:android:4477da69366fa6e1666c21",
    //   messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    //   projectId: "tracking-ed1ba",
    //   storageBucket: "YOUR_STORAGE_BUCKET",
    // ),
  );

  runApp(MyApp());
}
