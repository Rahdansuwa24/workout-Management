import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_uas/api/api.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Enum untuk level kesulitan
enum WorkoutLevel { pemula, amatir, mahir }

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _groupedScheduleData = [];
  bool _isLoading = true;
  String? _errorMessage;

  final _storage = const FlutterSecureStorage();

  
  static const Color screenBackgroundColor = Color(0xFF121212);
  static const Color appBarTextColor = Colors.white;
  static const Color bannerTextColor = Colors.white;
  static const Color dayChipBackgroundColor = Color(0xFFE0C083);
  static const Color dayChipTextColor = Color(0xFF1F1F1F);
  static const Color scheduleItemBackgroundColor = Color(0xFF1E1E1E);
  static const Color workoutNameTextColor = Color(0xFFE0E0E0);
  static const Color actionButtonBackgroundColor = Color(0xFF383838);
  static const Color actionButtonTextColor = Color(0xFFE0E0E0);
  static const Color popupBackgroundColor = Color(0xFF2C2C2E);
  static const Color popupTitleColor = Colors.white;
  static const Color popupContentColor = Color(0xFFE0E0E0);
  static const Color popupDetailLabelColor = Color(0xFFB0B0B0);
  static const Color popupOptionTextColor = Color(0xFFE0C083); 

  @override
  void initState() {
    super.initState();
    _fetchAndProcessScheduleData();
  }

  String _getDayAbbreviation(String? dayName) {
    if (dayName == null) return 'N/A';
    switch (dayName.toLowerCase()) {
      case 'senin':
        return 'MON';
      case 'selasa':
        return 'TUE';
      case 'rabu':
        return 'WED';
      case 'kamis':
        return 'THU';
      case 'jumat':
        return 'FRI';
      case 'sabtu':
        return 'SAT';
      case 'minggu':
        return 'SUN';
      default:
        if (dayName.length >= 3) {
          return dayName.substring(0, 3).toUpperCase();
        }
        return dayName.toUpperCase();
    }
  }

  Future<void> _fetchAndProcessScheduleData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null) {
        throw Exception("Token tidak ditemukan. Silakan login kembali.");
      }

      final String scheduleUrl = '${ApiConfig.baseUrl}/workout/popup';
      print("Fetching schedule data from: $scheduleUrl");

      final response = await http.get(
        Uri.parse(scheduleUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print("SchedulePage - Response status: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("SchedulePage - Decoded data from /popup: $responseData");

        if (responseData['status'] == true && responseData['data'] is List) {
          final List<dynamic> allWorkoutsFromServer = responseData['data'];

          Map<String, List<Map<String, dynamic>>> tempGrouped = {};
          for (var workoutItem in allWorkoutsFromServer) {
            if (workoutItem is Map<String, dynamic>) {
              String day =
                  workoutItem['hari_latihan']?.toString() ?? 'Tidak Diketahui';
              if (!tempGrouped.containsKey(day)) {
                tempGrouped[day] = [];
              }
              tempGrouped[day]!.add({
                'latihan_id': workoutItem['latihan_id']?.toString(),
                'nama_latihan':
                    workoutItem['nama_latihan']?.toString() ?? 'N/A',
                'bagian_yang_dilatih':
                    workoutItem['bagian_yang_dilatih']?.toString() ?? '-',
                'set_latihan': workoutItem['set_latihan']?.toString() ?? '0',
                'repetisi_latihan':
                    workoutItem['repetisi_latihan']?.toString() ?? '0',
                'waktu': workoutItem['waktu']?.toString() ?? '0',
              });
            }
          }

          List<String> dayOrder = [
            'senin',
            'selasa',
            'rabu',
            'kamis',
            'jumat',
            'sabtu',
            'minggu'
          ];
          List<Map<String, dynamic>> processedSchedule = [];

          for (String dayKey in dayOrder) {
            if (tempGrouped.containsKey(dayKey)) {
              List<Map<String, dynamic>> workoutsForDay = tempGrouped[dayKey]!;
              processedSchedule.add({
                'day_abbreviation': _getDayAbbreviation(dayKey),
                'original_day_name': dayKey,
                'workouts_summary_string':
                    workoutsForDay.map((w) => w['nama_latihan']).join(', '),
                'detailed_workouts_for_this_day': workoutsForDay,
              });
            }
          }
          tempGrouped.forEach((dayKey, workoutsForDay) {
            if (!dayOrder.contains(dayKey)) {
              processedSchedule.add({
                'day_abbreviation': _getDayAbbreviation(dayKey),
                'original_day_name': dayKey,
                'workouts_summary_string':
                    workoutsForDay.map((w) => w['nama_latihan']).join(', '),
                'detailed_workouts_for_this_day': workoutsForDay,
              });
            }
          });

          setState(() {
            _groupedScheduleData = processedSchedule;
            _isLoading = false;
          });
        } else {
          throw Exception(
              "Format data jadwal tidak sesuai atau status false. Pesan: ${responseData['message']}");
        }
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(
            'Gagal mengambil data jadwal. Status: ${response.statusCode}. Pesan: ${errorBody?['message'] ?? response.body}');
      }
    } catch (e) {
      print("Error fetching schedule data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showScheduleDetailPopup(BuildContext context, String dayFullName,
      List<Map<String, dynamic>> detailedWorkouts) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: popupBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(
            'Detail Jadwal - ${dayFullName.isNotEmpty ? dayFullName[0].toUpperCase() + dayFullName.substring(1) : 'Hari Ini'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: popupTitleColor,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: detailedWorkouts.isEmpty
                ? const Text(
                    'Tidak ada latihan terjadwal untuk hari ini.',
                    style: TextStyle(color: popupContentColor, fontSize: 15),
                    textAlign: TextAlign.center,
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: detailedWorkouts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final workout = detailedWorkouts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout['nama_latihan'] ??
                                  'Nama Latihan Tidak Ada',
                              style: const TextStyle(
                                  color: dayChipBackgroundColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            if (workout['bagian_yang_dilatih'] != null &&
                                workout['bagian_yang_dilatih'] != '-')
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(
                                    'Bagian: ${workout['bagian_yang_dilatih']}',
                                    style: const TextStyle(
                                        color: popupDetailLabelColor,
                                        fontSize: 14)),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                  'Set: ${workout['set_latihan'] ?? '-'}',
                                  style: const TextStyle(
                                      color: popupDetailLabelColor,
                                      fontSize: 14)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                  'Repetisi: ${workout['repetisi_latihan'] ?? '-'}',
                                  style: const TextStyle(
                                      color: popupDetailLabelColor,
                                      fontSize: 14)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                  'Waktu: ${workout['waktu'] ?? '-'} menit',
                                  style: const TextStyle(
                                      color: popupDetailLabelColor,
                                      fontSize: 14)),
                            ),
                            if (index < detailedWorkouts.length - 1)
                              Divider(
                                  color: Colors.grey[800],
                                  height: 16,
                                  thickness: 0.5),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: dayChipBackgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('Tutup',
                  style: TextStyle(
                      color: dayChipTextColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showStartWorkoutOptionsPopup(BuildContext context, String dayFullName,
      List<Map<String, dynamic>> detailedWorkouts) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: popupBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(
            'Pilih Level Kesulitan\nUntuk $dayFullName',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: popupTitleColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                height: 1.3),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            children: WorkoutLevel.values.map((level) {
              String levelName = "";
              int restTime = 0;
              switch (level) {
                case WorkoutLevel.pemula:
                  levelName = "Pemula";
                  restTime = 45;
                  break;
                case WorkoutLevel.amatir:
                  levelName = "Amatir";
                  restTime = 25;
                  break;
                case WorkoutLevel.mahir:
                  levelName = "Mahir";
                  restTime = 15;
                  break;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dayChipBackgroundColor,
                    foregroundColor: dayChipTextColor,
                    minimumSize:
                        const Size(double.infinity, 45), // Tombol full width
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    print(
                        'Level dipilih: $levelName, Waktu Istirahat: $restTime detik');
                    Navigator.pushNamed(
                        context, '/countdown', 
                        arguments: {
                          'levelName': levelName,
                          'restTime': restTime,
                          'dayName': dayFullName,
                          'workoutsForDay': detailedWorkouts,
                        });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Memulai workout $dayFullName (Level: $levelName, Istirahat: $restTime detik) - Simulasi'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  child: Text(levelName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          'SCHEDULE',
          style: TextStyle(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: dayChipBackgroundColor))
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
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: dayChipBackgroundColor),
                        onPressed: _fetchAndProcessScheduleData,
                        icon:
                            const Icon(Icons.refresh, color: dayChipTextColor),
                        label: const Text('Coba Lagi',
                            style: TextStyle(color: dayChipTextColor)),
                      )
                    ],
                  ),
                ))
              : _groupedScheduleData.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Jadwal workout Anda masih kosong.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text(
                          'Tambahkan latihan ke jadwal Anda.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: dayChipBackgroundColor),
                          onPressed: _fetchAndProcessScheduleData,
                          icon: const Icon(Icons.refresh,
                              color: dayChipTextColor),
                          label: const Text('Refresh Jadwal',
                              style: TextStyle(color: dayChipTextColor)),
                        )
                      ],
                    ))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildBannerSection(),
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
        image: DecorationImage(
            image: const AssetImage('assets/photo-schedule.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3), BlendMode.darken)),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.transparent,
                    Colors.black.withOpacity(0.35)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0]),
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
        children: _groupedScheduleData.map((item) {
          return _buildScheduleItem(
              item['day_abbreviation']!,
              item['workouts_summary_string']!,
              item['original_day_name']!,
              item['detailed_workouts_for_this_day']
                  as List<Map<String, dynamic>>);
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleItem(String dayAbbreviation, String workoutSummary,
      String dayFullName, List<Map<String, dynamic>> detailedWorkouts) {
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
                    workoutSummary,
                    style: const TextStyle(
                      color: workoutNameTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      _buildActionButton('Detail', () {
                        _showScheduleDetailPopup(
                            context, dayFullName, detailedWorkouts);
                      }),
                      const SizedBox(width: 8.0),
                      _buildActionButton('Start', () {
                        // Panggil popup opsi start workout
                        _showStartWorkoutOptionsPopup(
                            context, dayFullName, detailedWorkouts);
                      }),
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

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
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
