import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_uas/api/api.dart';

class WorkoutList extends StatefulWidget {
  const WorkoutList({super.key});

  @override
  State<WorkoutList> createState() => _WorkoutListState();
}

class _WorkoutListState extends State<WorkoutList> {
  List<Map<String, dynamic>> _allWorkoutData = [];
  List<Map<String, dynamic>> _filteredWorkoutData = [];
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedIndex;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDayFilter;

  final List<String> _hariOptions = [
    'Semua Hari',
    'senin',
    'selasa',
    'rabu',
    'kamis',
    'jumat',
    'sabtu',
    'minggu'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDayFilter = _hariOptions.first; // Default ke "Semua Hari"
    _fetchWorkoutData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFiltersAndSearch();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFiltersAndSearch() {
    List<Map<String, dynamic>> tempFilteredList = List.from(_allWorkoutData);

    // Filter berdasarkan hari
    if (_selectedDayFilter != null && _selectedDayFilter != 'Semua Hari') {
      tempFilteredList = tempFilteredList.where((workout) {
        return workout['hari_latihan']?.toString().toLowerCase() ==
            _selectedDayFilter!.toLowerCase();
      }).toList();
    }

    // Filter berdasarkan query pencarian (nama latihan)
    if (_searchQuery.isNotEmpty) {
      tempFilteredList = tempFilteredList.where((workout) {
        final workoutName =
            workout['nama_latihan']?.toString().toLowerCase() ?? '';
        return workoutName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredWorkoutData = tempFilteredList;
    });
  }

  Future<void> _fetchWorkoutData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'authToken');
      print('WorkoutList - Token: $token');

      if (token == null || token.isEmpty) {
        throw Exception("Token tidak ditemukan. Silakan login kembali.");
      }

      final apiUrl = '${ApiConfig.baseUrl}/workout/workoutlist';
      print('WorkoutList - Fetching data from: $apiUrl');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('WorkoutList - Response status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData['data'] != null && decodedData['data'] is List) {
          final List<dynamic> workoutsFromServer = decodedData['data'];

          _allWorkoutData =
              workoutsFromServer.map<Map<String, dynamic>>((item) {
            if (item is Map<String, dynamic>) {
              final latihanId = item['latihan_id']?.toString();
              Map<String, dynamic> processedItem = {
                ...item,
                'id': latihanId ?? UniqueKey().toString(),
                'name': item['nama_latihan']?.toString() ?? 'No Name',
                'sets': item['set_latihan']?.toString() ?? '0',
                'reps': item['repetisi_latihan']?.toString() ?? '0',
                'duration': item['waktu']?.toString() ?? '-',
              };
              processedItem['hari_latihan'] =
                  item['hari_latihan']?.toString()?.toLowerCase() ?? '';

              processedItem.updateAll((key, value) => value?.toString() ?? '');
              processedItem['id'] = latihanId ?? UniqueKey().toString();

              return processedItem;
            }
            return {
              'id': UniqueKey().toString(),
              'name': 'Invalid Data',
              'sets': '0',
              'reps': '0',
              'duration': '-',
              'hari_latihan': ''
            };
          }).toList();

          _applyFiltersAndSearch();
          _isLoading = false;
          _errorMessage = null;
        } else {
          throw Exception(
              "Format data dari server tidak sesuai (field 'data' bukan List atau null). Respons: ${decodedData['message']}");
        }
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(
            'Gagal mengambil data. Status: ${response.statusCode}. Pesan: ${errorBody?['message'] ?? response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
      print('WorkoutList - Terjadi error saat fetch data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetailPage(Map<String, dynamic> workoutItem) {
    print(
        "Navigasi ke detail untuk: ${workoutItem['name']} dengan ID: ${workoutItem['id']}");
    Navigator.pushNamed(context, '/detailworkout', arguments: workoutItem);
  }

  Future<void> _navigateToEditPage(Map<String, dynamic> workoutItem) async {
    print(
        "Navigasi ke edit untuk: ${workoutItem['name']} dengan ID: ${workoutItem['id']}");
    final result =
        await Navigator.pushNamed(context, '/edit', arguments: workoutItem);

    if (!mounted) return;

    if (result == true) {
      print(
          "Kembali dari halaman edit dengan hasil sukses, memuat ulang data...");
      _fetchWorkoutData();
    } else {
      print(
          "Kembali dari halaman edit tanpa perubahan signifikan (hasil: $result).");
    }
  }

  Future<void> _confirmDeleteWorkout(
      Map<String, dynamic> workoutItem, int indexInFilteredData) async {
    final workoutId = workoutItem['id']?.toString();
    if (workoutId == null || workoutId.startsWith('UniqueKey')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: ID workout tidak valid untuk dihapus.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          title: const Text('Konfirmasi Hapus',
              style: TextStyle(color: Colors.white)),
          content: Text(
              'Anda yakin ingin menghapus workout "${workoutItem['name']}"?',
              style: const TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final indexInAllData =
          _allWorkoutData.indexWhere((item) => item['id'] == workoutId);
      if (indexInAllData != -1) {
        await _performDeleteWorkout(workoutId, indexInAllData);
      } else {
        print(
            "Error: Item tidak ditemukan di _allWorkoutData untuk dihapus. ID yang dicari: $workoutId");
        final indexInFilteredForDebug =
            _filteredWorkoutData.indexWhere((item) => item['id'] == workoutId);
        print(
            "Debug: Item ditemukan di _filteredWorkoutData pada index: $indexInFilteredForDebug");
        print("Debug: _allWorkoutData saat ini: $_allWorkoutData");
        print("Debug: _filteredWorkoutData saat ini: $_filteredWorkoutData");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Error: Item tidak ditemukan untuk dihapus (internal).'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _performDeleteWorkout(
      String workoutId, int indexInAllData) async {
    if (!mounted) return;

    // Tampilkan loading indicator sementara (opsional, bisa lebih spesifik per item)
    // setState(() { _isLoading = true; }); // Hindari ini agar tidak mengganggu seluruh list

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null || token.isEmpty) {
        throw Exception("Token tidak ditemukan. Tidak dapat menghapus.");
      }

      final apiUrl = '${ApiConfig.baseUrl}/workout/delete/$workoutId';
      print(
          'WorkoutList - Menghapus workout dari: $apiUrl dengan ID: $workoutId');

      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('WorkoutList - Delete response status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _allWorkoutData.removeAt(indexInAllData);
          _applyFiltersAndSearch();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Workout berhasil dihapus.'),
              backgroundColor: Colors.green),
        );
      } else {
        final responseData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {
                'message':
                    'Gagal menghapus dengan status ${response.statusCode}'
              };
        throw Exception(
            'Gagal menghapus workout. Status: ${response.statusCode}. Pesan: ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      print('WorkoutList - Error saat menghapus workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Gagal menghapus: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}...'),
            backgroundColor: Colors.red),
      );
    } finally {
      // if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBackgroundColor = Color(0xFF2C2C2C);
    const Color chipBackgroundColor = Color(0xFFE0C083);
    const Color chipTextColor = Colors.black;
    const Color primaryTextColorOnCard = Colors.white;
    final Color secondaryTextColorOnCard = Colors.grey[350]!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context, false);
          },
        ),
        title: const Text(
          'WORKOUT LIST',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari nama latihan...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedDayFilter,
                  dropdownColor: const Color(0xFF2C2C2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.calendar_today,
                        color: Colors.grey[400], size: 20),
                  ),
                  items: _hariOptions.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day[0].toUpperCase() + day.substring(1)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDayFilter = newValue;
                      _applyFiltersAndSearch();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: chipBackgroundColor))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 60),
                            const SizedBox(height: 16),
                            Text(_errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: chipBackgroundColor),
                              onPressed: _fetchWorkoutData,
                              icon: const Icon(Icons.refresh,
                                  color: chipTextColor),
                              label: const Text('Coba Lagi',
                                  style: TextStyle(color: chipTextColor)),
                            )
                          ],
                        ))
                      : _filteredWorkoutData.isEmpty
                          ? Center(
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off,
                                    size: 80, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                    _searchQuery.isNotEmpty ||
                                            (_selectedDayFilter != null &&
                                                _selectedDayFilter !=
                                                    'Semua Hari')
                                        ? 'Tidak ada workout yang cocok.'
                                        : 'Belum ada workout.',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 18)),
                                const SizedBox(height: 8),
                                if (!(_searchQuery.isNotEmpty ||
                                    (_selectedDayFilter != null &&
                                        _selectedDayFilter != 'Semua Hari')))
                                  const Text(
                                    'Tambahkan workout baru di halaman dashboard.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: chipBackgroundColor),
                                  onPressed: _fetchWorkoutData,
                                  icon: const Icon(Icons.refresh,
                                      color: chipTextColor),
                                  label: const Text('Refresh Data',
                                      style: TextStyle(color: chipTextColor)),
                                )
                              ],
                            ))
                          : GridView.builder(
                              itemCount: _filteredWorkoutData.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                childAspectRatio:
                                    0.82, // Sedikit diubah untuk memberi ruang lebih
                              ),
                              itemBuilder: (context, index) {
                                final item = _filteredWorkoutData[index];
                                final isSelected = _selectedIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                    _navigateToDetailPage(item);
                                  },
                                  child: WorkoutCard(
                                    exerciseName:
                                        item['name']?.toString() ?? 'N/A',
                                    sets: item['sets']?.toString() ?? '0',
                                    reps: item['reps']?.toString() ?? '0',
                                    duration:
                                        item['duration']?.toString() ?? '-',
                                    isSelected: isSelected,
                                    cardBackgroundColor: cardBackgroundColor,
                                    chipBackgroundColor: chipBackgroundColor,
                                    chipTextColor: chipTextColor,
                                    primaryTextColorOnCard:
                                        primaryTextColorOnCard,
                                    secondaryTextColorOnCard:
                                        secondaryTextColorOnCard,
                                    onEdit: () => _navigateToEditPage(item),
                                    onDelete: () =>
                                        _confirmDeleteWorkout(item, index),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final String exerciseName;
  final String sets;
  final String reps;
  final String duration;
  final bool isSelected;
  final Color cardBackgroundColor;
  final Color chipBackgroundColor;
  final Color chipTextColor;
  final Color primaryTextColorOnCard;
  final Color secondaryTextColorOnCard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WorkoutCard({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.duration,
    this.isSelected = false,
    required this.cardBackgroundColor,
    required this.chipBackgroundColor,
    required this.chipTextColor,
    required this.primaryTextColorOnCard,
    required this.secondaryTextColorOnCard,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: isSelected
            ? Border.all(color: Colors.blueAccent, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipBackgroundColor,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                exerciseName.toUpperCase(),
                style: TextStyle(
                  color: chipTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: primaryTextColorOnCard,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily:
                            DefaultTextStyle.of(context).style.fontFamily,
                      ),
                      children: <TextSpan>[
                        TextSpan(text: sets),
                        const TextSpan(
                          text: ' x ',
                          style: TextStyle(
                            fontSize: 28,
                          ),
                        ),
                        TextSpan(text: reps),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (double.tryParse(duration) != null &&
                            duration.isNotEmpty &&
                            duration != '-')
                        ? '$duration menit'
                        : (duration == '-' || duration.isEmpty
                            ? 'Durasi N/A'
                            : duration),
                    style: TextStyle(
                      color: secondaryTextColorOnCard,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceAround, // Default, bisa diubah jika perlu
              children: <Widget>[
                // Menggunakan Flexible agar tombol bisa menyesuaikan ruang
                Flexible(
                    child: _buildActionButton(context, Icons.edit_note, 'Edit',
                        onEdit, secondaryTextColorOnCard)),
                const SizedBox(width: 4), // Jarak antar tombol
                Flexible(
                    child: _buildActionButton(
                        context,
                        Icons.delete_sweep_outlined,
                        'Delete',
                        onDelete,
                        Colors.redAccent[100]!)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      VoidCallback onPressed, Color color) {
    return TextButton.icon(
      icon: Icon(icon, size: 16, color: color), // Ukuran ikon disesuaikan
      label: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: onPressed,
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          minimumSize: const Size(50, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }
}
