import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

/// Halaman pembuka (Splash Screen) yang tampil singkat sebelum ke LoginPage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Berpindah otomatis ke LoginPage setelah jeda 3 detik
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    // Membatalkan timer jika layar ditutup lebih awal
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deeperDark =
        Color.alphaBlend(Colors.black.withValues(alpha: 0.25), AppColors.dark);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Kedalaman gradasi lembut dari warna gelap asli aplikasi
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.dark, deeperDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.94 + (0.06 * t),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kotak logo utama dengan warna hijau primer & bayangan lembut
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.eco, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),

                // Nama aplikasi
                const Text(
                  'Plant Monitoring',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Tagline singkat aplikasi
                Text(
                  'Pantau kebunmu dari mana saja',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),

                // Garis indikator tipis sebagai penanda transisi pembuka
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}