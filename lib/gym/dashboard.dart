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
                (double.tryParse(duration) != null)
                    ? '$duration Menit'
                    : duration,
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

  Future<void> _loadUserDataAndFetchData() async {
    final token = await _getTokenAndProcessUsername();
    if (!mounted) return;

    if (token == null) {
      setState(() {
        _errorMessage =
            "Sesi tidak valid atau token tidak ditemukan. Silakan login kembali.";
        _isLoadingRecommendations = false;
        _isLoadingUserWorkouts = false;
      });
      return;
    }
    _fetchDashboardWorkoutData(token);
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
        if (mounted) {
          setState(() {
            _loggedInUserName = 'User';
          });
        }
      }
      return token;
    } catch (e) {
      print('Error membaca token atau username dari secure storage: $e');
      if (mounted) {
        setState(() {
          _loggedInUserName = null;
        });
      }
      return null;
    }
  }

  Future<void> _fetchDashboardWorkoutData(String token) async {
    await _fetchData(
      endpoint: '/reccomendation',
      token: token,
      onSuccess: (data, fullResponse) {
        if (mounted) {
          setState(() {
            _recommendationWorkouts = data;
            _isLoadingRecommendations = false;
          });
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() {
            _errorMessage = message;
            _isLoadingRecommendations = false;
          });
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
              }
            }
          });
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() {
            _errorMessage = (_errorMessage == null || _errorMessage!.isEmpty)
                ? message
                : "$_errorMessage\n$message";
            _isLoadingUserWorkouts = false;
          });
        }
      },
    );
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

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      print(
          "API Response for $endpoint (Status: ${response.statusCode}): $responseData");

      if (response.statusCode == 200) {
        if (responseData['status'] == true && responseData['data'] is List) {
          List<Map<String, String>> workouts =
              (responseData['data'] as List).map((item) {
            // ** PERBAIKAN MAPPING FIELD **
            return {
              'exerciseName': item['nama_latihan']?.toString() ?? 'N/A',
              'sets': item['set_latihan']?.toString() ?? '0',
              'reps': item['repetisi_latihan']?.toString() ?? '0',
              'duration': item['waktu']?.toString() ?? 'N/A',
            };
          }).toList();
          onSuccess(workouts, responseData);
        } else {
          onError(responseData['message']?.toString() ??
              'Format data tidak sesuai atau status false.');
        }
      } else {
        onError(
            'Error ${response.statusCode}: ${responseData['message']?.toString() ?? 'Gagal mengambil data.'}');
      }
    } catch (e) {
      print('Error fetching $apiUrl: $e');
      onError(
          'Tidak dapat terhubung ke server untuk $endpoint. Periksa URL dan koneksi.');
    }
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    setState(() {
      _isLoggingOut = true;
    });

    final String logoutApiEndpoint = '/auth/logout';
    final String logoutUrl = '${ApiConfig.baseUrl}$logoutApiEndpoint';

    try {
      final response = await http.get(
        Uri.parse(logoutUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (!mounted) return;

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
      print(
          'Local token and username deleted successfully from secure storage.');
    } catch (e) {
      print('Error deleting local token/username from secure storage: $e');
    }

    if (mounted) {
      setState(() {
        _isLoggingOut = false;
        _loggedInUserName = null;
      });
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SingleChildScrollView(
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
                        (_errorMessage == null || _errorMessage!.isEmpty)
                    ? const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text('Tidak ada rekomendasi workout saat ini.',
                            style: TextStyle(color: Colors.white70)),
                      )
                    : _workoutCarousel(_recommendationWorkouts),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                    onTap: () {
                      Navigator.pushNamed(context, '/listworkout');
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
                        (_errorMessage == null || _errorMessage!.isEmpty)
                    ? const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text('Anda belum memiliki daftar workout.',
                            style: TextStyle(color: Colors.white70)),
                      )
                    : _workoutCarousel(_userWorkouts),
            const SizedBox(height: 20),
          ],
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
              _actionButton(Icons.fitness_center, 'Add Workout', context, () {
                print('Add Workout Tapped');
              }),
              _actionButton(Icons.calendar_today, 'Schedule', context, () {
                print('Schedule Tapped');
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

  Widget _workoutCarousel(List<Map<String, String>> data) {
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
          return DashboardWorkoutCard(
            exerciseName: item['exerciseName']!,
            sets: item['sets']!,
            reps: item['reps']!,
            duration: item['duration']!,
          );
        },
      ),
    );
  }
}
