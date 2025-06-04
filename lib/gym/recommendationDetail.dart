import 'package:flutter/material.dart';
import 'package:flutter_uas/gym/createPaget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_uas/api/api.dart'; // Pastikan path ini benar

class RecommendationDetail extends StatefulWidget {
  final Map<String, dynamic>? initialRecommendationData;

  const RecommendationDetail({
    super.key,
    this.initialRecommendationData,
  });

  @override
  State<RecommendationDetail> createState() => _RecommendationDetailState();
}

class _RecommendationDetailState extends State<RecommendationDetail> {
  Map<String, dynamic>? _detailedData;
  bool _isLoadingDetails = true;
  String? _detailErrorMessage;
  String? _recommendationId;

  List<Map<String, dynamic>> _fetchedComments = [];
  bool _isLoadingComments =
      true; // Awalnya true sampai komentar selesai di-load
  String? _commentsErrorMessage;
  bool _isPostingComment = false;

  final _storage = const FlutterSecureStorage();
  final TextEditingController _commentController = TextEditingController();

  // Skema Warna
  static const Color screenBackgroundColor = Color(0xFF121212);
  static const Color appBarTextColor = Colors.white;
  static const Color cardBackgroundColor = Color(0xFF1E1E1E);
  static const Color chipAndButtonBackgroundColor = Color(0xFFE0C083);
  static const Color chipAndButtonTextColor = Color(0xFF121212);
  static const Color detailLabelTextColor = Color(0xFFB0B0B0);
  static const Color detailValueTextColor = Color(0xFFE0E0E0);
  static const Color dotColor = chipAndButtonBackgroundColor;
  static const Color commentsTitleColor = Colors.white;
  static const Color commentItemBackgroundColor = Color(0xFF2C2C2C);
  static const Color commenterNameColor = Color(0xFFE0E0E0);
  static const Color commentTextColor = Color(0xFFB0B0B0);
  static const Color textFieldBorderColor = Color(0xFF4A4A4A);
  static const Color textFieldHintColor = Color(0xFF757575);

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecommendationData != null) {
      _recommendationId = widget.initialRecommendationData!['id']?.toString();
      print(
          "RecommendationDetail initState - Initial _recommendationId from widget.initialRecommendationData: $_recommendationId");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      print(
          "RecommendationDetail didChangeDependencies - Arguments diterima: $arguments");

      Map<String, dynamic>? dataFromArgs;
      if (arguments is Map<String, dynamic>) {
        dataFromArgs = arguments;
      } else if (widget.initialRecommendationData != null) {
        dataFromArgs = widget.initialRecommendationData;
        print(
            "RecommendationDetail didChangeDependencies - Menggunakan initialRecommendationData karena argumen tidak valid atau null.");
      }

      if (dataFromArgs != null) {
        final idFromArgs = dataFromArgs['id']?.toString();
        print(
            "RecommendationDetail didChangeDependencies - idFromArgs (dari argumen atau initialData): $idFromArgs");

        if (idFromArgs != null &&
            idFromArgs.isNotEmpty &&
            !idFromArgs.startsWith('UniqueKey')) {
          _recommendationId = idFromArgs;
          print(
              "RecommendationDetail didChangeDependencies - _recommendationId di-set menjadi: $_recommendationId. Memulai fetch details dan comments...");
          _fetchRecommendationDetailsAndComments(_recommendationId!);
        } else {
          if (_recommendationId != null &&
              _recommendationId!.isNotEmpty &&
              !_recommendationId!.startsWith('UniqueKey')) {
            print(
                "RecommendationDetail didChangeDependencies - Menggunakan _recommendationId dari initState: $_recommendationId. Memulai fetch details dan comments...");
            _fetchRecommendationDetailsAndComments(_recommendationId!);
          } else {
            print(
                "PERINGATAN: ID Rekomendasi tidak valid dari argumen/initialData: $idFromArgs.");
            _handleFetchError(
                "ID Rekomendasi tidak valid atau tidak ditemukan untuk memuat detail.",
                true);
            _handleFetchError(
                "Tidak dapat memuat komentar karena ID Rekomendasi tidak valid.",
                false); // Juga set error untuk komentar
          }
        }
      } else {
        _handleFetchError(
            "Tidak ada data rekomendasi yang diterima untuk ditampilkan detailnya.",
            true);
        _handleFetchError(
            "Tidak dapat memuat komentar karena tidak ada data rekomendasi.",
            false); // Juga set error untuk komentar
      }
      _isInitialized = true;
    }
  }

  void _handleFetchError(String message, bool isDetailError) {
    if (mounted) {
      setState(() {
        if (isDetailError) {
          _isLoadingDetails = false;
          _detailErrorMessage = message;
        } else {
          _isLoadingComments = false;
          _commentsErrorMessage = message;
        }
      });
    }
  }

  Future<void> _fetchRecommendationDetailsAndComments(String id) async {
    // Fetch details dulu
    await _fetchRecommendationDetails(id);
    // Hanya fetch komentar jika detail berhasil dimuat dan ID rekomendasi valid
    if (mounted && _detailedData != null && _recommendationId != null) {
      await _fetchComments(_recommendationId!);
    } else if (mounted && _recommendationId != null) {
      // Jika detail gagal tapi ID ada, tetap coba fetch komentar (atau set error)
      // Tergantung apakah komentar bisa ada tanpa detail workout yang valid
      _handleFetchError(
          "Detail workout gagal dimuat, komentar mungkin tidak relevan atau tidak dapat dimuat.",
          false);
    }
  }

  Future<void> _fetchRecommendationDetails(String id) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDetails = true;
      _detailErrorMessage = null;
    });
    print(
        "RecommendationDetail - Memulai _fetchRecommendationDetails untuk ID: $id");

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null) {
        throw Exception(
            "Token tidak ditemukan. Tidak dapat memuat detail rekomendasi.");
      }

      // Endpoint untuk mengambil detail workout/rekomendasi
      final String fetchUrl = '${ApiConfig.baseUrl}/workout/edit/$id';
      print("RecommendationDetail - Fetching details from: $fetchUrl");

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },
      );

      print(
          "RecommendationDetail - Respons fetch details: Status: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print(
            "RecommendationDetail - Data JSON dari fetch details: $responseData");

        if (responseData['status'] == true) {
          dynamic dataPayload = responseData['data'];
          Map<String, dynamic>? workoutData;

          if (dataPayload is Map<String, dynamic>) {
            workoutData = dataPayload;
          } else if (dataPayload is List &&
              dataPayload.isNotEmpty &&
              dataPayload.first is Map<String, dynamic>) {
            workoutData = dataPayload.first;
          }

          if (workoutData != null) {
            setState(() {
              _detailedData = workoutData;
              _isLoadingDetails = false;
            });
          } else {
            throw Exception(
                "Format data detail rekomendasi tidak sesuai atau data kosong. Respons: ${responseData['message']}");
          }
        } else {
          throw Exception(
              "Gagal memuat detail: ${responseData['message'] ?? 'Status false dari server.'}");
        }
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(
            'Gagal memuat detail rekomendasi. Status: ${response.statusCode}. Pesan: ${errorBody?['message'] ?? response.body}');
      }
    } catch (e) {
      print("Error saat _fetchRecommendationDetails: $e");
      if (mounted) _handleFetchError(e.toString(), true);
    }
  }

  Future<void> _fetchComments(String latihanId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingComments = true;
      _commentsErrorMessage = null;
      _fetchedComments.clear(); // Kosongkan komentar lama sebelum fetch baru
    });
    print(
        "RecommendationDetail - Memulai _fetchComments untuk latihan_id: $latihanId");

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null)
        throw Exception("Token tidak ditemukan untuk mengambil komentar.");

      // **ASUMSI ENDPOINT BARU**: Anda perlu endpoint ini di backend: GET /api/komentar/latihan/:latihan_id
      final String fetchUrl =
          '${ApiConfig.baseUrl}/komentar/latihan/$latihanId';
      print("RecommendationDetail - Fetching comments from: $fetchUrl");

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },
      );

      print(
          "RecommendationDetail - Respons fetch comments: Status: ${response.statusCode}");
      // print("RecommendationDetail - Respons fetch comments Body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print(
            "RecommendationDetail - Data JSON dari fetch comments: $responseData");
        if (responseData['status'] == true && responseData['data'] is List) {
          List<Map<String, dynamic>> comments = List<Map<String, dynamic>>.from(
              (responseData['data'] as List).map((item) {
            // Asumsi backend mengirim 'username' dari join dengan tabel users, dan 'komentar'
            return {
              'name': item['username']?.toString() ?? 'Anonim',
              'comment': item['komentar']?.toString() ?? '',
              'created_at': item['created_at']?.toString() ?? '',
            };
          }));
          setState(() {
            _fetchedComments = comments;
            _isLoadingComments = false;
          });
        } else {
          if (responseData['status'] == true && responseData['data'] == null) {
            setState(() {
              _fetchedComments = [];
              _isLoadingComments = false;
            });
            print(
                "RecommendationDetail - Tidak ada komentar untuk latihan_id: $latihanId");
          } else {
            throw Exception(
                "Format data komentar tidak sesuai atau data kosong. Pesan: ${responseData['message']}");
          }
        }
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(
            'Gagal memuat komentar. Status: ${response.statusCode}. Pesan: ${errorBody?['message'] ?? response.body}');
      }
    } catch (e) {
      print("Error saat _fetchComments: $e");
      if (mounted) _handleFetchError(e.toString(), false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Komentar tidak boleh kosong.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_recommendationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('ID Latihan tidak ditemukan untuk mengirim komentar.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isPostingComment = true);

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null) throw Exception("Token tidak ditemukan.");

      final String postUrl = '${ApiConfig.baseUrl}/komentar/store';

      final Map<String, dynamic> commentData = {
        'komentar': _commentController.text,
        'id_latihan': _recommendationId,
      };
      print(
          "RecommendationDetail - Mengirim komentar: $commentData ke $postUrl");

      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(commentData),
      );

      print(
          "RecommendationDetail - Respons post comment: Status: ${response.statusCode} - Body: ${response.body}");

      if (!mounted) return;

      final responseData =
          jsonDecode(response.body); // Selalu coba decode body untuk pesan

      if (response.statusCode == 201) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['message'] ?? 'Komentar berhasil dikirim!'),
              backgroundColor: Colors.green),
        );
        _fetchComments(_recommendationId!);
      } else if (response.statusCode == 403) {
        // **PERBAIKAN: Tangani status 403**
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  'Gagal mengirim komentar: Batas maksimal tercapai.'),
              backgroundColor: Colors.orange),
        );
      } else {
        throw Exception(
            'Gagal mengirim komentar. Status: ${response.statusCode}. Pesan: ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      print("Error saat mengirim komentar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengirim komentar: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _addRecommendationToMyWorkouts() async {
    if (_detailedData == null || _recommendationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data rekomendasi tidak lengkap untuk ditambahkan.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {/* Bisa tambahkan state loading untuk tombol Add */});

    try {
      final token = await _storage.read(key: 'authToken');
      if (token == null) throw Exception("Token tidak ditemukan.");

      final String addUrl = '${ApiConfig.baseUrl}/workout/store';

      final Map<String, dynamic> workoutToAdd = {
        'nama_latihan': _detailedData!['nama_latihan'] ?? 'N/A',
        'bagian_yang_dilatih': _detailedData!['bagian_yang_dilatih'] ?? 'N/A',
        'set_latihan':
            int.tryParse(_detailedData!['set_latihan']?.toString() ?? '0') ?? 0,
        'repetisi_latihan': int.tryParse(
                _detailedData!['repetisi_latihan']?.toString() ?? '0') ??
            0,
        'waktu': _detailedData!['waktu']?.toString() ?? '0',
        'hari_latihan':
            _detailedData!['hari_latihan']?.toString() ?? WorkoutDay.senin.name,
      };
      print(
          "RecommendationDetail - Menambahkan workout: $workoutToAdd ke $addUrl");

      final response = await http.post(
        Uri.parse(addUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(workoutToAdd),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  'Rekomendasi berhasil ditambahkan ke workout Anda!'),
              backgroundColor: Colors.green),
        );
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(
            'Gagal menambahkan rekomendasi. Status: ${response.statusCode}. Pesan: ${errorBody?['message'] ?? response.body}');
      }
    } catch (e) {
      print("Error saat menambahkan rekomendasi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menambahkan: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      // if (mounted) setState(() { /* Reset state loading tombol Add */ });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text(
          'RECOMMENDATION\nDETAIL',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: appBarTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              height: 1.2),
        ),
        centerTitle: true,
      ),
      body: _isLoadingDetails
          ? const Center(
              child: CircularProgressIndicator(
                  color: chipAndButtonBackgroundColor))
          : _detailErrorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(_detailErrorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_recommendationId != null &&
                                _recommendationId!.isNotEmpty) {
                              _fetchRecommendationDetailsAndComments(
                                  _recommendationId!);
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
              : _detailedData != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20.0),
                      child: Column(
                        children: [
                          _buildRecommendationDetailCard(
                              context, _detailedData!),
                          const SizedBox(height: 24.0),
                          _buildCommentsSection(context),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text('Tidak ada data detail rekomendasi.',
                          style: TextStyle(color: Colors.white70))),
    );
  }

  Widget _buildRecommendationDetailCard(
      BuildContext context, Map<String, dynamic> details) {
    final String exerciseName =
        details['nama_latihan']?.toString() ?? 'Nama Latihan Tidak Ada';

    Map<String, String> displayDetails = {
      'Bagian Dilatih': details['bagian_yang_dilatih']?.toString() ?? '-',
      'Set': details['set_latihan']?.toString() ?? '0',
      'Repetisi': details['repetisi_latihan']?.toString() ?? '0',
      'Waktu': "${details['waktu']?.toString() ?? '-'} menit",
      'Hari': details['hari_latihan']?.toString() ?? '-',
    };

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExerciseNameChip(exerciseName),
          const SizedBox(height: 24.0),
          _buildDetailsSection(displayDetails),
          const SizedBox(height: 28.0),
          _buildAddButton(context),
        ],
      ),
    );
  }

  Widget _buildExerciseNameChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      decoration: BoxDecoration(
          color: chipAndButtonBackgroundColor,
          borderRadius: BorderRadius.circular(16.0)),
      child: Text(name.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: chipAndButtonTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
    );
  }

  Widget _buildDetailsSection(Map<String, String> detailsToDisplay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
          children: detailsToDisplay.entries
              .map((entry) => _buildDetailRow(entry.key, entry.value))
              .toList()),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: detailLabelTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(width: 12),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: detailValueTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _addRecommendationToMyWorkouts,
      style: ElevatedButton.styleFrom(
        backgroundColor: chipAndButtonBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        minimumSize: const Size(double.infinity, 50),
        elevation: 2,
      ),
      child: const Text('Add to My Workouts',
          style: TextStyle(
              color: chipAndButtonTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Comments',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: commentsTitleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16.0),
          _isLoadingComments
              ? const Center(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                          color: chipAndButtonBackgroundColor)))
              : _commentsErrorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(_commentsErrorMessage!,
                          style: const TextStyle(color: Colors.orangeAccent),
                          textAlign: TextAlign.center))
                  : _fetchedComments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                              'Belum ada komentar untuk rekomendasi ini.',
                              style: TextStyle(color: commentTextColor),
                              textAlign: TextAlign.center))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _fetchedComments.length,
                          itemBuilder: (context, index) {
                            final comment = _fetchedComments[index];
                            return _buildCommentItem(
                                comment['name']?.toString() ?? 'Anonim',
                                comment['comment']?.toString() ?? '');
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12.0),
                        ),
          const SizedBox(height: 20.0),
          _buildCommentTextField(),
          const SizedBox(height: 12.0),
          _buildSendButton(context),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String name, String comment) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: commentItemBackgroundColor,
          borderRadius: BorderRadius.circular(12.0)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name,
            style: const TextStyle(
                color: commenterNameColor,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 4.0),
        Text(comment,
            style: const TextStyle(
                color: commentTextColor, fontSize: 13, height: 1.4)),
      ]),
    );
  }

  Widget _buildCommentTextField() {
    return TextField(
      controller: _commentController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'leave a comment',
        hintStyle: const TextStyle(color: textFieldHintColor, fontSize: 14),
        filled: true,
        fillColor: commentItemBackgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide:
                const BorderSide(color: textFieldBorderColor, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide:
                const BorderSide(color: textFieldBorderColor, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(
                color: chipAndButtonBackgroundColor, width: 1.5)),
      ),
      maxLines: 3,
      minLines: 1,
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isPostingComment ? null : _postComment,
      style: ElevatedButton.styleFrom(
        backgroundColor: chipAndButtonBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        minimumSize: const Size(double.infinity, 50),
        elevation: 2,
      ),
      child: _isPostingComment
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: chipAndButtonTextColor, strokeWidth: 3))
          : const Text('Send',
              style: TextStyle(
                  color: chipAndButtonTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
    );
  }
}
