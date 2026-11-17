import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Tempel API key di defaultValue, atau jalankan dengan:
// flutter run --dart-define=GEMINI_API_KEY=kunci_kamu
// Jangan unggah key asli ke GitHub publik.
const String _apiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AQ.Ab8RN6Jq9hnOy8pdmjX3u9SmnZAOpBJQLMDQ83OfGa5J0dfYew');

// Google sering memperbarui nama model. Kalau muncul error 404,
// cek nama model terbaru di AI Studio lalu ganti di sini.
const String _model = 'gemini-4-hydrogen';

/// Mode pemindaian. Mau menambah mode baru? Tambahkan di sini
/// dan tulis prompt-nya di fungsi _prompt.
enum ScanMode { identify, diagnose }

class ScanException implements Exception {
  final String message;
  ScanException(this.message);
}

/// Hasil pemindaian yang sudah rapi dan siap ditampilkan.
class ScanResult {
  final bool isPlant;
  final String title; // nama tanaman, atau gejala yang terlihat
  final String? scientificName;
  final String summary;
  final List<String> causes; // kemungkinan penyebab
  final List<String> advice; // saran
  final double confidence; // 0 sampai 1

  ScanResult({
    required this.isPlant,
    required this.title,
    this.scientificName,
    required this.summary,
    required this.causes,
    required this.advice,
    required this.confidence,
  });

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        isPlant: j['is_plant'] as bool? ?? true,
        title: j['title'] as String? ?? '-',
        scientificName: j['scientific_name'] as String?,
        summary: j['summary'] as String? ?? '',
        causes: _stringList(j['causes']),
        advice: _stringList(j['advice']),
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
      );
}

List<String> _stringList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

String _prompt(ScanMode mode) {
  const format = '''
Balas HANYA dengan JSON tanpa teks lain, dengan bentuk:
{"is_plant": true, "title": "...", "scientific_name": "... atau null", "summary": "...", "causes": ["..."], "advice": ["..."], "confidence": 0.0}
Jika foto bukan tanaman atau terlalu buram, isi is_plant dengan false dan jelaskan singkat di summary.
Gunakan bahasa Indonesia yang sederhana. Jangan mengarang. Jika ragu, turunkan confidence.''';

  switch (mode) {
    case ScanMode.identify:
      return 'Kenali tanaman pada foto ini. '
          'title adalah nama umum dalam bahasa Indonesia, '
          'scientific_name adalah nama ilmiahnya, '
          'summary adalah ciri yang terlihat pada foto, '
          'causes dikosongkan, '
          'advice berisi tips perawatan singkat. $format';
    case ScanMode.diagnose:
      return 'Periksa kondisi tanaman pada foto ini. '
          'title adalah gejala atau kondisi yang terlihat (misalnya daun menguning), '
          'scientific_name adalah nama tanaman jika dikenali, '
          'summary adalah deskripsi gejala, '
          'causes adalah kemungkinan penyebab, urut dari yang paling mungkin, '
          'advice adalah langkah penanganan. '
          'Ingatkan bahwa penyebab pastinya perlu dicek langsung. $format';
  }
}

/// Mengirim foto ke Gemini dan mengembalikan hasil yang sudah diurai.
Future<ScanResult> scanPlant(File image, ScanMode mode) async {
  final bytes = await image.readAsBytes();
  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent');

  http.Response response;
  try {
    response = await http
        .post(
          uri,
          headers: {
            'x-goog-api-key': _apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Encode(bytes),
                    }
                  },
                  {'text': _prompt(mode)},
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.2,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));
  } on SocketException {
    throw ScanException('Tidak ada koneksi internet.');
  } on TimeoutException {
    throw ScanException('Pemindaian terlalu lama. Coba lagi.');
  }

  if (response.statusCode == 429) {
    throw ScanException('Kuota pemindaian sedang habis. Coba lagi nanti.');
  }
  if (response.statusCode != 200) {
    throw ScanException('Gagal memindai (kode ${response.statusCode}).');
  }

  try {
    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return ScanResult.fromJson(jsonDecode(clean) as Map<String, dynamic>);
  } catch (_) {
    throw ScanException('Hasil dari AI tidak bisa dibaca. Coba foto lagi.');
  }
}