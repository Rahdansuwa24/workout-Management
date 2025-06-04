import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_uas/api/api.dart'; // Pastikan ini path-nya benar sesuai projectmu

class WorkoutList extends StatefulWidget {
  const WorkoutList({super.key});

  @override
  State<WorkoutList> createState() => _WorkoutListState();
}

class _WorkoutListState extends State<WorkoutList> {
  final List<Map<String, String>> workoutData = [];
  final _storage = const FlutterSecureStorage();

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWorkoutData();
  }

  Future<void> fetchWorkoutData() async {
    try {
      final token = await _storage.read(key: 'authToken');
      print('Token: $token');

      if (token == null) throw Exception("Token tidak ditemukan");

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/workout/workoutlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> workouts = data['data'];

        setState(() {
          workoutData.clear();
          workoutData.addAll(workouts.map<Map<String, String>>((item) {
            return {
              'name': item['nama_latihan']?.toString() ?? 'No Name',
              'sets': item['set_latihan']?.toString() ?? '0',
              'reps': item['repetisi_latihan']?.toString() ?? '0',
              'duration': item['waktu']?.toString() ?? '-',
            };
          }).toList());
          isLoading = false;
          errorMessage = null;
        });
      } else {
        throw Exception('Gagal mengambil data. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      print('Terjadi error: $e');
    }
  }

  int? _selectedIndex;

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
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text(
          'WORKOUT LIST',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!,
                        style: const TextStyle(color: Colors.red)))
                : GridView.builder(
                    itemCount: workoutData.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final item = workoutData[index];
                      final isSelected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: WorkoutCard(
                          exerciseName: item['name']!,
                          sets: item['sets']!,
                          reps: item['reps']!,
                          duration: item['duration']!,
                          isSelected: isSelected,
                          cardBackgroundColor: cardBackgroundColor,
                          chipBackgroundColor: chipBackgroundColor,
                          chipTextColor: chipTextColor,
                          primaryTextColorOnCard: primaryTextColorOnCard,
                          secondaryTextColorOnCard: secondaryTextColorOnCard,
                          onEdit: () {
                            print('Edit item $index');
                          },
                          onDelete: () {
                            print('Delete item $index');
                          },
                        ),
                      );
                    },
                  ),
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
        border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chipBackgroundColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                exerciseName.toUpperCase(),
                style: TextStyle(
                  color: chipTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: primaryTextColorOnCard,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: sets),
                      const TextSpan(
                        text: ' x ',
                        style: TextStyle(
                          fontSize: 32,
                        ),
                      ),
                      TextSpan(text: reps),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration + ' menit',
                  style: TextStyle(
                    color: secondaryTextColorOnCard,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                        color: secondaryTextColorOnCard, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                        color: secondaryTextColorOnCard, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
