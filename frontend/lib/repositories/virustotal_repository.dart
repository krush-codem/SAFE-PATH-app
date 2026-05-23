import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ScanResult {
  final String id;
  final String status;
  final int malicious;
  final int suspicious;
  final int undetected;
  final int harmless;
  final int totalEngines;
  final String? link;

  ScanResult({
    required this.id,
    required this.status,
    required this.malicious,
    required this.suspicious,
    required this.undetected,
    required this.harmless,
    required this.totalEngines,
    this.link,
  });

  bool get isMalicious => malicious > 0 || suspicious > 1;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] ?? '',
      status: json['status'] ?? 'unknown',
      malicious: json['malicious'] ?? 0,
      suspicious: json['suspicious'] ?? 0,
      undetected: json['undetected'] ?? 0,
      harmless: json['harmless'] ?? 0,
      totalEngines: json['total_engines'] ?? 0,
      link: json['link'],
    );
  }
}

final virusTotalProvider = Provider((ref) => VirusTotalRepository());

class VirusTotalRepository {
  late final Dio _dio;

  VirusTotalRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60), // Longer for polling
    ));
  }

  /// Returns [ScanResult] for the analyzed URL.
  Future<ScanResult> scanUrl(String url) async {
    try {
      final response = await _dio.post(
        '/security/scan-url',
        data: {'url': url},
      );

      if (response.statusCode == 200) {
        return ScanResult.fromJson(response.data);
      }
      throw Exception('Failed to get scan results');
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'URL scan failed via backend';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred during URL scan.');
    }
  }

  /// Scan file bytes via the Safe Path backend proxy.
  Future<ScanResult> scanFileBytes(Uint8List bytes, String fileName) async {
    try {
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        '/security/scan-file',
        data: formData,
      );

      if (response.statusCode == 200) {
        return ScanResult.fromJson(response.data);
      }
      throw Exception('Failed to upload file to security portal');
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'File scan failed via backend';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred during file scan.');
    }
  }
}

