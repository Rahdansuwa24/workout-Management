import 'package:flutter/material.dart';

class CreateWorkoutPage extends StatelessWidget {
  const CreateWorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TextEditingControllers untuk setiap field
    final nameController = TextEditingController();
    final setController = TextEditingController();
    final repetitionController = TextEditingController();
    final timeController = TextEditingController();
    final dayController = TextEditingController();
    final restController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Warna background utama
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A), // Warna AppBar
        elevation: 0, // Hilangkan shadow AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'CREATE WORKOUT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20), // Jarak dari AppBar
            _buildTextField(
              controller: nameController,
              hintText: 'Name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: setController,
              hintText: 'Set',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: repetitionController,
              hintText: 'Repetition',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: timeController,
              hintText: 'Time',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: dayController,
              hintText: 'Day',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: restController,
              hintText: 'Rest',
            ),
            const SizedBox(height: 40), // Jarak sebelum tombol Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0C083), // Warna tombol Save
                  padding: const EdgeInsets.symmetric(
                      vertical: 18), // Padding tombol
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(25), // Radius tombol lebih bulat
                  ),
                ),
                onPressed: () {
                  // Tambahkan fungsi save workout di sini
                  final name = nameController.text;
                  final sets = setController.text;
                  final repetitions = repetitionController.text;
                  final time = timeController.text;
                  final day = dayController.text;
                  final rest = restController.text;

                  // Contoh print data
                  print('Workout Name: $name');
                  print('Sets: $sets');
                  print('Repetitions: $repetitions');
                  print('Time: $time');
                  print('Day: $day');
                  print('Rest: $rest');
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20), // Jarak tambahan di bawah
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF8A8A8D), fontSize: 16),
        filled: true,
        fillColor: const Color(0xFF2C2C2E), // Warna fill TextField
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18), // Padding konten
        border: OutlineInputBorder(
          borderSide: BorderSide.none, // Hilangkan border default
          borderRadius:
              BorderRadius.circular(25), // Radius border TextField lebih bulat
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none, // Hilangkan border saat enabled
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          // Border saat TextField aktif/fokus
          borderSide: const BorderSide(
              color: Color(0xFFE0C083), width: 1.5), // Warna border kuning
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }
}
