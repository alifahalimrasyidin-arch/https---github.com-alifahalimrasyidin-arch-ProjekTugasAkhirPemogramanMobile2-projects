import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Perkiraan cuaca satu hari.
class WeatherDay {
  final DateTime date;
  final int rainChance; // peluang hujan, persen
  final double rainMm;
  final double tempMax; // suhu tertinggi, derajat Celsius

  const WeatherDay(this.date, this.rainChance, this.rainMm, this.tempMax);

  /// Dianggap hujan. ANGKA SEMENTARA, sesuaikan kalau perlu.
  bool get rainy => rainChance >= 60 || rainMm >= 5;

  /// Dianggap panas tinggi. ANGKA SEMENTARA.
  bool get hot => tempMax >= 33;
}

/// Menyimpan lokasi dan perkiraan cuaca (sumber data: Open-Meteo, tanpa API key).
class WeatherStore extends ChangeNotifier {
  String city = 'Jakarta'; // nama tempat yang ditampilkan
  bool usingGps = false;
  double lat = -6.2088;
  double lon = 106.8456;
  List<WeatherDay> days = [];
  bool loading = false;
  String? error;

  WeatherDay? get today => days.isEmpty ? null : days.first;
  WeatherDay? get tomorrow => days.length > 1 ? days[1] : null;

  /// Dipanggil sekali saat beranda dibuka: coba pakai lokasi HP,
  /// kalau gagal pakai lokasi awal.
  Future<void> init() async {
    if (days.isNotEmpty) return;
    final err = await useDeviceLocation();
    if (err != null) await refresh();
  }

  /// Memakai lokasi HP (GPS). Mengembalikan null kalau berhasil,
  /// atau pesan kalau gagal.
  Future<String?> useDeviceLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Layanan lokasi di HP mati. Aktifkan GPS dulu.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return 'Izin lokasi ditolak.';
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Izin lokasi diblokir. Aktifkan lewat pengaturan aplikasi di HP.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      lat = pos.latitude;
      lon = pos.longitude;
      city = await _placeName(lat, lon) ?? 'Lokasi HP';
      usingGps = true;
      await refresh();
      return null;
    } on TimeoutException {
      return 'Lokasi terlalu lama didapat. Coba lagi di tempat terbuka.';
    } catch (_) {
      return 'Lokasi belum bisa didapat.';
    }
  }

  /// Mengubah koordinat menjadi nama tempat (kelurahan, kecamatan, kota)
  /// lewat layanan peta OpenStreetMap (Nominatim), tanpa plugin tambahan.
  Future<String?> _placeName(double lat, double lon) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$lat',
        'lon': '$lon',
        'format': 'jsonv2',
        'zoom': '14',
        'addressdetails': '1',
        'accept-language': 'id',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'plant_monitoring/1.0 (aplikasi tugas kuliah)',
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final address =
          (jsonDecode(res.body) as Map<String, dynamic>)['address']
              as Map<String, dynamic>?;
      if (address == null) return null;

      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = address[k];
          if (v is String && v.isNotEmpty) return v;
        }
        return null;
      }

      final parts = <String>[];
      for (final p in [
        pick(['village', 'suburb', 'neighbourhood']), // kelurahan
        pick(['city_district', 'district', 'municipality']), // kecamatan
        pick(['city', 'town', 'county', 'regency']), // kota atau kabupaten
      ]) {
        if (p != null && !parts.contains(p)) parts.add(p);
      }
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$lat',
        'longitude': '$lon',
        'daily':
            'temperature_2m_max,precipitation_sum,precipitation_probability_max',
        'timezone': 'auto',
        'forecast_days': '3',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('kode ${res.statusCode}');

      final daily = jsonDecode(res.body)['daily'] as Map<String, dynamic>;
      final times = (daily['time'] as List).cast<String>();
      final tmax = daily['temperature_2m_max'] as List;
      final rain = daily['precipitation_sum'] as List;
      final prob = daily['precipitation_probability_max'] as List;

      days = [
        for (var i = 0; i < times.length; i++)
          WeatherDay(
            DateTime.parse(times[i]),
            (prob[i] as num?)?.round() ?? 0,
            (rain[i] as num?)?.toDouble() ?? 0,
            (tmax[i] as num?)?.toDouble() ?? 0,
          ),
      ];
    } on SocketException {
      error = 'Tidak ada koneksi internet.';
    } on TimeoutException {
      error = 'Cuaca terlalu lama dimuat.';
    } catch (_) {
      error = 'Cuaca belum bisa dimuat.';
    }

    loading = false;
    notifyListeners();
  }

  /// Mencari kota, menyimpan koordinatnya, lalu memuat cuacanya.
  /// Mengembalikan false kalau kota tidak ditemukan.
  Future<bool> setCity(String name) async {
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': name,
        'count': '1',
        'format': 'json',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return false;

      final results = jsonDecode(res.body)['results'] as List?;
      if (results == null || results.isEmpty) return false;

      final r = results.first as Map<String, dynamic>;
      city = r['name'] as String;
      usingGps = false;
      lat = (r['latitude'] as num).toDouble();
      lon = (r['longitude'] as num).toDouble();
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Satu objek yang dipakai bersama oleh seluruh aplikasi.
final weatherStore = WeatherStore();