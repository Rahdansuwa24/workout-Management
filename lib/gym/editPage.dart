import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_uas/api/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Enum untuk hari latihan (sama seperti di CreateWorkoutPage)
enum WorkoutDay { senin, selasa, rabu, kamis, jumat, sabtu, minggu }

String getDayNameInIndonesian(WorkoutDay day) {
  switch (day) {
    case WorkoutDay.senin:
      return 'senin';
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

WorkoutDay? workoutDayFromString(String? dayString) {
  if (dayString == null) return null;
  try {
    return WorkoutDay.values
        .firstWhere((e) => e.name.toLowerCase() == dayString.toLowerCase());
  } catch (e) {
    return null;
  }
}

class UpdateWorkoutPage extends StatefulWidget {
  final Map<String, dynamic>? initialWorkoutDataFromList;

  const UpdateWorkoutPage({
    super.key,
    this.initialWorkoutDataFromList,
  });

  @override
  State<UpdateWorkoutPage> createState() => _UpdateWorkoutPageState();
}

class _UpdateWorkoutPageState extends State<UpdateWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetchingDetails = true;
  String? _fetchError;

  final _storage = const FlutterSecureStorage();

  late TextEditingController _nameController;
  late TextEditingController _bagianController;
  late TextEditingController _setController;
  late TextEditingController _repetitionController;
  late TextEditingController _timeController;
  WorkoutDay? _selectedDay;
  String? _latihanId;

  bool _isInitializedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bagianController = TextEditingController();
    _setController = TextEditingController();
    _repetitionController = TextEditingController();
    _timeController = TextEditingController();

    if (widget.initialWorkoutDataFromList != null) {
      _latihanId = widget.initialWorkoutDataFromList!['id']?.toString();
      print(
          "UpdateWorkoutPage initState - Initial _latihanId from widget.initialWorkoutDataFromList: $_latihanId");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitializedFromArgs) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      print(
          "UpdateWorkoutPage didChangeDependencies - Arguments diterima: $arguments");

      Map<String, dynamic>? dataFromArgs;
      if (arguments is Map<String, dynamic>) {
        dataFromArgs = arguments;
      } else if (widget.initialWorkoutDataFromList != null) {
        dataFromArgs = widget.initialWorkoutDataFromList;
        print(
            "UpdateWorkoutPage didChangeDependencies - Menggunakan initialWorkoutDataFromList karena argumen tidak valid atau null.");
      }

      if (dataFromArgs != null) {
        final idFromArgsOrInitial = dataFromArgs['id']?.toString();
        print(
            "UpdateWorkoutPage didChangeDependencies - idFromArgsOrInitial (dari argumen atau initialData): $idFromArgsOrInitial");

        if (idFromArgsOrInitial != null &&
            idFromArgsOrInitial.isNotEmpty &&
            !idFromArgsOrInitial.startsWith('UniqueKey')) {
          _latihanId = idFromArgsOrInitial;
          print(
              "UpdateWorkoutPage didChangeDependencies - _latihanId di-set menjadi: $_latihanId. Memulai fetch details...");
          _fetchWorkoutDetails(_latihanId!);
        } else {
          print(
              "PERINGATAN: ID Latihan tidak valid dari argumen/initialData: $idFromArgsOrInitial.");
          _handleInitializationError(
              "ID Latihan tidak valid atau tidak ditemukan untuk memuat data.");
        }
      } else {
        _handleInitializationError(
            "Tidak ada data workout yang diterima untuk diedit (argumen dan initialData null).");
      }
      _isInitializedFromArgs = true;
    }
  }

  void _handleInitializationError(String message) {
    print("UpdateWorkoutPage - Initialization Error: $message");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
        Navigator.of(context).pop(false);
      }
    });
    if (mounted) {
      setState(() {
        _isFetchingDetails = false;
        _fetchError = message;
      });
    }
  }

  Future<void> _fetchWorkoutDetails(String id) async {
    if (!mounted) return;
    setState(() {
      _isFetchingDetails = true;
      _fetchError = null;
    });
    print("UpdateWorkoutPage - Memulai _fetchWorkoutDetails untuk ID: $id");

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null) {
        throw Exception(
            "Token tidak ditemukan. Tidak dapat memuat detail workout.");
      }

      final String fetchUrl = '${ApiConfig.baseUrl}/workout/edit/$id';
      print("UpdateWorkoutPage - Fetching details from: $fetchUrl");

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          "UpdateWorkoutPage - Respons fetch details: Status: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print(
            "UpdateWorkoutPage - Data JSON dari fetch details: $responseData"); // Log data JSON

        if (responseData['status'] == true &&
            responseData['data'] is Map<String, dynamic>) {
          _initializeControllers(responseData['data']);
        } else if (responseData['status'] == true &&
            responseData['data'] is List &&
            (responseData['data'] as List).isNotEmpty) {
          print(
              "Peringatan: Backend GET /edit/:id mengembalikan List, mengambil item pertama.");
          _initializeControllers((responseData['data'] as List).first);
        } else {
          throw Exception(
              "Format data detail workout tidak sesuai atau data tidak ditemukan. Pesan dari server: ${responseData['message']}");
        }
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(
            'Gagal memuat detail workout. Status: ${response.statusCode}. Pesan: ${errorBody?['message'] ?? response.body}');
      }
    } catch (e) {
      print("Error saat _fetchWorkoutDetails: $e");
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingDetails = false;
        });
      }
    }
  }

  void _initializeControllers(Map<String, dynamic> data) {
    print(
        "UpdateWorkoutPage - Menginisialisasi controllers dengan data: $data");
    _latihanId = data['latihan_id']?.toString() ?? data['id']?.toString();

    _nameController.text = data['nama_latihan']?.toString() ?? '';
    _bagianController.text = data['bagian_yang_dilatih']?.toString() ?? '';
    _setController.text = data['set_latihan']?.toString() ?? '';
    _repetitionController.text = data['repetisi_latihan']?.toString() ?? '';
    _timeController.text = data['waktu']?.toString() ?? '';
    _selectedDay = workoutDayFromString(data['hari_latihan']?.toString());

    if (_latihanId == null) {
      print(
          "PERINGATAN FINAL: _latihanId tetap null setelah _initializeControllers!");
      _handleInitializationError(
          "Gagal memuat ID latihan untuk diedit setelah fetch.");
    } else {
      print(
          "Controller diinisialisasi. _latihanId: $_latihanId, Nama: ${_nameController.text}, Bagian: ${_bagianController.text}, Set: ${_setController.text}, Rep: ${_repetitionController.text}, Waktu: ${_timeController.text}, Hari: $_selectedDay");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bagianController.dispose();
    _setController.dispose();
    _repetitionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _updateWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_latihanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: ID Latihan tidak ditemukan untuk update.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sesi tidak valid. Silakan login kembali.'),
                backgroundColor: Colors.red),
          );
        }
        throw Exception("Token tidak ditemukan. Silakan login kembali.");
      }

      final String updateUrl =
          '${ApiConfig.baseUrl}/workout/update/$_latihanId';
      print(
          "UpdateWorkoutPage - Mengirim update ke: $updateUrl dengan metode PATCH");

      final updatedData = {
        'nama_latihan': _nameController.text,
        'bagian_yang_dilatih': _bagianController.text,
        'set_latihan': int.tryParse(_setController.text) ?? 0,
        'repetisi_latihan': int.tryParse(_repetitionController.text) ?? 0,
        'waktu': _timeController
            .text, // Pastikan backend bisa handle String atau konversi ke int jika perlu
        'hari_latihan': _selectedDay!.name,
      };
      print("UpdateWorkoutPage - Data yang dikirim untuk update: $updatedData");

      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      print(
          "UpdateWorkoutPage - Respons update dari server: ${response.statusCode} - ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Workout berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Gagal memperbarui workout'};
        throw Exception(
            'Gagal memperbarui workout. Status: ${response.statusCode}. Pesan: ${errorBody['message']}');
      }
    } catch (e) {
      print("Error saat _updateWorkout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              backgroundColor: Colors.red),
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
    if (_isFetchingDetails) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          title: const Text('Memuat Data Workout...',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1A1A1A),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE0C083))),
      );
    }

    if (_fetchError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          title: const Text('Error Memuat Data',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1A1A1A),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text(_fetchError!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_latihanId != null && _latihanId!.isNotEmpty) {
                    _fetchWorkoutDetails(_latihanId!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Tidak dapat mencoba lagi, ID latihan tidak ada.'),
                          backgroundColor: Colors.orange),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text('Coba Lagi',
                    style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0C083)),
              )
            ],
          ),
        )),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        print("UpdateWorkoutPage: Tombol kembali sistem ditekan.");
        Navigator.pop(context, false);
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              print("UpdateWorkoutPage: Tombol back di AppBar ditekan.");
              Navigator.pop(context, false);
            },
          ),
          title: const Text(
            'UPDATE WORKOUT',
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
                  hintText: 'Nama Latihan',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama latihan tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bagianController,
                  hintText: 'Bagian yang Dilatih',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Bagian yang dilatih tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _setController,
                  hintText: 'Set',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Set tidak boleh kosong';
                    if (int.tryParse(value) == null)
                      return 'Set harus berupa angka';
                    if (int.parse(value) <= 0) return 'Set harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _repetitionController,
                  hintText: 'Repetisi',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Repetisi tidak boleh kosong';
                    if (int.tryParse(value) == null)
                      return 'Repetisi harus berupa angka';
                    if (int.parse(value) <= 0)
                      return 'Repetisi harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _timeController,
                  hintText: 'Waktu (e.g., 15, 30)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        int.tryParse(value) == null) {
                      return 'Waktu harus berupa angka jika diisi';
                    }
                    if (value != null &&
                        value.isNotEmpty &&
                        (int.tryParse(value) ?? -1) < 0) {
                      return 'Waktu tidak boleh negatif';
                    }
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
                  decoration: _inputDecoration('Hari Latihan'),
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
                  validator: (value) =>
                      value == null ? 'Hari latihan tidak boleh kosong' : null,
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
                    onPressed: _isLoading ? null : _updateWorkout,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 3))
                        : const Text(
                            'Update Workout',
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: _inputDecoration(hintText),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF8A8A8D), fontSize: 16),
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
    );
  }
}
