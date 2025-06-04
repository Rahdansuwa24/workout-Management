import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import package http
import 'dart:convert'; // Untuk jsonEncode dan jsonDecode

// Impor file konfigurasi API Anda
// Pastikan path ini benar: 'package:flutter_uas/api/api.dart' jika itu struktur proyek Anda
import 'package:flutter_uas/api/api.dart';

// Impor flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Enum untuk hari latihan
enum WorkoutDay { senin, selasa, rabu, kamis, jumat, sabtu, minggu }

// Helper untuk mendapatkan nama hari dalam Bahasa Indonesia dari enum
String getDayNameInIndonesian(WorkoutDay day) {
  switch (day) {
    case WorkoutDay.senin:
      return 'senin'; // Sesuaikan dengan nilai yang diharapkan backend jika case sensitive
    case WorkoutDay.selasa:
      return 'selasa';
    case WorkoutDay.rabu:
      return 'rabu';
    case WorkoutDay.kamis:
      return 'kamis';
    case WorkoutDay.jumat:
      return 'jumat';
    case WorkoutDay.sabtu:
      return 'sabtu';
    case WorkoutDay.minggu:
      return 'minggu';
  }
}

class CreateWorkoutPage extends StatefulWidget {
  const CreateWorkoutPage({super.key});

  @override
  State<CreateWorkoutPage> createState() => _CreateWorkoutPageState();
}

class _CreateWorkoutPageState extends State<CreateWorkoutPage> {
  // TextEditingControllers untuk setiap field
  final _nameController = TextEditingController();
  final _bagianController = TextEditingController();
  final _setController = TextEditingController();
  final _repetitionController = TextEditingController();
  final _timeController = TextEditingController();
  final _restController =
      TextEditingController(); // Tetap ada di UI, tapi tidak dikirim

  WorkoutDay? _selectedDay;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final String _baseApiUrl = ApiConfig.baseUrl;
  // Pastikan endpoint ini cocok dengan backend Anda router.post('/store', ...)
  // Jika base URL sudah mengandung /api, dan router backend adalah /workout/store
  // maka endpoint bisa jadi '/workout/store'
  final String _endpoint = '/workout/store';

  final _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    _nameController.dispose();
    _bagianController.dispose();
    _setController.dispose();
    _repetitionController.dispose();
    _timeController.dispose();
    _restController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String fullUrl = _baseApiUrl + _endpoint;

      String? token = await _secureStorage.read(key: 'authToken');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sesi tidak valid (token tidak ditemukan). Silakan login kembali.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final workoutData = {
        'nama_latihan': _nameController.text,
        'bagian_yang_dilatih': _bagianController.text,
        'set_latihan': int.tryParse(_setController.text) ?? 0,
        'repetisi_latihan': int.tryParse(_repetitionController.text) ?? 0,
        'waktu': _timeController.text,
        'hari_latihan': _selectedDay!.name,
      };

      final Map<String, String> headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      print(
          "Mengirim data workout: $workoutData ke $fullUrl"); // Log data yang dikirim

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: headers,
        body: jsonEncode(workoutData),
      );

      print(
          "Respons dari server: ${response.statusCode} - ${response.body}"); // Log respons server

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(responseData['message'] ?? 'Workout berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );
          print(
              "CreateWorkoutPage: Penyimpanan berhasil, akan pop dengan hasil true.");
          if (Navigator.canPop(context)) {
            Navigator.pop(
                context, true); // **PERBAIKAN: Kirim true sebagai hasil**
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sesi berakhir atau tidak valid. Silakan login kembali.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        String errorMessage = 'Gagal menyimpan workout.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] as String? ??
              'Status: ${response.statusCode}';
        } catch (e) {
          print(
              'Error parsing error response body: $e. Body: ${response.body}');
          errorMessage =
              'Gagal menyimpan workout. Status: ${response.statusCode}. Respons tidak valid.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error saat _saveWorkout: $e"); // Log error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // **PERBAIKAN: Tambahkan WillPopScope**
      onWillPop: () async {
        print("CreateWorkoutPage: Tombol kembali sistem ditekan atau swipe.");
        // Kirim 'false' untuk menandakan tidak ada perubahan data eksplisit yang sukses
        Navigator.pop(context, false);
        return true; // Izinkan operasi pop
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              print("CreateWorkoutPage: Tombol back di AppBar ditekan.");
              if (Navigator.canPop(context)) {
                Navigator.pop(
                    context, false); // **PERBAIKAN: Kirim false sebagai hasil**
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Nama Latihan (e.g., Bench Press)',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama latihan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bagianController,
                  hintText: 'Bagian yang Dilatih (e.g., Dada)',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bagian yang dilatih tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _setController,
                  hintText: 'Set',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Set tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Set harus berupa angka';
                    }
                    if (int.parse(value) <= 0) {
                      return 'Set harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _repetitionController,
                  hintText: 'Repetisi',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Repetisi tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Repetisi harus berupa angka';
                    }
                    if (int.parse(value) <= 0) {
                      return 'Repetisi harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _timeController,
                  hintText: 'Waktu (e.g., 30s, 1min)',
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<WorkoutDay>(
                  value: _selectedDay,
                  hint: const Text('Pilih Hari Latihan',
                      style: TextStyle(color: Color(0xFF8A8A8D))),
                  dropdownColor: const Color(0xFF2C2C2E),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color(0xFFE0C083), width: 1.5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.red, width: 2.0),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  items: WorkoutDay.values.map((WorkoutDay day) {
                    return DropdownMenuItem<WorkoutDay>(
                      value: day,
                      child: Text(getDayNameInIndonesian(day)),
                    );
                  }).toList(),
                  onChanged: (WorkoutDay? newValue) {
                    setState(() {
                      _selectedDay = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Hari latihan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0C083),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveWorkout,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF8A8A8D), fontSize: 16),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE0C083), width: 1.5),
          borderRadius: BorderRadius.circular(25),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(25),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      validator: validator,
    );
  }
}
