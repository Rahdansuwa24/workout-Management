import 'package:flutter/material.dart';
import 'dart:async'; // Untuk Timer

class CountdownPage extends StatefulWidget {
  final Map<String, dynamic>? navigationArgs; // Untuk menerima argumen

  const CountdownPage({
    super.key,
    this.navigationArgs, // Jarang digunakan jika rute bernama dipakai dengan benar
  });

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  // Skema Warna
  static const Color screenBackgroundColor = Color(0xFF0A0A0A);
  static const Color appBarTextColor = Colors.white;
  static const Color chipBackgroundColor = Color(0xFFE0C083);
  static const Color chipTextColor = Color(0xFF121212);
  static const Color timerTextColor = Colors.white;
  static const Color setsRepsTextColor = Color(0xFF9E9E9E);
  static const Color startButtonBackgroundColor = chipBackgroundColor;
  static const Color startButtonTextColor = chipTextColor;
  static const Color stopButtonBackgroundColor = Color(0xFF2C2C2C);
  static const Color stopButtonTextColor = Colors.white;

  Timer? _timer;
  int _currentTimerSeconds = 0;
  int _initialWorkoutDurationSeconds = 0;
  int _initialRestDurationSeconds = 0;

  String _displayTime = "00:00";
  String _currentWorkoutName = "Memuat Latihan..."; // Teks awal
  String _currentSetsReps = "-";
  List<Map<String, dynamic>> _workoutsForDay = [];
  int _currentWorkoutIndex = 0;
  bool _isResting = false;
  bool _isTimerRunning = false;
  String _currentLevel = "Pemula";
  bool _isWorkoutSessionFinished = false;
  bool _isInitialized =
      false; // Flag untuk memastikan inisialisasi hanya sekali

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambil argumen dan inisialisasi hanya sekali
    if (!_isInitialized) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      print("CountdownPage - Arguments received: $args");
      if (args is Map<String, dynamic>) {
        _currentLevel = args['levelName'] as String? ?? 'Pemula';
        _initialRestDurationSeconds = args['restTime'] as int? ?? 45;
        _workoutsForDay = List<Map<String, dynamic>>.from(
            args['workoutsForDay'] as List? ?? []);

        if (_workoutsForDay.isNotEmpty) {
          _setupNextWorkout(resetIndex: true);
          // **MULAI TIMER OTOMATIS SETELAH INISIALISASI PERTAMA**
          if (!_isWorkoutSessionFinished && mounted) {
            _startTimer();
          }
        } else {
          _currentWorkoutName = "Tidak Ada Latihan";
          _displayTime = "00:00";
          _currentSetsReps = "-";
          _isWorkoutSessionFinished = true;
          if (mounted) setState(() {}); // Update UI jika tidak ada workout
        }
      } else if (widget.navigationArgs != null) {
        _currentLevel =
            widget.navigationArgs!['levelName'] as String? ?? 'Pemula';
        _initialRestDurationSeconds =
            widget.navigationArgs!['restTime'] as int? ?? 45;
        _workoutsForDay = List<Map<String, dynamic>>.from(
            widget.navigationArgs!['workoutsForDay'] as List? ?? []);
        if (_workoutsForDay.isNotEmpty) {
          _setupNextWorkout(resetIndex: true);
          // **MULAI TIMER OTOMATIS SETELAH INISIALISASI PERTAMA**
          if (!_isWorkoutSessionFinished && mounted) {
            _startTimer();
          }
        } else {
          _currentWorkoutName = "Tidak Ada Latihan";
          _displayTime = "00:00";
          _currentSetsReps = "-";
          _isWorkoutSessionFinished = true;
          if (mounted) setState(() {});
        }
      } else {
        print("CountdownPage - Tidak ada argumen yang diterima!");
        _currentWorkoutName = "Error Memuat Latihan";
        _displayTime = "--:--";
        _isWorkoutSessionFinished = true;
        if (mounted) setState(() {});
      }
      _isInitialized = true;
    }
  }

  void _setupNextWorkout({bool resetIndex = false}) {
    if (resetIndex) {
      _currentWorkoutIndex = 0;
    }

    if (_currentWorkoutIndex < _workoutsForDay.length) {
      final workout = _workoutsForDay[_currentWorkoutIndex];
      _currentWorkoutName = workout['nama_latihan']?.toString() ?? 'N/A';
      _currentSetsReps =
          "${workout['set_latihan']?.toString() ?? '0'} X ${workout['repetisi_latihan']?.toString() ?? '0'}";

      _initialWorkoutDurationSeconds =
          (int.tryParse(workout['waktu']?.toString() ?? '0') ?? 0) * 60;

      if (mounted) {
        setState(() {
          _isResting = false;
          _currentTimerSeconds = _initialWorkoutDurationSeconds;
          _displayTime = _formatTime(_currentTimerSeconds);
          _isWorkoutSessionFinished = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentWorkoutName = "Selesai!";
          _displayTime = "Good\nJob!";
          _currentSetsReps = _currentLevel;
          _isTimerRunning = false;
          _isWorkoutSessionFinished = true;
        });
      }
      _timer?.cancel();
    }
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    if (_isWorkoutSessionFinished) return;

    if (_currentTimerSeconds <= 0) {
      _handleTimerEnd(); // Jika durasi 0, langsung transisi
      return;
    }

    if (mounted) {
      setState(() {
        _isTimerRunning = true;
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentTimerSeconds > 0) {
        if (mounted) {
          setState(() {
            _currentTimerSeconds--;
            _displayTime = _formatTime(_currentTimerSeconds);
          });
        }
      } else {
        _handleTimerEnd();
      }
    });
  }

  void _handleTimerEnd() {
    _timer?.cancel();
    _isTimerRunning = false;
    if (!mounted) return;

    if (!_isResting) {
      print("Workout '${_currentWorkoutName}' selesai, mulai istirahat.");
      setState(() {
        _isResting = true;
        _currentTimerSeconds = _initialRestDurationSeconds;
        _displayTime = _formatTime(_currentTimerSeconds);
      });
      if (_currentTimerSeconds > 0) {
        _startTimer();
      } else {
        print("Tidak ada waktu istirahat, lanjut workout berikutnya.");
        _currentWorkoutIndex++;
        _setupNextWorkout();
        if (!_isWorkoutSessionFinished && mounted) {
          _startTimer();
        }
      }
    } else {
      print("Istirahat selesai, lanjut workout berikutnya.");
      setState(() {
        _isResting = false;
      });
      _currentWorkoutIndex++;
      _setupNextWorkout();
      if (!_isWorkoutSessionFinished && mounted) {
        _startTimer();
      }
    }
  }

  void _stopTimer() {
    // Pause
    if (!mounted) return;
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isTimerRunning = false;
      });
    }
  }

  void _skipToNextPhase() {
    print('Tombol Next ditekan, skip ke fase berikutnya.');
    _timer?.cancel();
    _isTimerRunning = false;
    if (!mounted) return;
    _handleTimerEnd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Tampilkan loading jika belum terinisialisasi dari argumen
      return Scaffold(
        backgroundColor: screenBackgroundColor,
        appBar: AppBar(
          backgroundColor: screenBackgroundColor,
          elevation: 0,
          title:
              const Text('MEMUAT...', style: TextStyle(color: appBarTextColor)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
            child: CircularProgressIndicator(color: chipBackgroundColor)),
      );
    }

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
        title: Text(
          _isWorkoutSessionFinished
              ? "SESI SELESAI"
              : (_isResting ? 'ISTIRAHAT' : 'COUNTDOWN'),
          style: const TextStyle(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _workoutsForDay.isEmpty && !_isWorkoutSessionFinished
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _currentWorkoutName,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(context),
                _buildWorkoutNameChip(_currentWorkoutName),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimerDisplay(
                          _displayTime,
                          _isWorkoutSessionFinished
                              ? "Level: $_currentLevel"
                              : (_isResting
                                  ? "Istirahat - Level: $_currentLevel"
                                  : _currentSetsReps)),
                    ],
                  ),
                ),
                _buildActionButtons(context),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
              ],
            ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    String? imageUrl;
    if (_workoutsForDay.isNotEmpty &&
        _currentWorkoutIndex < _workoutsForDay.length) {
      imageUrl =
          _workoutsForDay[_currentWorkoutIndex]['gambar_url']?.toString() ??
              _workoutsForDay[_currentWorkoutIndex]['image_url']?.toString();
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: MediaQuery.of(context).size.height * 0.35,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error memuat gambar: $error");
          return _defaultImagePlaceholder(context);
        },
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: chipBackgroundColor,
              ),
            ),
          );
        },
      );
    } else {
      return _defaultImagePlaceholder(context);
    }
  }

  Widget _defaultImagePlaceholder(BuildContext context) {
    return Image.asset(
      'assets/incheon.jpg',
      height: MediaQuery.of(context).size.height * 0.35,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.35,
          color: Colors.grey[800],
          child: const Center(
              child: Icon(Icons.image_not_supported,
                  color: Colors.white70, size: 50)),
        );
      },
    );
  }

  Widget _buildWorkoutNameChip(String name) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 20.0, right: 20.0, top: 20.0, bottom: 10.0),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: chipBackgroundColor,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: chipTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(String time, String setsReps) {
    return Column(
      children: [
        Text(
          time,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isResting ? Colors.greenAccent[400] : timerTextColor,
            fontSize: 68,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          setsReps,
          style: const TextStyle(
            color: setsRepsTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              text: _isTimerRunning ? 'Pause' : 'Start',
              backgroundColor: startButtonBackgroundColor,
              textColor: startButtonTextColor,
              onPressed: _isWorkoutSessionFinished
                  ? null
                  : (_isTimerRunning ? _stopTimer : _startTimer),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: _buildButton(
              text: 'Next',
              backgroundColor: stopButtonBackgroundColor,
              textColor: stopButtonTextColor,
              onPressed: _isWorkoutSessionFinished ? null : _skipToNextPhase,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        disabledBackgroundColor: Colors.grey[700],
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 2,
      ),
      child: Text(text),
    );
  }
}
