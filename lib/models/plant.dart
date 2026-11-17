import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tiga kategori tanaman di aplikasi.
enum PlantCategory { sayurBuah, hias, hidroponik }

extension PlantCategoryX on PlantCategory {
  String get label {
    switch (this) {
      case PlantCategory.sayurBuah:
        return 'Sayur dan buah';
      case PlantCategory.hias:
        return 'Tanaman hias';
      case PlantCategory.hidroponik:
        return 'Hidroponik';
    }
  }

  /// Warna card: hijau, merah, biru.
  Color get color {
    switch (this) {
      case PlantCategory.sayurBuah:
        return AppColors.primary;
      case PlantCategory.hias:
        return const Color(0xFFC94F4F);
      case PlantCategory.hidroponik:
        return const Color(0xFF3B82A0);
    }
  }

  IconData get icon {
    switch (this) {
      case PlantCategory.sayurBuah:
        return Icons.eco;
      case PlantCategory.hias:
        return Icons.local_florist;
      case PlantCategory.hidroponik:
        return Icons.water_drop;
    }
  }
}

/// Tipe perawatan. Tiap tipe nanti punya tahap dan fitur perawatannya sendiri.
enum CareType {
  // Sayur dan buah
  taburDaun, // tipe 1: tabur langsung, konsumsi daun/batang, potong atau cabut
  taburBuah, // tipe 2: tabur langsung, konsumsi buah, petik, pangkas batang
  semaiDaun, // tipe 3: perlu semai, pindah tanah, potong atau cabut
  semaiLama, // tipe 4: semai lebih lama, pindah tanah, pangkas atau cabut
  // Tanaman hias
  hiasMudah, // mudah dirawat, sedikit matahari, sedikit air
  hiasSedang, // medium, suka matahari, air normal
  hiasSulit, // sulit, matahari terbatas, air normal
  hiasUnik, // hanya untuk tambah manual
  // Hidroponik
  hidroponik,
}

extension CareTypeX on CareType {
  String get label {
    switch (this) {
      case CareType.taburDaun:
        return 'Tabur langsung, panen daun';
      case CareType.taburBuah:
        return 'Tabur langsung, panen buah';
      case CareType.semaiDaun:
        return 'Semai, pindah tanam, panen daun';
      case CareType.semaiLama:
        return 'Semai lama, pindah tanam';
      case CareType.hiasMudah:
        return 'Hias: mudah dirawat';
      case CareType.hiasSedang:
        return 'Hias: perawatan sedang';
      case CareType.hiasSulit:
        return 'Hias: sulit dirawat';
      case CareType.hiasUnik:
        return 'Hias: unik (manual)';
      case CareType.hidroponik:
        return 'Hidroponik';
    }
  }
}

/// Tiap jenis di katalog menunjuk ke satu tipe perawatan.
/// PEMETAAN INI SEMENTARA, sesuaikan dengan yang benar.
const Map<PlantCategory, Map<String, CareType>> careTypeMap = {
  PlantCategory.sayurBuah: {
    'Kangkung': CareType.taburDaun,
    'Bayam': CareType.taburDaun,
    'Caisim': CareType.taburDaun,
    'Pakcoy': CareType.semaiDaun,
    'Selada': CareType.semaiDaun,
    'Daun Bawang': CareType.semaiLama,
    'Cabai': CareType.taburBuah,
    'Tomat': CareType.taburBuah,
    'Terong': CareType.taburBuah,
    'Pepaya': CareType.taburBuah,
    'Stroberi': CareType.taburBuah,
  },
  PlantCategory.hias: {
    'Miana': CareType.hiasSedang,
    'Bunga Matahari': CareType.hiasSedang,
    'Aster': CareType.hiasSulit,
    'Mawar': CareType.hiasSulit,
    'Lavender': CareType.hiasSulit,
  },
  PlantCategory.hidroponik: {
    'Kangkung': CareType.hidroponik,
    'Caisim': CareType.hidroponik,
    'Pakcoy': CareType.hidroponik,
    'Bayam': CareType.hidroponik,
    'Selada': CareType.hidroponik,
  },
};

/// Mengembalikan tipe perawatan, atau null untuk jenis di luar katalog.
CareType? careTypeOf(PlantCategory category, String type) =>
    careTypeMap[category]?[type];

/// Katalog bawaan: daftar jenis tanaman per kategori.
const Map<PlantCategory, List<String>> plantCatalog = {
  PlantCategory.sayurBuah: [
    'Kangkung',
    'Caisim',
    'Pakcoy',
    'Bayam',
    'Selada',
    'Daun Bawang',
    'Cabai',
    'Stroberi',
    'Pepaya',
    'Tomat',
    'Terong',
  ],
  PlantCategory.hias: [
    'Bunga Matahari',
    'Mawar',
    'Aster',
    'Miana',
    'Lavender',
  ],
  PlantCategory.hidroponik: [
    'Kangkung',
    'Caisim',
    'Pakcoy',
    'Bayam',
    'Selada',
  ],
};

enum PlantStage { semai, tumbuh }

enum CareKind {
  siram,
  pupuk,
  cekMedia,
  cekAir,
  panenPotong,
  pangkas,
  pantauBuah,
  petikBuah,
}

/// Satu catatan perawatan yang sudah dilakukan user.
class CareLog {
  final CareKind kind;
  final DateTime at;
  CareLog(this.kind, [DateTime? at]) : at = at ?? DateTime.now();
}

/// Catatan bebas dari user.
class PlantNote {
  final String text;
  final DateTime at;
  PlantNote(this.text) : at = DateTime.now();
}

/// Tanaman milik user yang tampil sebagai card di Monitoring Kebun.
class Plant {
  final String id;
  final String name; // nama dari user, misalnya "Kangkung balkon"
  final String type; // jenis dari katalog, misalnya "Kangkung"
  final PlantCategory category;
  final CareType? careType; // tipe perawatan (null kalau jenis di luar katalog)
  final bool isCustom; // true kalau dipilih lewat "Lainnya"
  final DateTime plantedAt;

  bool withSemai; // true kalau tanaman dimulai dari masa semai
  PlantStage stage = PlantStage.tumbuh;
  late DateTime stageStart; // awal tahap yang sedang berjalan
  int cutCount = 0; // berapa kali panen potong
  DateTime? lastCutAt;
  final List<CareLog> logs = [];
  final List<PlantNote> notes = [];
  final List<String> photoPaths = [];

  Plant({
    required this.name,
    required this.type,
    required this.category,
    this.careType,
    this.isCustom = false,
    this.withSemai = false,
    DateTime? plantedAt,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        plantedAt = plantedAt ?? DateTime.now() {
    stageStart = this.plantedAt;
  }
}