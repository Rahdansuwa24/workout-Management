import 'package:flutter/material.dart';

class WorkoutDetail extends StatelessWidget {
  const WorkoutDetail({super.key});

  // Contoh data, bisa diganti dengan data dinamis
  final String exerciseName = 'Single Dumbbel Row';
  final Map<String, String> details = const {
    'Name': 'Dips',
    'Set': '5',
    'Repetition': '15',
    'Time': '20 Min',
    'Day': 'Monday,\nSunday', // Menggunakan newline untuk dua baris
    'Rest': '5 Min',
  };

  // Skema Warna (sesuai gambar dan konteks sebelumnya)
  static const Color screenBackgroundColor = Color(0xFF1A1A1A);
  static const Color appBarTextColor = Colors.white;
  static const Color cardBackgroundColor = Color(0xFF2C2C2C);
  static const Color chipAndButtonBackgroundColor = Color(0xFFE0C083);
  static const Color chipAndButtonTextColor = Color(0xFF1F1F1F);
  static const Color detailLabelTextColor = Color(0xFFE0E0E0);
  static const Color detailValueTextColor = Color(0xFFE0E0E0);
  static const Color dotColor = chipAndButtonBackgroundColor;

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
          'WORKOUT\nDETAIL',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            height: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: _buildDetailCard(context),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Padding internal kartu utama
      decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExerciseNameChip(exerciseName),
          const SizedBox(height: 28.0),
          _buildDetailsSection(), // Bagian ini yang akan dimodifikasi paddingnya
          const SizedBox(height: 32.0),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildExerciseNameChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: chipAndButtonBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        name.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: chipAndButtonTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    // PERUBAHAN DI SINI: Menambahkan Padding horizontal
    // untuk membuat konten bagian detail tampak lebih ke tengah.
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 35.0), // Tambahan padding kanan-kiri
      child: Column(
        children: details.entries
            .map((entry) => _buildDetailRow(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: detailLabelTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16), // Jarak minimum antara label dan value
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: detailValueTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            text: 'Edit',
            onPressed: () {
              print('Edit button pressed');
            },
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: _buildActionButton(
            text: 'Delete',
            onPressed: () {
              print('Delete button pressed');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: chipAndButtonBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 2,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: chipAndButtonTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
