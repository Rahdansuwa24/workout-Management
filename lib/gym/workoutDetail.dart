import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_uas/api/api.dart'; // Pastikan path ini benar

class WorkoutDetail extends StatefulWidget {
  // Data awal yang mungkin dikirim dari halaman list,
  // terutama untuk mendapatkan 'id' (latihan_id)
  final Map<String, dynamic>? initialWorkoutData;

  const WorkoutDetail({
    super.key,
    this.initialWorkoutData,
  });

  @override
  State<WorkoutDetail> createState() => _WorkoutDetailState();
}

class _WorkoutDetailState extends State<WorkoutDetail> {
  Map<String, dynamic>? _workoutDetailsData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _latihanId;

  final _storage = const FlutterSecureStorage();

  // Skema Warna
  static const Color screenBackgroundColor = Color(0xFF1A1A1A);
  static const Color appBarTextColor = Colors.white;
  static const Color cardBackgroundColor = Color(0xFF2C2C2C);
  static const Color chipAndButtonBackgroundColor = Color(0xFFE0C083);
  static const Color chipAndButtonTextColor = Color(0xFF1F1F1F);
  static const Color detailLabelTextColor =
      Color(0xFFE0E0E0); // Warna lebih terang untuk label
  static const Color detailValueTextColor =
      Colors.white; // Warna putih untuk nilai agar kontras
  static const Color dotColor = chipAndButtonBackgroundColor;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Jika data awal ada dari konstruktor (jarang jika pakai argumen rute)
    if (widget.initialWorkoutData != null) {
      _latihanId = widget.initialWorkoutData!['id']?.toString();
      print(
          "WorkoutDetail initState - Initial _latihanId from widget.initialWorkoutData: $_latihanId");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      print(
          "WorkoutDetail didChangeDependencies - Arguments diterima: $arguments");

      Map<String, dynamic>? dataFromArgs;
      if (arguments is Map<String, dynamic>) {
        dataFromArgs = arguments;
      } else if (widget.initialWorkoutData != null) {
        // Fallback jika argumen tidak ada/tidak valid, gunakan data dari konstruktor
        dataFromArgs = widget.initialWorkoutData;
        print(
            "WorkoutDetail didChangeDependencies - Menggunakan initialWorkoutData karena argumen tidak valid atau null.");
      }

      if (dataFromArgs != null) {
        // 'id' yang dikirim dari WorkoutList adalah 'latihan_id'
        final idFromArgs = dataFromArgs['id']?.toString();
        print(
            "WorkoutDetail didChangeDependencies - idFromArgs (dari argumen atau initialData): $idFromArgs");

        if (idFromArgs != null &&
            idFromArgs.isNotEmpty &&
            !idFromArgs.startsWith('UniqueKey')) {
          _latihanId = idFromArgs;
          print(
              "WorkoutDetail didChangeDependencies - _latihanId di-set menjadi: $_latihanId. Memulai fetch details...");
          _fetchWorkoutDetails(_latihanId!);
        } else {
          // Jika _latihanId dari initState sudah ada (dari widget.initialWorkoutData) dan valid, gunakan itu
          if (_latihanId != null &&
              _latihanId!.isNotEmpty &&
              !_latihanId!.startsWith('UniqueKey')) {
            print(
                "WorkoutDetail didChangeDependencies - Menggunakan _latihanId dari initState: $_latihanId. Memulai fetch details...");
            _fetchWorkoutDetails(_latihanId!);
          } else {
            print(
                "PERINGATAN: ID Latihan tidak valid dari argumen/initialData: $idFromArgs.");
            _handleFetchError(
                "ID Latihan tidak valid atau tidak ditemukan untuk memuat detail.");
          }
        }
      } else {
        _handleFetchError(
            "Tidak ada data workout yang diterima untuk ditampilkan detailnya.");
      }
      _isInitialized = true;
    }
  }

  void _handleFetchError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    }
  }

  Future<void> _fetchWorkoutDetails(String id) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print("WorkoutDetail - Memulai _fetchWorkoutDetails untuk ID: $id");

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null) {
        throw Exception(
            "Token tidak ditemukan. Tidak dapat memuat detail workout.");
      }

      // Menggunakan endpoint GET /api/workout/edit/:id (sesuai info Anda)
      final String fetchUrl = '${ApiConfig.baseUrl}/workout/edit/$id';
      print("WorkoutDetail - Fetching details from: $fetchUrl");

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          "WorkoutDetail - Respons fetch details: Status: ${response.statusCode}");
      // print("WorkoutDetail - Respons fetch details Body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("WorkoutDetail - Data JSON dari fetch details: $responseData");

        if (responseData['status'] == true) {
          if (responseData['data'] is Map<String, dynamic>) {
            setState(() {
              _workoutDetailsData = responseData['data'];
              _isLoading = false;
            });
          } else if (responseData['data'] is List &&
              (responseData['data'] as List).isNotEmpty) {
            // Jika backend mengembalikan list dengan satu item untuk get by ID
            print(
                "WorkoutDetail - Peringatan: Backend GET /edit/:id mengembalikan List, mengambil item pertama.");
            setState(() {
              _workoutDetailsData =
                  (responseData['data'] as List).first as Map<String, dynamic>;
              _isLoading = false;
            });
          } else {
            throw Exception(
                "Format data detail workout tidak sesuai atau data kosong. Respons: ${responseData['message']}");
          }
        } else {
          throw Exception(
              "Gagal memuat detail: ${responseData['message'] ?? 'Status false dari server.'}");
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
        _handleFetchError(e.toString());
      }
    }
  }

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: chipAndButtonBackgroundColor))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(_errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_latihanId != null && _latihanId!.isNotEmpty) {
                              _fetchWorkoutDetails(_latihanId!);
                            }
                          },
                          icon: const Icon(Icons.refresh,
                              color: chipAndButtonTextColor),
                          label: const Text('Coba Lagi',
                              style: TextStyle(color: chipAndButtonTextColor)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: chipAndButtonBackgroundColor),
                        )
                      ],
                    ),
                  ),
                )
              : _workoutDetailsData != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildDetailCard(context, _workoutDetailsData!),
                    )
                  : const Center(
                      child: Text('Tidak ada data detail workout.',
                          style: TextStyle(color: Colors.white70))),
    );
  }

  Widget _buildDetailCard(BuildContext context, Map<String, dynamic> details) {
    final String exerciseName =
        details['nama_latihan']?.toString() ?? 'Nama Latihan Tidak Ada';

    // Siapkan data untuk ditampilkan di detail row
    // Sesuaikan key ini dengan field yang ada di `details` dari backend
    Map<String, String> displayDetails = {
      'Bagian Dilatih': details['bagian_yang_dilatih']?.toString() ?? '-',
      'Set': details['set_latihan']?.toString() ?? '0',
      'Repetisi': details['repetisi_latihan']?.toString() ?? '0',
      'Waktu': "${details['waktu']?.toString() ?? '-'} menit",
      'Hari': details['hari_latihan']?.toString() ?? '-',
      // 'Rest' tidak ada di output Postman Anda, jadi saya akan hilangkan atau beri nilai default
      // 'Rest': details['rest_time']?.toString() ?? 'N/A',
    };

    return Container(
      padding: const EdgeInsets.all(16.0),
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
          _buildDetailsSection(displayDetails),
          const SizedBox(height: 32.0),
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

  Widget _buildDetailsSection(Map<String, String> detailsToDisplay) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 15.0), // Padding disesuaikan
      child: Column(
        children: detailsToDisplay.entries
            .map((entry) => _buildDetailRow(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 12.0), // Padding vertikal ditambah
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            CrossAxisAlignment.start, // Agar teks panjang bisa wrap dengan baik
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: detailValueTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600, // Value dibuat lebih bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}
