// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_uas/gym/countdownPage.dart';
import 'package:flutter_uas/gym/createPaget.dart';
import 'package:flutter_uas/gym/dashboard.dart';
import 'package:flutter_uas/gym/editPage.dart';
import 'package:flutter_uas/gym/recommendationDetail.dart';
import 'package:flutter_uas/gym/schedulePage.dart';
import 'package:flutter_uas/auth/signIn.dart';
import 'package:flutter_uas/auth/signUp.dart';
import 'package:flutter_uas/gym/workoutDetail.dart';
import 'package:flutter_uas/gym/workoutList.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PGR',
        theme: ThemeData(),
        initialRoute: '/',
        // Definisi rute statis yang tidak memerlukan argumen dinamis
        routes: {
          '/': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) => DashboardPage(),
          '/listworkout': (context) => const WorkoutList(),
          '/detailworkout': (context) => const WorkoutDetail(),
          '/detailrecommendation': (context) => const RecommendationDetail(),
          '/schedule': (context) => const SchedulePage(),
          '/countdown': (context) => const CountdownPage(),
          '/create': (context) => const CreateWorkoutPage(),
          '/edit': (context) => const UpdateWorkoutPage(),
        });
  }
}
