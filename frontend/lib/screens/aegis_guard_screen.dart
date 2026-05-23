import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/virustotal_repository.dart';

class AegisGuardScreen extends ConsumerStatefulWidget {
  const AegisGuardScreen({super.key});

  @override
  ConsumerState<AegisGuardScreen> createState() => _AegisGuardScreenState();
}

class _AegisGuardScreenState extends ConsumerState<AegisGuardScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isUrlScanning = false;
  bool _isFileScanning = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleUrlScan() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isUrlScanning = true);

    try {
      final result = await ref.read(virusTotalProvider).scanUrl(url);
      _showResultPopup(result);
    } catch (e) {
      _showErrorPopup(e.toString());
    } finally {
      if (mounted) setState(() => _isUrlScanning = false);
    }
  }

  Future<void> _handleFileScan() async {
    setState(() => _isFileScanning = true);

    try {
      final result = await FilePicker.platform.pickFiles(withData: true);

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        if (platformFile.bytes == null) throw Exception('File data unreadable');

        final scanResult = await ref.read(virusTotalProvider).scanFileBytes(
          platformFile.bytes!,
          platformFile.name,
        );

        _showResultPopup(scanResult);
      }
    } catch (e) {
      _showErrorPopup(e.toString());
    } finally {
      if (mounted) setState(() => _isFileScanning = false);
    }
  }

  void _showResultPopup(ScanResult result) {
    if (!mounted) return;
    final isMalicious = result.isMalicious;
    
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1220),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isMalicious ? Colors.redAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMalicious ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMalicious ? Icons.gpp_bad : Icons.gpp_good,
                  color: isMalicious ? Colors.redAccent : Colors.greenAccent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  isMalicious ? 'THREAT DETECTED' : 'SYSTEM SECURE',
                  style: GoogleFonts.outfit(
                    color: isMalicious ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, color: isMalicious ? Colors.redAccent : Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${result.malicious} of ${result.totalEngines} engines detected threats',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (result.link != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {}, // Link to VT GUI could go here
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('VIEW FULL REPORT', style: TextStyle(fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMalicious ? Colors.redAccent : Colors.greenAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorPopup(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030A14), // Ultra deep navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B498A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 20),
          ),
        ),
        title: Text(
          'SAFEPATH',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSentinelBanner(),
                const SizedBox(height: 32),
                _buildScanHeader('Scan URL', 'PROTOCOL 4.0'),
                const SizedBox(height: 16),
                _buildUrlScanBox(),
                const SizedBox(height: 32),
                _buildScanHeader('Scan File', 'DEEP SANDBOX'),
                const SizedBox(height: 16),
                _buildFileScanBox(),
                const SizedBox(height: 32),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isUrlScanning || _isFileScanning) _buildScanningOverlay(),
        ],
      ),
    );
  }

  Widget _buildSentinelBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2545), Color(0xFF030A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.shield_outlined, size: 100, color: Colors.blue.withValues(alpha: 0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SENTINEL STATUS',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64B5F6),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Digital Perimeter is Secure',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FadeTransition(
                      opacity: _pulseController,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Surveillance Active',
                      style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildUrlScanBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1220),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://secure-link.com/check',
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
                icon: const Icon(Icons.link, color: Colors.white24, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isUrlScanning ? null : _handleUrlScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
              icon: _isUrlScanning 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.radar),
              label: Text(
                'Check Link',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Instant analysis for phishing, malware, and social engineering threats.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFileScanBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1220),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.file_upload_outlined, color: Colors.blueAccent, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Drop secure file here',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Supports PDF, EXE, ZIP up to 32MB',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _isFileScanning ? null : _handleFileScan,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white.withValues(alpha: 0.03),
            ),
            child: _isFileScanning
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('BROWSE FILES', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RadarScanner(),
            const SizedBox(height: 40),
            Text(
              'SCANNING PERIMETER...',
              style: GoogleFonts.outfit(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Engaging Deep Sandbox Protocols',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class RadarScanner extends StatefulWidget {
  const RadarScanner({super.key});

  @override
  State<RadarScanner> createState() => _RadarScannerState();
}

class _RadarScannerState extends State<RadarScanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: RadarPainter(_controller.value),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double angle;
  RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Circles
    canvas.drawCircle(center, radius, paintCircle);
    canvas.drawCircle(center, radius * 0.7, paintCircle);
    canvas.drawCircle(center, radius * 0.4, paintCircle);

    // Grid lines
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), paintCircle);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), paintCircle);

    // Radar scan
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.blueAccent.withValues(alpha: 0.0), Colors.blueAccent.withValues(alpha: 0.4)],
        stops: const [0.8, 1.0],
        transform: GradientRotation(angle * 2 * 3.14159),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Scanner beam edge
    final beamPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.0;
    
    final lineAngle = angle * 2 * 3.14159;
    canvas.drawLine(
      center,
      Offset(center.dx + radius * (lineAngle).cos(), center.dy + radius * (lineAngle).sin()),
      beamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension on double {
  double cos() => math.cos(this);
  double sin() => math.sin(this);
}
