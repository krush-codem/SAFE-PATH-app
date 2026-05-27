import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/virustotal_repository.dart';
import '../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isMalicious ? colorScheme.error : colorScheme.onSurface,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMalicious ? Icons.gpp_bad : Icons.gpp_good,
                  color: isMalicious ? colorScheme.error : AppColors.successEmerald,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  isMalicious ? 'THREAT DETECTED' : 'SYSTEM SECURE',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, color: isMalicious ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.6), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${result.malicious} of ${result.totalEngines} engines flagged as malicious.',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.onSurface,
                    foregroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DISMISS PROTOCOL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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
        content: Text(error, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AEGIS GUARD',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSentinelBanner(context),
                const SizedBox(height: 40),
                _buildScanHeader(context, 'URL ANALYSIS', 'PROTOCOL 4.0'),
                const SizedBox(height: 16),
                _buildUrlScanBox(context),
                const SizedBox(height: 40),
                _buildScanHeader(context, 'FILE SANDBOX', 'DEEP SCAN'),
                const SizedBox(height: 16),
                _buildFileScanBox(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isUrlScanning || _isFileScanning) _buildScanningOverlay(context),
        ],
      ),
    );
  }

  Widget _buildSentinelBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.shield, size: 160, color: colorScheme.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SENTINEL STATUS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Digital Perimeter\nSecure.',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    FadeTransition(
                      opacity: _pulseController,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.successEmerald,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.successEmerald, blurRadius: 8)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI Surveillance Active',
                      style: TextStyle(color: AppColors.successEmerald, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

  Widget _buildScanHeader(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildUrlScanBox(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: TextField(
              controller: _urlController,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'https://secure-link.com/check',
                hintStyle: theme.textTheme.bodyMedium,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                icon: Icon(Icons.link, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isUrlScanning ? null : _handleUrlScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onSurface,
                foregroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isUrlScanning 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: colorScheme.surface))
                : const Icon(Icons.radar, size: 20),
              label: const Text(
                'EXECUTE ANALYSIS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analysis for phishing, malware, and social engineering.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFileScanBox(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(Icons.file_upload_outlined, color: colorScheme.onSurface, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'UPLOAD ENCRYPTED FILE',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'MAX 32MB • PDF, EXE, ZIP, BIN',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isFileScanning ? null : _handleFileScan,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.onSurface, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isFileScanning
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: colorScheme.onSurface))
                : const Text('BROWSE DIRECTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Positioned.fill(
      child: Container(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RadarScanner(color: colorScheme.onSurface),
            const SizedBox(height: 48),
            Text(
              'SCANNING PERIMETER',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ENGAGING DEEP SANDBOX PROTOCOLS',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
class RadarScanner extends StatefulWidget {
  final Color color;
  const RadarScanner({super.key, required this.color});

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
          painter: RadarPainter(_controller.value, widget.color),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double angle;
  final Color color;
  RadarPainter(this.angle, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

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
        colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.4)],
        stops: const [0.8, 1.0],
        transform: GradientRotation(angle * 2 * 3.14159),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Scanner beam edge
    final beamPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5;
    
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
