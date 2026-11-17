import 'package:flutter/material.dart';
import '../data/plant_store.dart';
import '../theme/app_theme.dart';

/// Ringkasan data kebun untuk satu periode rekap.
class RecapData {
  final int totalActions;
  final String? busiestDay;
  final int longestStreak;
  final int harvests;
  final String? lastHarvest;
  final int plantsNow;

  const RecapData({
    required this.totalActions,
    required this.busiestDay,
    required this.longestStreak,
    required this.harvests,
    required this.lastHarvest,
    required this.plantsNow,
  });

  bool get isEmpty => totalActions == 0 && harvests == 0;

  /// Menghitung dari catatan nyata dalam [days] hari terakhir.
  factory RecapData.fromStore(int days) {
    const names = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final today = DateTime.now();
    final perWeekday = List<int>.filled(7, 0);
    var total = 0;
    var streak = 0;
    var best = 0;

    for (var i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final c = plantStore.activityOn(day);
      total += c;
      perWeekday[day.weekday - 1] += c;
      if (c > 0) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 0;
      }
    }

    String? busiest;
    var most = 0;
    for (var i = 0; i < 7; i++) {
      if (perWeekday[i] > most) {
        most = perWeekday[i];
        busiest = names[i];
      }
    }

    final start = today.subtract(Duration(days: days));
    final hs = plantStore.harvests.where((h) => h.at.isAfter(start)).toList();

    return RecapData(
      totalActions: total,
      busiestDay: busiest,
      longestStreak: best,
      harvests: hs.length,
      lastHarvest: hs.isEmpty ? null : hs.last.name,
      plantsNow: plantStore.plants.length,
    );
  }

  /// Data contoh, untuk demo ketika belum ada catatan.
  factory RecapData.sample() => const RecapData(
        totalActions: 86,
        busiestDay: 'Sabtu',
        longestStreak: 12,
        harvests: 4,
        lastHarvest: 'Kangkung balkon',
        plantsNow: 5,
      );
}

class _Slide {
  final Color bg;
  final Color fg;
  final String small;
  final String? big;
  final int? number;
  final String? unit;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Slide({
    required this.bg,
    required this.fg,
    required this.small,
    this.big,
    this.number,
    this.unit,
    this.text = '',
    this.actionLabel,
    this.onAction,
  });
}

/// Rekap bergaya story: halaman layar penuh yang berganti otomatis.
/// Ketuk kanan untuk lanjut, ketuk kiri untuk kembali.
class RecapStoryPage extends StatefulWidget {
  final String periodLabel;
  final int days;
  const RecapStoryPage({
    super.key,
    required this.periodLabel,
    required this.days,
  });

  @override
  State<RecapStoryPage> createState() => _RecapStoryPageState();
}

class _RecapStoryPageState extends State<RecapStoryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  final PageController _pages = PageController();
  late RecapData _data;
  bool _sample = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _data = RecapData.fromStore(widget.days);
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      })
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _showSample() {
    setState(() {
      _sample = true;
      _data = RecapData.sample();
      _index = 0;
    });
    _pages.jumpToPage(0);
    _progress.forward(from: 0);
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pages.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _prev() {
    if (_index > 0) {
      _pages.animateToPage(
        _index - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      _progress.forward(from: 0);
    }
  }

  List<_Slide> get _slides {
    final d = _data;
    if (d.isEmpty) {
      return [
        _Slide(
          bg: AppColors.dark,
          fg: Colors.white,
          small: 'Rekap ${widget.periodLabel}',
          big: 'Belum ada data',
          text: 'Catat perawatan dan panen dulu, nanti ceritamu muncul di sini.',
          actionLabel: 'Lihat contoh rekap',
          onAction: _showSample,
        ),
      ];
    }
    return [
      _Slide(
        bg: AppColors.dark,
        fg: Colors.white,
        small: 'Rekap ${widget.periodLabel}',
        big: 'Kebunmu',
        text: _sample
            ? 'Ini data contoh. Ceritamu akan tampil seperti ini.'
            : 'Yuk lihat apa saja yang sudah kamu lakukan.',
      ),
      if (d.totalActions > 0)
        _Slide(
          bg: AppColors.primary,
          fg: Colors.white,
          small: 'Kamu merawat tanamanmu',
          number: d.totalActions,
          unit: 'kali',
          text: d.busiestDay == null
              ? ''
              : 'Hari paling sibukmu adalah ${d.busiestDay}.',
        ),
      if (d.longestStreak > 1)
        _Slide(
          bg: const Color(0xFF3B82A0),
          fg: Colors.white,
          small: 'Rentetan terpanjang',
          number: d.longestStreak,
          unit: 'hari berturut-turut',
          text: 'Rutin merawat itu kuncinya.',
        ),
      if (d.harvests > 0)
        _Slide(
          bg: AppColors.harvest,
          fg: AppColors.ink,
          small: 'Hasil panen',
          number: d.harvests,
          unit: 'kali panen',
          text: d.lastHarvest == null
              ? ''
              : 'Panen terakhirmu: ${d.lastHarvest}.',
        ),
      _Slide(
        bg: AppColors.dark,
        fg: Colors.white,
        small: 'Saat ini',
        number: d.plantsNow,
        unit: 'tanaman sedang tumbuh',
        text: 'Terima kasih sudah merawatnya. Lanjutkan ya!',
        actionLabel: 'Selesai',
        onAction: () => Navigator.pop(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    final current = slides[_index.clamp(0, slides.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final w = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < w / 3) {
                _prev();
              } else {
                _next();
              }
            },
            child: PageView.builder(
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _progress.forward(from: 0);
              },
              itemBuilder: (context, i) => _buildSlide(slides[i]),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(child: _bars(slides.length, current.fg)),
                    IconButton(
                      icon: Icon(Icons.close, color: current.fg),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bars(int count, Color color) {
    Widget bar(double v) => LinearProgressIndicator(
          value: v,
          minHeight: 3,
          backgroundColor: color.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        );

    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: i < _index
                    ? bar(1)
                    : i == _index
                        ? AnimatedBuilder(
                            animation: _progress,
                            builder: (context, _) => bar(_progress.value),
                          )
                        : bar(0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSlide(_Slide s) {
    return Container(
      color: s.bg,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 90, 28, 60),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.small,
              style: TextStyle(color: s.fg.withValues(alpha: 0.75), fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (s.number != null)
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: s.number!),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, v, _) => Text(
                  '$v',
                  style: TextStyle(
                    color: s.fg,
                    fontSize: 110,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            if (s.big != null)
              Text(
                s.big!,
                style: TextStyle(
                  color: s.fg,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            if (s.unit != null)
              Text(
                s.unit!,
                style: TextStyle(
                  color: s.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 20),
            if (s.text.isNotEmpty)
              Text(
                s.text,
                style: TextStyle(
                  color: s.fg.withValues(alpha: 0.9),
                  fontSize: 17,
                  height: 1.4,
                ),
              ),
            if (s.actionLabel != null && s.onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: s.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.dark,
                ),
                child: Text(s.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}