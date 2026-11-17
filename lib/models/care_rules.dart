import 'plant.dart';

/// Cara panen sebuah tipe.
/// none = tidak dipanen, cutCycle = potong lalu tumbuh lagi (maksimal beberapa kali),
/// pick = petik buah kapan saja setelah masa pantau dimulai.
enum HarvestMode { none, cutCycle, pick }

/// Tugas rutin, misalnya siram tiap hari atau pupuk tiap 14 hari.
/// [fromDay] = tugas baru muncul setelah tanaman berumur sekian hari.
class RoutineTask {
  final CareKind kind;
  final String label;
  final int everyDays;
  final int fromDay;
  const RoutineTask(this.kind, this.label, this.everyDays, [this.fromDay = 0]);
}

/// Aturan perawatan satu tipe. Mengubah angka di sini mengubah perilaku
/// semua tanaman bertipe itu.
class CareRules {
  final int semaiDays; // 0 = tanpa masa semai
  final int optionalSemaiDays; // lama semai kalau user memilih semai (tipe 2A)
  final HarvestMode harvestMode;
  final int harvestFromDays; // panen pertama / mulai pantau buah
  final int regrowDays; // jeda panen potong berikutnya
  final int maxCuts; // maksimal panen potong
  final String? lightNote; // catatan kebutuhan cahaya (tanaman hias)
  final List<RoutineTask> semaiTasks;
  final List<RoutineTask> tasks;

  const CareRules({
    required this.semaiDays,
    this.optionalSemaiDays = 0,
    this.harvestMode = HarvestMode.cutCycle,
    this.harvestFromDays = 0,
    this.regrowDays = 0,
    this.maxCuts = 0,
    this.lightNote,
    required this.semaiTasks,
    required this.tasks,
  });

  bool get hasSemai => semaiDays > 0;
}

const _cekMedia = RoutineTask(CareKind.cekMedia, 'Cek media tetap basah', 1);
const _siram = RoutineTask(CareKind.siram, 'Siram', 1);
const _pupuk = RoutineTask(CareKind.pupuk, 'Beri pupuk', 14);
const _cekAir = RoutineTask(CareKind.cekAir, 'Cek air nutrisi', 3);
// Muncul setelah hari ke-30 (bulan kedua), untuk tipe 2A. ANGKA SEMENTARA.
const _pangkas =
    RoutineTask(CareKind.pangkas, 'Pangkas tunas dan daun tua', 14, 30);
const _pantauBuah = RoutineTask(CareKind.pantauBuah, 'Pantau buah', 3, 30);

// Tipe 1A: tabur langsung, panen daun
const _taburDaun = CareRules(
  semaiDays: 0,
  harvestFromDays: 28,
  regrowDays: 21, // ANGKA SEMENTARA
  maxCuts: 3,
  semaiTasks: [],
  tasks: [_siram, _pupuk],
);

// Tipe 2A: tabur langsung, panen buah dipetik kapan saja (tidak bisa diprediksi).
// Semai bersifat opsional, dipilih user saat menambah tanaman.
const _taburBuah = CareRules(
  semaiDays: 0,
  optionalSemaiDays: 21, // ANGKA SEMENTARA
  harvestMode: HarvestMode.pick,
  harvestFromDays: 30,
  semaiTasks: [_cekMedia],
  tasks: [_siram, _pupuk, _pangkas, _pantauBuah],
);

// Tipe 3A: semai 3 minggu, lalu seperti tipe 1A
const _semaiDaun = CareRules(
  semaiDays: 21,
  harvestFromDays: 28, // dihitung sejak pindah tanah, ANGKA SEMENTARA
  regrowDays: 21,
  maxCuts: 3,
  semaiTasks: [_cekMedia],
  tasks: [_siram, _pupuk],
);

// Tipe 4A: semai 2 bulan, lalu seperti tipe 1A
const _semaiLama = CareRules(
  semaiDays: 60,
  harvestFromDays: 28, // ANGKA SEMENTARA
  regrowDays: 21,
  maxCuts: 3,
  semaiTasks: [_cekMedia],
  tasks: [_siram, _pupuk],
);

// Hidroponik: semai dulu, lalu cek air tiap 3 hari
const _hidroponik = CareRules(
  semaiDays: 14, // ANGKA SEMENTARA
  harvestFromDays: 28, // ANGKA SEMENTARA
  regrowDays: 21,
  maxCuts: 3,
  semaiTasks: [_cekMedia],
  tasks: [_cekAir],
);

// Tanaman hias: tidak dipanen, fokus ke siram dan kebutuhan cahaya.
const _hiasMudah = CareRules(
  semaiDays: 0,
  harvestMode: HarvestMode.none,
  lightNote: 'Tidak butuh banyak matahari. Cukup tempat terang tanpa terik langsung.',
  semaiTasks: [],
  tasks: [RoutineTask(CareKind.siram, 'Siram', 4)], // 3-5 hari sekali
);

const _hiasSedang = CareRules(
  semaiDays: 0,
  harvestMode: HarvestMode.none,
  lightNote: 'Suka matahari. Taruh di tempat yang terkena sinar matahari langsung.',
  semaiTasks: [],
  tasks: [RoutineTask(CareKind.siram, 'Siram', 2)],
);

const _hiasSulit = CareRules(
  semaiDays: 0,
  harvestMode: HarvestMode.none,
  lightNote: 'Tidak suka matahari terik. Taruh di tempat teduh atau yang cahayanya tersaring.',
  semaiTasks: [],
  tasks: [RoutineTask(CareKind.siram, 'Siram', 2)],
);

/// Aturan untuk satu tipe. Null berarti fiturnya belum dibuat.
CareRules? careRulesOf(CareType? type) {
  switch (type) {
    case CareType.taburDaun:
      return _taburDaun;
    case CareType.taburBuah:
      return _taburBuah;
    case CareType.semaiDaun:
      return _semaiDaun;
    case CareType.semaiLama:
      return _semaiLama;
    case CareType.hidroponik:
      return _hidroponik;
    case CareType.hiasMudah:
      return _hiasMudah;
    case CareType.hiasSedang:
      return _hiasSedang;
    case CareType.hiasSulit:
      return _hiasSulit;
    default:
      return null;
  }
}

/// Logika perawatan yang dihitung dari data tanaman.
extension PlantCare on Plant {
  CareRules? get rules => careRulesOf(careType);

  int get daysInStage => DateTime.now().difference(stageStart).inDays;

  /// Lama masa semai tanaman ini (0 kalau tidak disemai).
  int get semaiLength {
    final r = rules;
    if (r == null || !withSemai) return 0;
    return r.semaiDays > 0 ? r.semaiDays : r.optionalSemaiDays;
  }

  int get pickCount => logs.where((l) => l.kind == CareKind.petikBuah).length;

  DateTime? lastLog(CareKind kind) {
    DateTime? last;
    for (final l in logs) {
      if (l.kind == kind && (last == null || l.at.isAfter(last))) last = l.at;
    }
    return last;
  }

  bool doneToday(CareKind kind) {
    final last = lastLog(kind);
    final now = DateTime.now();
    return last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  /// Apakah tugas ini perlu dikerjakan sekarang.
  bool dueNow(RoutineTask t) {
    if (t.everyDays <= 1) return true;
    final since =
        DateTime.now().difference(lastLog(t.kind) ?? stageStart).inDays;
    return since >= t.everyDays;
  }

  bool get semaiReady =>
      rules != null && stage == PlantStage.semai && daysInStage >= semaiLength;

  bool get mustPull {
    final r = rules;
    return r != null &&
        r.harvestMode == HarvestMode.cutCycle &&
        stage == PlantStage.tumbuh &&
        cutCount >= r.maxCuts;
  }

  bool get canHarvest {
    final r = rules;
    if (r == null ||
        r.harvestMode != HarvestMode.cutCycle ||
        stage != PlantStage.tumbuh ||
        mustPull) {
      return false;
    }
    final since = DateTime.now().difference(lastCutAt ?? stageStart).inDays;
    return since >= (cutCount == 0 ? r.harvestFromDays : r.regrowDays);
  }

  /// Tanaman buah: sudah boleh mencatat petik buah.
  bool get canPick {
    final r = rules;
    return r != null &&
        r.harvestMode == HarvestMode.pick &&
        stage == PlantStage.tumbuh &&
        daysInStage >= r.harvestFromDays;
  }
}