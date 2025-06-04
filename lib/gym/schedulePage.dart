import 'package:flutter/material.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  // Contoh data jadwal
  final List<Map<String, String>> scheduleData = const [
    {'day': 'MON', 'workouts': 'Dips, Push Ups, Pull Ups'},
    {'day': 'TUE', 'workouts': 'Squats, Lunges, Calf Raises'},
    {'day': 'WED', 'workouts': 'Deadlifts, Rows, Bicep Curls'},
    {'day': 'THU', 'workouts': 'Overhead Press, Lateral Raises'},
    {'day': 'FRI', 'workouts': 'Full Body Circuit Training'},
  ];

  // Skema Warna
  static const Color screenBackgroundColor = Color(0xFF121212);
  static const Color appBarTextColor = Colors.white;
  static const Color bannerTextColor = Colors.white;
  static const Color dayChipBackgroundColor = Color(0xFFE0C083); // Kuning-beige
  static const Color dayChipTextColor = Color(0xFF1F1F1F); // Teks gelap di chip
  static const Color scheduleItemBackgroundColor =
      Color(0xFF1E1E1E); // Latar item jadwal
  static const Color workoutNameTextColor =
      Color(0xFFE0E0E0); // Teks nama workout
  static const Color actionButtonBackgroundColor =
      Color(0xFF383838); // Latar tombol aksi
  static const Color actionButtonTextColor =
      Color(0xFFE0E0E0); // Teks tombol aksi

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
          'SCHEDULE',
          style: TextStyle(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBannerSection(), // Bagian banner yang dikoreksi
            _buildScheduleList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        // Menggunakan decoration untuk gambar
        image: DecorationImage(
          // GANTI DENGAN PATH GAMBAR ANDA YANG SEBENARNYA
          // Contoh: 'assets/images/my_banner.jpg'
          // Pastikan gambar sudah ada di folder assets dan didaftarkan di pubspec.yaml
          image: const AssetImage(
              'assets/photo-schedule.png'), // Gunakan path aset yang valid
          fit: BoxFit.cover,
        ),
      ),
      // Properti 'color' telah DIHAPUS dari sini karena 'decoration' (dengan image) sudah digunakan.
      child: Stack(
        children: [
          // Container overlay gelap ini membantu agar teks lebih terbaca di atas gambar.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.65), // Lebih gelap di bawah
                  Colors.black.withOpacity(0.15) // Lebih transparan di atas
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WITH EVERY STEP',
                  style: TextStyle(
                      color: bannerTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            blurRadius: 5.0,
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(1, 1))
                      ]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get Closer to the Best\nVersion of You',
                  style: TextStyle(
                      color: bannerTextColor,
                      fontSize: 16,
                      height: 1.4,
                      shadows: [
                        Shadow(
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(1, 1))
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: scheduleData.map((item) {
          return _buildScheduleItem(item['day']!, item['workouts']!);
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleItem(String dayAbbreviation, String workoutNames) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: scheduleItemBackgroundColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            _buildDayChip(dayAbbreviation),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workoutNames,
                    style: const TextStyle(
                      color: workoutNameTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      _buildActionButton('Detail'),
                      const SizedBox(width: 8.0),
                      _buildActionButton('Start'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String dayAbbreviation) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: dayChipBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          dayAbbreviation,
          style: const TextStyle(
            color: dayChipTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text) {
    return ElevatedButton(
      onPressed: () {
        print('$text button pressed');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: actionButtonBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: actionButtonTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Untuk menjalankan contoh ini secara terpisah (opsional):
// void main() {
//   runApp(
//     MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: SchedulePage(),
//       // theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: SchedulePage.screenBackgroundColor),
//     ),
//   );
// }
