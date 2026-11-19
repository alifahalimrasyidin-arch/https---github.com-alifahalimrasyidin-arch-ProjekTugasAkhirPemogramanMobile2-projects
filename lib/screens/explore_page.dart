import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';

/// Halaman Jelajah: AI scanner dan daftar materi edukasi berkebun.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ImagePicker _picker = ImagePicker();

  /// Memilih sumber foto (kamera atau galeri), mengambil gambar, lalu memindai.
  Future<void> _pickAndScan(ScanMode mode) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis indikator geser di atas bottom sheet
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: context.accent),
                title: Text('Ambil foto', style: TextStyle(color: context.ink)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_outlined, color: context.accent),
                title: Text('Pilih dari galeri',
                    style: TextStyle(color: context.ink)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    _runScan(File(picked.path), mode);
  }

  /// Menampilkan pilihan mode pemindaian: identifikasi jenis atau cek gejala.
  void _showScannerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis indikator geser di atas modal
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: context.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Mau pindai apa?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search, color: context.accent),
                ),
                title: Text(
                  'Ini tanaman apa?',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: context.ink),
                ),
                subtitle: Text(
                  'Kenali jenis tanaman dari daun atau buahnya',
                  style: TextStyle(color: context.muted, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndScan(ScanMode.identify);
                },
              ),
              Divider(color: context.line),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.coronavirus_outlined,
                      color: Colors.red),
                ),
                title: Text(
                  'Cek gejala tanaman',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: context.ink),
                ),
                subtitle: Text(
                  'Cari tahu penyebab penyakit, hama, atau kurang nutrisi',
                  style: TextStyle(color: context.muted, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndScan(ScanMode.diagnose);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Mengirim foto ke AI dengan dialog loading lalu menampilkan hasilnya.
  Future<void> _runScan(File image, ScanMode mode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: context.accent),
            const SizedBox(width: 20),
            const Expanded(child: Text('Memindai...')),
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
    Navigator.pop(context); // Tutup dialog loading

    if (result != null) {
      _showScanResult(mode, image, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Terjadi kesalahan. Coba lagi.')),
      );
    }
  }

  /// Menampilkan hasil identifikasi atau diagnosis tanaman.
  Future<void> _showScanResult(
      ScanMode mode, File image, ScanResult result) async {
    final sci = result.scientificName;
    final hasSci = sci != null && sci.isNotEmpty && sci != 'null';
    final pct = (result.confidence * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: context.accent),
                    const SizedBox(width: 8),
                    Text(
                      mode == ScanMode.identify
                          ? 'Hasil identifikasi'
                          : 'Hasil cek gejala',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    image,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                if (!result.isPlant)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.tint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.line),
                    ),
                    child: Text(
                      result.summary.isEmpty
                          ? 'Foto ini tidak terlihat seperti tanaman. Coba foto lagi.'
                          : result.summary,
                      style: TextStyle(color: context.ink, height: 1.5),
                    ),
                  )
                else ...[
                  Text(
                    result.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                  if (hasSci)
                    Text(
                      sci,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: context.muted,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Tingkat keyakinan $pct%',
                    style: TextStyle(color: context.muted, fontSize: 13),
                  ),
                  if (result.confidence < 0.6)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.harvest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.harvest.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          'Kurang yakin. Coba foto lebih dekat, terang, dan fokus pada satu daun.',
                          style: TextStyle(color: context.ink, fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.tint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.line),
                    ),
                    child: Text(
                      result.summary,
                      style: TextStyle(
                        color: context.ink,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (result.causes.isNotEmpty)
                    _resultSection('Kemungkinan penyebab', result.causes),
                  if (result.advice.isNotEmpty)
                    _resultSection(
                      mode == ScanMode.identify
                          ? 'Tips perawatan'
                          : 'Saran penanganan',
                      result.advice,
                    ),
                ],
                const SizedBox(height: 22),
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

  /// Bagian daftar poin (penyebab atau saran) pada hasil pemindaian.
  Widget _resultSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.ink,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: context.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: context.ink, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = context.isDark ? context.bg : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Jelajah'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian atas: AI scanner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: context.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pemindai tanaman',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Arahkan kamera ke daun atau buah untuk mengenali tanaman dan mengecek penyakit atau hama.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showScannerOptions(context),
                            icon: Icon(Icons.camera_alt_outlined,
                                color: context.accent),
                            label: Text(
                              'Buka kamera',
                              style: TextStyle(
                                color: context.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.surface,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Bingkai visual pemindai di sisi kanan kartu header
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Bagian bawha: daftar materi edukasi
            Text(
              'Belajar berkebun',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
            const SizedBox(height: 14),

            _buildArticleCard(
              icon: Icons.eco_outlined,
              title: 'Menanam sayur di rumah',
              subtitle: 'Dari menyiapkan media tanam sampai panen.',
              format: 'PDF, 5 menit baca',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildArticleCard(
              icon: Icons.straighten_outlined,
              title: 'Mengenal etiolasi (kutilang)',
              subtitle:
                  'Kenapa batang tumbuh kurus dan memanjang, dan cara mengatasinya.',
              format: 'Artikel, 3 menit baca',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildArticleCard(
              icon: Icons.bug_report_outlined,
              title: 'Hama umum pada bunga',
              subtitle: 'Cara alami mengusir kutu putih dan ulat daun.',
              format: 'PDF, 7 menit baca',
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildArticleCard(
              icon: Icons.water_drop_outlined,
              title: 'Hidroponik untuk pemula',
              subtitle: 'Mengenal nutrisi AB Mix dan nilai PPM.',
              format: 'Artikel, 4 menit baca',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu materi edukasi
  Widget _buildArticleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String format,
    required Color color,
  }) {
    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Logika membuka materi PDF/Artikel dapat ditambahkan di sini
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.line),
            boxShadow: context.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Kotak visual/thumbnail materi di sebelah kiri kartu
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badge pil untuk informasi format & estimasi waktu baca
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.tint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        format,
                        style: TextStyle(
                          color: context.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: context.muted),
            ],
          ),
        ),
      ),
    );
  }
}