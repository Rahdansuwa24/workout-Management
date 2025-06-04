import 'package:flutter/material.dart';

class CountdownPage extends StatelessWidget {
  const CountdownPage({super.key});

  // Skema Warna
  static const Color screenBackgroundColor = Color(0xFF0A0A0A); // Sangat gelap
  static const Color appBarTextColor = Colors.white;
  static const Color chipBackgroundColor = Color(0xFFE0C083); // Kuning-beige
  static const Color chipTextColor = Color(0xFF121212); // Teks gelap di chip
  static const Color timerTextColor = Colors.white;
  static const Color setsRepsTextColor =
      Color(0xFF9E9E9E); // Abu-abu untuk set/reps
  static const Color startButtonBackgroundColor = chipBackgroundColor;
  static const Color startButtonTextColor = chipTextColor;
  static const Color stopButtonBackgroundColor =
      Color(0xFF2C2C2C); // Abu-abu gelap
  static const Color stopButtonTextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackgroundColor,
      appBar: AppBar(
        backgroundColor: screenBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: appBarTextColor),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'COUNTDOWN',
          style: TextStyle(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSection(context),
          _buildWorkoutNameChip("Single Dumbbel Row"),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerDisplay("20 : 00", "05 X 12"),
              ],
            ),
          ),
          _buildActionButtons(context),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom +
                  24), // Padding bawah aman
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    // Ganti dengan Image.asset jika Anda punya gambar
    return Image.asset(
      'assets/incheon.jpg', // Ganti dengan path gambar Anda
      height: MediaQuery.of(context).size.height *
          0.4, // Ambil sekitar 40% tinggi layar
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildWorkoutNameChip(String name) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 10.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: chipBackgroundColor,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: chipTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(String time, String setsReps) {
    return Column(
      children: [
        Text(
          time,
          style: const TextStyle(
            color: timerTextColor,
            fontSize: 80, // Ukuran font besar untuk timer
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace', // Atau font lain yang cocok untuk angka
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          setsReps,
          style: const TextStyle(
            color: setsRepsTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              text: 'Start',
              backgroundColor: startButtonBackgroundColor,
              textColor: startButtonTextColor,
              onPressed: () {
                print('Start button pressed');
                // Logika untuk memulai timer
              },
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: _buildButton(
              text: 'Stop',
              backgroundColor: stopButtonBackgroundColor,
              textColor: stopButtonTextColor,
              onPressed: () {
                print('Stop button pressed');
                // Logika untuk menghentikan timer
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0), // Sudut tombol membulat
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        elevation: 2,
      ),
      child: Text(text),
    );
  }
}
