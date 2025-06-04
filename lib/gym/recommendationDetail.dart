import 'package:flutter/material.dart';

class RecommendationDetail extends StatelessWidget {
  const RecommendationDetail({super.key});

  // Contoh data, bisa diganti dengan data dinamis
  final String exerciseName = 'Single Dumbbel Row';
  final Map<String, String> details = const {
    'Name': 'Dips',
    'Set': '5',
    'Repetition': '15',
    'Time': '20 Min',
    'Day': 'Monday,\nSunday',
    'Rest': '5 Min',
  };

  // Contoh data komentar
  final List<Map<String, String>> comments = const [
    {
      'name': 'Haidar',
      'comment':
          'Terima kasih atas rekomendasinya! Latihan tersebut memang terbukti efektif.'
    },
    {
      'name': 'Lexy',
      'comment':
          'Suka banget sama insight-nya! Kami sangat mengapresiasi rekomendasi latihan ini.'
    },
    {
      'name': 'Ifcal',
      'comment':
          'Rekomendasi yang bagus! Latihan ini memang dapat membantu meningkatkan daya tahan otot.'
    },
  ];

  // Skema Warna (disesuaikan dengan gambar baru dan konteks sebelumnya)
  static const Color screenBackgroundColor =
      Color(0xFF121212); // Lebih gelap agar kontras
  static const Color appBarTextColor = Colors.white;
  static const Color cardBackgroundColor =
      Color(0xFF1E1E1E); // Warna kartu sedikit lebih gelap
  static const Color chipAndButtonBackgroundColor =
      Color(0xFFE0C083); // Kuning-beige
  static const Color chipAndButtonTextColor =
      Color(0xFF121212); // Teks lebih gelap untuk kontras di chip/button
  static const Color detailLabelTextColor =
      Color(0xFFB0B0B0); // Abu-abu lebih terang untuk label
  static const Color detailValueTextColor =
      Color(0xFFE0E0E0); // Putih keabuan untuk nilai
  static const Color dotColor = chipAndButtonBackgroundColor;

  static const Color commentsTitleColor = Colors.white;
  static const Color commentItemBackgroundColor =
      Color(0xFF2C2C2C); // Latar belakang item komentar
  static const Color commenterNameColor = Color(0xFFE0E0E0);
  static const Color commentTextColor = Color(0xFFB0B0B0);
  static const Color textFieldBorderColor =
      Color(0xFF4A4A4A); // Warna border textfield
  static const Color textFieldHintColor =
      Color(0xFF757575); // Warna hint textfield

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
          'RECOMMENDATION\nDETAIL', // Judul diubah
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
      body: SingleChildScrollView(
        // Padding diatur per bagian, bukan global di SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 20.0), // Padding untuk sisi halaman
          child: Column(
            children: [
              _buildRecommendationDetailCard(context), // Mengganti nama method
              const SizedBox(height: 24.0),
              _buildCommentsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationDetailCard(BuildContext context) {
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
          _buildDetailsSection(),
          const SizedBox(height: 28.0),
          _buildAddButton(context), // Tombol diubah menjadi "Add"
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

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0),
      child: Column(
        children: details.entries
            .map((entry) => _buildDetailRow(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 9.0), // Sedikit mengurangi padding vertikal
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, // Ukuran dot disesuaikan
                height: 8,
                decoration: const BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: detailLabelTextColor,
                  fontSize: 15, // Ukuran font label disesuaikan
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: detailValueTextColor,
                fontSize: 15, // Ukuran font value disesuaikan
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print('Add button pressed');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: chipAndButtonBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        minimumSize: const Size(double.infinity, 50), // Untuk full width
        elevation: 2,
      ),
      child: const Text(
        'Add',
        style: TextStyle(
          color: chipAndButtonTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // --- Bagian Komentar ---
  Widget _buildCommentsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color:
              cardBackgroundColor, // Sama dengan kartu atas atau sedikit beda
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
          const Text(
            'Comments',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: commentsTitleColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          // Daftar Komentar
          ListView.separated(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Karena sudah di dalam SingleChildScrollView
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _buildCommentItem(comment['name']!, comment['comment']!);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
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
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: commenterNameColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            comment,
            style: const TextStyle(
                color: commentTextColor,
                fontSize: 13, // Teks komentar lebih kecil
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTextField() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'leave a comment',
        hintStyle: const TextStyle(color: textFieldHintColor, fontSize: 14),
        filled: true,
        fillColor:
            commentItemBackgroundColor, // Sama dengan item komentar atau sedikit beda
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: textFieldBorderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: textFieldBorderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide:
              const BorderSide(color: chipAndButtonBackgroundColor, width: 1.5),
        ),
      ),
      maxLines: 3,
      minLines: 1,
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print('Send comment pressed');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: chipAndButtonBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        minimumSize: const Size(double.infinity, 50),
        elevation: 2,
      ),
      child: const Text(
        'Send',
        style: TextStyle(
          color: chipAndButtonTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
