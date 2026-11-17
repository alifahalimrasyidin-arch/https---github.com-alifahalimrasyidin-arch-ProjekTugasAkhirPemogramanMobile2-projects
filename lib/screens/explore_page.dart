import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {

  final ImagePicker _picker = ImagePicker();

  // Pilih sumber foto (kamera atau galeri), ambil fotonya, lalu kirim ke AI
  Future<void> _pickAndScan(ScanMode mode) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: context.accent),
              title: Text('Ambil foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: context.accent),
              title: Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return; // user menutup pilihan

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return; // user batal mengambil foto

    _runScan(File(picked.path), mode);
  }

  
  // Memunculkan opsi pilihan scan (Identifikasi atau Diagnosis)
  void _showScannerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mau pindai apa?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: context.tint, shape: BoxShape.circle),
                  child: Icon(Icons.search, color: context.accent),
                ),
                title: Text('Ini tanaman apa?'),
                subtitle: Text('Kenali jenis tanaman dari daun atau buahnya'),
                onTap: () {
                  Navigator.pop(context); // Tutup pop-up opsi
                  _pickAndScan(ScanMode.identify);
                },
              ),
              Divider(),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.coronavirus_outlined, color: Colors.red),
                ),
                title: Text('Cek gejala tanaman'),
                subtitle: Text('Cari tahu penyebab penyakit, hama, atau kurang nutrisi'),
                onTap: () {
                  Navigator.pop(context); // Tutup pop-up opsi
                  _pickAndScan(ScanMode.diagnose);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Mengirim foto ke Gemini, menampilkan loading, lalu hasilnya
  Future<void> _runScan(File image, ScanMode mode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: context.accent),
            SizedBox(width: 20),
            Expanded(child: Text('Memindai...')),
          ],
        ),
      ),
    );

    ScanResult? result;
    String? error;
    try {
      result = await scanPlant(image, mode);
    } on ScanException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Terjadi kesalahan. Coba lagi.';
    }

    if (!mounted) return;
    Navigator.pop(context); // tutup loading

    if (result != null) {
      _showScanResult(mode, image, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Terjadi kesalahan. Coba lagi.')),
      );
    }
  }

  Future<void> _showScanResult(ScanMode mode, File image, ScanResult result) async {
    final sci = result.scientificName;
    final hasSci = sci != null && sci.isNotEmpty && sci != 'null';
    final pct = (result.confidence * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: context.accent),
                    SizedBox(width: 8),
                    Text(
                      mode == ScanMode.identify ? 'Hasil identifikasi' : 'Hasil cek gejala',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(image, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                SizedBox(height: 16),
                if (!result.isPlant)
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      result.summary.isEmpty ? 'Foto ini tidak terlihat seperti tanaman. Coba foto lagi.' : result.summary,
                      style: TextStyle(height: 1.5),
                    ),
                  )
                else ...[
                  Text(result.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  if (hasSci)
                    Text(sci, style: TextStyle(fontStyle: FontStyle.italic, color: context.muted)),
                  SizedBox(height: 8),
                  Text('Tingkat keyakinan $pct%', style: TextStyle(color: context.muted, fontSize: 13)),
                  if (result.confidence < 0.6)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.harvest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Kurang yakin. Coba foto lebih dekat, terang, dan fokus pada satu daun.'),
                      ),
                    ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(10)),
                    child: Text(result.summary, style: TextStyle(fontSize: 15, height: 1.5)),
                  ),
                  if (result.causes.isNotEmpty) _resultSection('Kemungkinan penyebab', result.causes),
                  if (result.advice.isNotEmpty)
                    _resultSection(mode == ScanMode.identify ? 'Tips perawatan' : 'Saran penanganan', result.advice),
                ],
                SizedBox(height: 20),
                Text(
                  'Ini perkiraan dari AI, bukan pengganti penyuluh pertanian.',
                  style: TextStyle(color: context.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resultSection(String title, List<String> items) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: context.accent),
                  SizedBox(width: 8),
                  Expanded(child: Text(item, style: TextStyle(height: 1.4))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
                elevation: 0,
        title: Text('Jelajah'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: SCANNER AI ---
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pemindai tanaman', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(
                    'Arahkan kamera ke daun atau buah untuk mengenali tanaman dan mengecek penyakit atau hama.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showScannerOptions(context),
                      icon: Icon(Icons.camera_alt, color: context.accent),
                      label: Text('Buka kamera', style: TextStyle(color: context.accent, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.surface,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 35),
            
            // --- DAFTAR MATERI EDUKASI ---
            Text('Belajar berkebun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            
            _buildArticleCard(
              icon: Icons.article_outlined,
              title: 'Menanam sayur di rumah',
              subtitle: 'Dari menyiapkan media tanam sampai panen.',
              format: 'PDF, 5 menit baca',
              color: AppColors.primary,
            ),
            SizedBox(height: 15),
            _buildArticleCard(
              icon: Icons.warning_amber_rounded,
              title: 'Mengenal etiolasi (kutilang)',
              subtitle: 'Kenapa batang tumbuh kurus dan memanjang, dan cara mengatasinya.',
              format: 'Artikel, 3 menit baca',
              color: AppColors.primary,
            ),
            SizedBox(height: 15),
            _buildArticleCard(
              icon: Icons.bug_report_outlined,
              title: 'Hama umum pada bunga',
              subtitle: 'Cara alami mengusir kutu putih dan ulat daun.',
              format: 'PDF, 7 menit baca',
              color: Colors.red,
            ),
            SizedBox(height: 15),
            _buildArticleCard(
              icon: Icons.water_drop_outlined,
              title: 'Hidroponik untuk pemula',
              subtitle: 'Mengenal nutrisi AB Mix dan nilai PPM.',
              format: 'Artikel, 4 menit baca',
              color: AppColors.primary,
            ),
            
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Desain kartu materi edukasi
  Widget _buildArticleCard({required IconData icon, required String title, required String subtitle, required String format, required Color color}) {
    return InkWell(
      onTap: () {
        // Logika untuk membuka materi PDF/Artikel nanti ditaruh di sini
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: context.line),
          boxShadow: [BoxShadow(color: context.line, blurRadius: 5, spreadRadius: 1)],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 5),
                  Text(subtitle, style: TextStyle(color: context.muted, fontSize: 13)),
                  SizedBox(height: 8),
                  Text(format, style: TextStyle(color: context.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.muted),
          ],
        ),
      ),
    );
  }
}