import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_uas/api/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color cardBackgroundColor = Color(0xFF2C2C2C);
const Color chipBackgroundColor = Color(0xFFE0C083);
const Color chipTextColor = Colors.black;
const Color primaryTextColorOnCard = Colors.white;
final Color secondaryTextColorOnCard = Colors.grey[350]!;

class DashboardWorkoutCard extends StatelessWidget {
  final String exerciseName;
  final String sets;
  final String reps;
  final String duration;

  const DashboardWorkoutCard({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            exerciseName,
            style: const TextStyle(
              color: primaryTextColorOnCard,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _buildInfoChip('$sets Sets')),
                  const SizedBox(width: 6),
                  Flexible(child: _buildInfoChip('$reps Reps')),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                (double.tryParse(duration) != null && duration.isNotEmpty)
                    ? '$duration Menit'
                    : (duration.isEmpty ? 'N/A' : duration),
                style: TextStyle(
                  color: secondaryTextColorOnCard,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: chipTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, String>> _recommendationWorkouts = [];
  List<Map<String, String>> _userWorkouts = [];
  bool _isLoadingRecommendations = true;
  bool _isLoadingUserWorkouts = true;
  bool _isLoggingOut = false;
  String? _errorMessage;
  String? _loggedInUserName;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchData();
  }

  Future<void> _refreshData() async {
    print("Memulai _refreshData()...");
    if (!mounted) {
      print("_refreshData dipanggil tetapi widget tidak mounted.");
      return;
    }
    setState(() {
      _isLoadingRecommendations = true;
      _isLoadingUserWorkouts = true;
      _errorMessage = null; // Reset error message
    });
    await _loadUserDataAndFetchData();
    print("_refreshData() selesai.");
  }

  Future<void> _loadUserDataAndFetchData() async {
    print("Memulai _loadUserDataAndFetchData()...");
    final token = await _getTokenAndProcessUsername();
    if (!mounted) {
      print(
          "_loadUserDataAndFetchData dipanggil tetapi widget tidak mounted setelah _getTokenAndProcessUsername.");
      return;
    }

    if (token == null) {
      setState(() {
        _errorMessage =
            "Sesi tidak valid atau token tidak ditemukan. Silakan login kembali.";
        _isLoadingRecommendations = false;
        _isLoadingUserWorkouts = false;
      });
      print(
          "Token null di _loadUserDataAndFetchData. Menghentikan fetch data.");
      return;
    }
    await _fetchDashboardWorkoutData(token);
    print("_loadUserDataAndFetchData() selesai.");
  }

  Future<String?> _getTokenAndProcessUsername() async {
    String? token;
    try {
      token = await _storage.read(key: 'authToken');
      if (token == null || token.isEmpty) {
        print("Token tidak ditemukan di secure storage.");
        if (mounted) {
          setState(() {
            _loggedInUserName = null;
          });
        }
        return null;
      }
      print("Token berhasil diambil dari secure storage: $token");

      final storedUsername = await _storage.read(key: 'loggedInUsername');
      if (storedUsername != null && storedUsername.isNotEmpty) {
        if (mounted) {
          setState(() {
            _loggedInUserName = storedUsername;
          });
        }
        print("Username dari storage: $storedUsername");
      } else {
        print(
            "Username tidak ada di storage, akan coba diambil dari API atau set default 'User'.");
      }
      return token;
    } catch (e) {
      print('Error membaca token atau username dari secure storage: $e');
      if (mounted) {
        setState(() {
          _loggedInUserName = null;
          _errorMessage = "Error membaca data sesi: $e";
        });
      }
      return null;
    }
  }

  Future<void> _fetchDashboardWorkoutData(String token) async {
    print("Memulai _fetchDashboardWorkoutData dengan token...");
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Fetch recommendations
    await _fetchData(
      endpoint: '/reccomendation',
      token: token,
      onSuccess: (data, fullResponse) {
        if (mounted) {
          setState(() {
            _recommendationWorkouts = data;
            _isLoadingRecommendations = false;
          });
          print("Rekomendasi berhasil dimuat: ${data.length} item.");
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() {
            _errorMessage = (_errorMessage == null || _errorMessage!.isEmpty)
                ? "Rekomendasi: $message"
                : "$_errorMessage\nRekomendasi: $message";
            _isLoadingRecommendations = false;
          });
          print("Error memuat rekomendasi: $message");
        }
      },
    );

    await _fetchData(
      endpoint: '/',
      token: token,
      onSuccess: (data, Map<String, dynamic>? fullResponse) {
        if (mounted) {
          setState(() {
            _userWorkouts = data;
            _isLoadingUserWorkouts = false;

            final usernameFromResponse = fullResponse?['username'] as String?;
            if (usernameFromResponse != null &&
                usernameFromResponse.isNotEmpty) {
              if (_loggedInUserName == null ||
                  _loggedInUserName == 'User' ||
                  _loggedInUserName != usernameFromResponse) {
                _loggedInUserName = usernameFromResponse;
                _storage.write(
                    key: 'loggedInUsername', value: usernameFromResponse);
                print("Username diperbarui dari API: $usernameFromResponse");
              }
            } else if (_loggedInUserName == null) {
              _loggedInUserName = 'User';
              print(
                  "Username diatur ke default 'User' karena tidak ada dari API atau storage.");
            }
          });
          print("User workouts berhasil dimuat: ${data.length} item.");
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() {
            _errorMessage = (_errorMessage == null || _errorMessage!.isEmpty)
                ? "Workout List: $message"
                : "$_errorMessage\nWorkout List: $message";
            _isLoadingUserWorkouts = false;
          });
          print("Error memuat user workouts: $message");
        }
      },
    );
    print("_fetchDashboardWorkoutData selesai.");
  }

  Future<void> _fetchData({
    required String endpoint,
    required String token,
    required Function(List<Map<String, String>>, Map<String, dynamic>?)
        onSuccess,
    required Function(String) onError,
  }) async {
    final String basePath = '/workout';
    final String apiUrl = '${ApiConfig.baseUrl}$basePath$endpoint';
    print("Fetching data from: $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) {
        print("Widget tidak mounted setelah http.get untuk $apiUrl.");
        return;
      }

      final responseData = jsonDecode(response.body);
      print(
          "API Response for $basePath$endpoint (Status: ${response.statusCode}): $responseData");

      if (response.statusCode == 200) {
        if (responseData['status'] == true && responseData['data'] is List) {
          List<Map<String, String>> workouts =
              (responseData['data'] as List).map((item) {
            if (item is Map) {
              return {
                'id': item['latihan_id']?.toString() ??
                    item['id']?.toString() ??
                    UniqueKey().toString(),
                'exerciseName': item['nama_latihan']?.toString() ?? 'N/A',
                'sets': item['set_latihan']?.toString() ?? '0',
                'reps': item['repetisi_latihan']?.toString() ?? '0',
                'duration': item['waktu']?.toString() ?? 'N/A',
                'bagian_yang_dilatih':
                    item['bagian_yang_dilatih']?.toString() ?? '',
                'hari_latihan': item['hari_latihan']?.toString() ?? '',
              };
            }
            return {
              'id': UniqueKey().toString(),
              'exerciseName': 'Data Tidak Valid',
              'sets': '0',
              'reps': '0',
              'duration': 'N/A'
            };
          }).toList();
          onSuccess(workouts, responseData);
        } else {
          onError(responseData['message']?.toString() ??
              'Format data tidak sesuai atau status dari server adalah false.');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        onError(
            'Sesi tidak valid atau tidak diizinkan (Status: ${response.statusCode}). Silakan login kembali.');
      } else {
        onError(
            'Error ${response.statusCode}: ${responseData['message']?.toString() ?? 'Gagal mengambil data.'}');
      }
    } catch (e) {
      print('Error fetching $apiUrl: $e');
      onError(
          'Tidak dapat terhubung ke server untuk $endpoint. Periksa URL API dan koneksi internet Anda.');
    }
  }

  Future<void> _handleLogout() async {
    if (!mounted) {
      print("Logout: Widget tidak mounted di awal _handleLogout.");
      return;
    }
    setState(() {
      _isLoggingOut = true;
    });

    final String logoutApiEndpoint = '/logout';
    final String logoutUrl = '${ApiConfig.baseUrl}$logoutApiEndpoint';
    print("Attempting backend logout from: $logoutUrl with GET method");

    try {
      final response = await http.get(
        Uri.parse(logoutUrl),
        headers: {},
      );
      if (!mounted) {
        print("Logout: Widget tidak mounted setelah panggilan API logout.");
        return;
      }

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Backend logout success: ${responseData['message']}');
      } else {
        print(
            'Backend logout API call failed or returned unexpected status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          try {
            final responseData = jsonDecode(response.body);
            print('Backend logout error message: ${responseData['message']}');
          } catch (e) {
            print('Backend logout response body (not JSON): ${response.body}');
          }
        }
      }
    } catch (e) {
      print('Error calling backend logout API: $e');
    }

    try {
      await _storage.delete(key: 'authToken');
      await _storage.delete(key: 'loggedInUsername');
      await _storage.delete(key: 'user_id');
      print(
          'Local token, username, and user_id deleted successfully from secure storage.');
    } catch (e) {
      print('Error deleting local data from secure storage: $e');
    }

    if (mounted) {
      print("Logout: Widget mounted. Mencoba navigasi ke /login...");
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    } else {
      print("Logout: Widget tidak mounted sebelum mencoba navigasi ke /login.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: chipBackgroundColor,
        backgroundColor: cardBackgroundColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (_errorMessage != null && _errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16)),
                ),
              const Padding(
                padding:
                    EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
                child: Text(
                  'Recommendation',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              _isLoadingRecommendations
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                              color: chipBackgroundColor)))
                  : _recommendationWorkouts.isEmpty &&
                          (_errorMessage == null ||
                              !_errorMessage!.contains("Rekomendasi:"))
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text('Tidak ada rekomendasi workout saat ini.',
                              style: TextStyle(color: Colors.white70)),
                        )
                      : _workoutCarousel(
                          _recommendationWorkouts,
                          onItemTap: (itemData) {
                            print("Recommendation card tapped: $itemData");
                            Navigator.pushNamed(
                                context, '/detailrecommendation',
                                arguments: itemData);
                          },
                        ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workout List',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result =
                            await Navigator.pushNamed(context, '/listworkout');
                        if (result == true && mounted) {
                          _refreshData();
                        } else if (mounted) {
                          // _refreshData(); // Opsi: refresh juga jika tidak ada hasil true
                        }
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(color: chipBackgroundColor),
                      ),
                    ),
                  ],
                ),
              ),
              _isLoadingUserWorkouts
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                              color: chipBackgroundColor)))
                  : _userWorkouts.isEmpty &&
                          (_errorMessage == null ||
                              !_errorMessage!.contains("Workout List:"))
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text('Anda belum memiliki daftar workout.',
                              style: TextStyle(color: Colors.white70)),
                        )
                      : _workoutCarousel(_userWorkouts),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String displayUserName = _loggedInUserName ?? "User";

    return Stack(
      children: [
        Image.asset(
          'assets/photo-dashboard.png',
          width: double.infinity,
          height: 230,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
                height: 230,
                color: Colors.grey[800],
                child: const Center(
                    child: Text('Gagal memuat gambar header',
                        style: TextStyle(color: Colors.white))));
          },
        ),
        Container(
          height: 230,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome!\n$displayUserName',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                '"WORK HARD DIE HARD"',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        Positioned(
          top: 45,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _isLoggingOut
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.logout,
                          color: Colors.white, size: 28),
                      onPressed: _handleLogout,
                      tooltip: 'Logout',
                    ),
              const Text(
                'PGR',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton(Icons.fitness_center, 'Add Workout', context,
                  () async {
                print(
                    "Tombol 'Add Workout' ditekan. Membuka halaman /create...");
                final result = await Navigator.pushNamed(context, '/create');
                print(
                    "Kembali dari halaman /create. Hasil: $result, Tipe Hasil: ${result.runtimeType}");

                if (!mounted) {
                  print(
                      "DashboardPage tidak lagi mounted setelah kembali dari /create.");
                  return;
                }

                if (result == true) {
                  print("Hasil adalah true. Memanggil _refreshData()...");
                  await _refreshData();
                  print(
                      "_refreshData() selesai dipanggil setelah 'Add Workout'.");
                } else {
                  print(
                      "Hasil dari /create bukan true (nilai: $result). Tidak memanggil _refreshData() secara otomatis.");
                }
              }),
              _actionButton(Icons.calendar_today, 'Schedule', context, () {
                Navigator.pushNamed(context, '/schedule');
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, BuildContext context,
      VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: chipTextColor, size: 20),
      label: Text(label,
          style: const TextStyle(color: chipTextColor, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: chipBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 3,
      ),
    );
  }

  // Modifikasi _workoutCarousel untuk menerima onItemTap callback
  Widget _workoutCarousel(List<Map<String, String>> data,
      {Function(Map<String, String> itemData)? onItemTap}) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          Widget card = DashboardWorkoutCard(
            exerciseName: item['exerciseName']!,
            sets: item['sets']!,
            reps: item['reps']!,
            duration: item['duration']!,
          );

          if (onItemTap != null) {
            return GestureDetector(
              onTap: () => onItemTap(item),
              child: card,
            );
          }
          return card;
        },
      ),
    );
  }
}
