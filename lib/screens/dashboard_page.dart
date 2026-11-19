import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/plant_store.dart';
import '../services/weather_service.dart';
import 'explore_page.dart';
import 'monitoring_page.dart';
import 'recap_page.dart';

/// Halaman utama (Dashboard) yang menampilkan ringkasan aktivitas 7 hari, informasi cuaca terkini, serta navigasi ke fitur utama aplikasi.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Key untuk mengontrol buka/tutup panel pengaturan (endDrawer)
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isNotifOn = true;

  @override
  void initState() {
    super.initState();
    // Memuat data cuaca saat halaman pertama kali dibuka
    weatherStore.init();
  }

  /// Menampilkan modal dari bawah (Bottom Sheet) untuk menu profil pengguna.
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Garis indikator geser di bagian atas sheet
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Foto profil dengan ikon kamera untuk ganti foto
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka galeri...')),
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 46, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.line),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: AppColors.primary, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sheetTile(Icons.person_outline, 'Ubah data diri', 'Nama dan email'),
            _sheetTile(Icons.lock_outline, 'Ubah kata sandi', null),
          ],
        ),
      ),
    );
  }

  /// Template baris item pengaturan di dalam drawer.
  Widget _settingItem(IconData icon, String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          control,
        ],
      ),
    );
  }

  /// Panel samping kanan untuk mengatur tema, notifikasi, bahasa, dan lokasi cuaca.
  Widget _settingsDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
              const SizedBox(height: 12),
              // mode gelap / terang
              _settingItem(
                Icons.dark_mode_outlined,
                'Tema gelap',
                Switch(
                  value: context.isDark,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) =>
                      themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
              Divider(color: context.line),
              // pengingat notifikasi
              _settingItem(
                Icons.notifications_none,
                'Notifikasi',
                Switch(
                  value: _isNotifOn,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isNotifOn = v),
                ),
              ),
              Divider(color: context.line),
              _settingItem(
                Icons.language,
                'Bahasa',
                Text('Indonesia', style: TextStyle(color: context.muted)),
              ),
              Divider(color: context.line),
              // Pengaturan lokasi cuaca (GPS otomatis atau input nama kota)
              _settingItem(
                Icons.location_on_outlined,
                'Lokasi cuaca',
                ListenableBuilder(
                  listenable: weatherStore,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weatherStore.usingGps
                            ? '${weatherStore.city} (lokasi HP)'
                            : weatherStore.city,
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _useGps,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Pakai lokasi HP',
                            style: TextStyle(
                              color: context.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _changeCity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Cari kota',
                            style: TextStyle(
                              color: context.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item menu di dalam modal profil.
  Widget _sheetTile(IconData icon, String title, String? subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: context.accent),
      title: Text(title, style: TextStyle(color: context.ink)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(color: context.muted)),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.bg,
      endDrawer: _settingsDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Header: Sapaan pengguna & tombol profil/pengaturan
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi User,',
                          style: TextStyle(
                            color: context.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mari kita lihat kebunmu',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.person_outline, color: context.ink),
                    onPressed: _showProfileSheet,
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: context.ink),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kartu pelacak aktivitas perawatan 7 hari terakhir
              ListenableBuilder(
                listenable: plantStore,
                builder: (context, _) => _weeklyCard(),
              ),
              const SizedBox(height: 12),

              // Kartu informasi suhu & peluang hujan hari ini
              ListenableBuilder(
                listenable: weatherStore,
                builder: (context, _) => _weatherTile(),
              ),
              const SizedBox(height: 28),

              // Daftar menu navigasi fitur utama
              Text(
                'Lakukan aktivitasmu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.ink,
                ),
              ),
              const SizedBox(height: 12),
              _menuTile(
                Icons.grass,
                'Monitoring Kebun',
                'Pantau dan kelola semua tanamanmu',
                () => const MonitoringPage(),
                featured: true,
              ),
              _menuTile(
                Icons.insights_outlined,
                'Rekap Kita',
                'Lihat perkembangan kebunmu',
                () => const RecapPage(),
              ),
              _menuTile(
                Icons.explore_outlined,
                'Jelajah',
                'Pindai tanaman dan belajar berkebun',
                () => const ExplorePage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mengambil lokasi GPS perangkat untuk memperbarui data cuaca.
  Future<void> _useGps() async {
    Navigator.pop(context);
    final error = await weatherStore.useDeviceLocation();
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  /// Menampilkan dialog pencarian nama kota untuk lokasi cuaca manual.
  Future<void> _changeCity() async {
    Navigator.pop(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lokasi cuaca'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Nama kota, misalnya Bandung'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final ok = await weatherStore.setCity(name);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kota "$name" tidak ditemukan.')),
    );
  }

  /// Kartu status cuaca (suhu maksimal dan persentase peluang hujan).
  Widget _weatherTile() {
    final w = weatherStore.today;
    IconData icon = Icons.cloud_outlined;
    String title = weatherStore.city;
    String detail;

    // Menentukan ikon & teks berdasarkan kondisi cuaca atau status loading
    if (w == null) {
      title = 'Cuaca';
      detail = weatherStore.loading
          ? 'Memuat cuaca...'
          : (weatherStore.error ?? 'Cuaca belum tersedia.');
    } else {
      detail = '${w.tempMax.round()}°C, peluang hujan ${w.rainChance}%';
      if (w.rainy) {
        icon = Icons.water_drop_outlined;
      } else if (w.hot) {
        icon = Icons.wb_sunny_outlined;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.line),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Ikon cuaca di dalam kotak lembut sesuai tema
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(color: context.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu ringkasan aktivitas perawatan tanaman selama 7 hari terakhir.
  Widget _weeklyCard() {
    const letters = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    final today = DateTime.now();
    // Menghitung daftar 7 hari ke belakang hingga hari ini
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final counts = [for (final d in days) plantStore.activityOn(d)];
    final total = counts.fold<int>(0, (a, b) => a + b);

    // Pesan ringkasan berdasarkan jumlah tanaman dan catatan perawatan
    String summary;
    if (plantStore.totalPlantsEver == 0) {
      summary =
          'Belum ada tanaman. Tambah tanaman di Monitoring Kebun untuk mulai mencatat.';
    } else if (total == 0) {
      summary = 'Belum ada catatan perawatan minggu ini.';
    } else {
      summary = '$total catatan perawatan dalam 7 hari terakhir.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1B4331) : AppColors.dark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7 hari terakhir',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aktivitas kebunmu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          // Deretan 7 lingkaran indikator harian (centang jika ada aktivitas)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < days.length; i++)
                Column(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: counts[i] > 0
                            ? AppColors.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: counts[i] > 0
                            ? null
                            : Border.all(
                                // Lingkaran hari ini (i == 6)
                                color: i == 6
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.3),
                                width: i == 6 ? 1.5 : 1.0,
                              ),
                      ),
                      child: counts[i] > 0
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      letters[days[i].weekday - 1],
                      style: TextStyle(
                        color: i == 6
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight:
                            i == 6 ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu tombol navigasi menu (featured = true untuk kartu utama berwarna hijau).
  Widget _menuTile(
      IconData icon, String title, String subtitle, Widget Function() page,
      {bool featured = false}) {
    final fg = featured ? Colors.white : context.ink;
    final sub = featured ? Colors.white.withValues(alpha: 0.8) : context.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: featured ? AppColors.primary : context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: featured ? AppColors.primary : context.line,
          ),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: featured
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => page())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: featured
                          ? Colors.white.withValues(alpha: 0.18)
                          : context.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: featured ? Colors.white : context.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(color: sub, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: sub),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}