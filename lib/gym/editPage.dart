import 'package:flutter/material.dart';

class UpdateWorkoutPage extends StatefulWidget {
  final Map<String, String>? existingWorkoutData;

  const UpdateWorkoutPage({
    super.key,
    this.existingWorkoutData,
  });

  @override
  State<UpdateWorkoutPage> createState() => _UpdateWorkoutPageState();
}

class _UpdateWorkoutPageState extends State<UpdateWorkoutPage> {
  late TextEditingController nameController;
  late TextEditingController setController;
  late TextEditingController repetitionController;
  late TextEditingController timeController;
  late TextEditingController dayController;
  late TextEditingController restController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data yang ada jika tersedia
    final data = widget.existingWorkoutData;
    nameController = TextEditingController(text: data?['name'] ?? '');
    setController = TextEditingController(text: data?['set'] ?? '');
    repetitionController =
        TextEditingController(text: data?['repetition'] ?? '');
    timeController = TextEditingController(text: data?['time'] ?? '');
    dayController = TextEditingController(text: data?['day'] ?? '');
    restController = TextEditingController(text: data?['rest'] ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    setController.dispose();
    repetitionController.dispose();
    timeController.dispose();
    dayController.dispose();
    restController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'UPDATE WORKOUT', // Diubah dari CREATE WORKOUT
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
                  backgroundColor: const Color(0xFFE0C083), // Warna tombol
                  padding: const EdgeInsets.symmetric(
                      vertical: 18), // Padding tombol
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(25), // Radius tombol lebih bulat
                  ),
                ),
                onPressed: () {
                  // Tambahkan fungsi update workout di sini
                  final name = nameController.text;
                  final sets = setController.text;
                  final repetitions = repetitionController.text;
                  final time = timeController.text;
                  final day = dayController.text;
                  final rest = restController.text;
                  print('Updating Workout Name: $name');
                  print('Updating Sets: $sets');
                  print('Updating Repetitions: $repetitions');
                  print('Updating Time: $time');
                  print('Updating Day: $day');
                  print('Updating Rest: $rest');
                },
                // Mengubah teks tombol
                child: const Text(
                  'Update Workout', // Diubah dari Save
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
