import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/guardian.dart';
import '../widgets/dynamic_ui.dart';

class ManageGuardiansScreen extends ConsumerStatefulWidget {
  const ManageGuardiansScreen({super.key});

  @override
  ConsumerState<ManageGuardiansScreen> createState() => _ManageGuardiansScreenState();
}

class _ManageGuardiansScreenState extends ConsumerState<ManageGuardiansScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final guardiansAsync = ref.watch(guardianNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Security Circle',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NETWORK STRENGTH', style: TextStyle(color: Color(0xFF5C79FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Manage Guardians', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    
                    guardiansAsync.when(
                      data: (guardians) => _buildSecurityHUD(guardians.length),
                      loading: () => const SkeletonBox(height: 80),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 32),
                    
                    const Text('ACTIVE CONTACTS', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    guardiansAsync.when(
                      data: (guardians) => _buildGuardiansList(guardians),
                      loading: () => Column(
                        children: List.generate(3, (i) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SkeletonBox(height: 72),
                        )),
                      ),
                      error: (err, _) => Center(
                        child: Text('Error loading guardians: $err', style: const TextStyle(color: Colors.white38)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHUD(int count) {
    final double progress = (count / 7).clamp(0.0, 1.0);
    final Color color = count < 2 ? Colors.orangeAccent : count < 4 ? const Color(0xFF5C79FF) : const Color(0xFF4CAF50);
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0 ? 'Critically Low' : count < 4 ? 'Moderate' : 'Ultra Secure',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count of 7 slots filled',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.shield_outlined, color: Colors.white24, size: 48),
        ],
      ),
    );
  }

  Widget _buildGuardiansList(List<Guardian> guardians) {
    return Column(
      children: [
        if (guardians.isEmpty)
          _buildEmptyState()
        else
          ...guardians.map((g) => _buildGuardianCard(g)),
        const SizedBox(height: 20),
        if (guardians.length < 7) _buildAddButton(),
      ],
    );
  }

  Widget _buildGuardianCard(Guardian guardian) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(name: guardian.fullName, size: 44, showStatus: true, isOnline: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guardian.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(guardian.phone, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Row(
              children: [
                _buildCircularBtn(Icons.edit_outlined, const Color(0xFF5C79FF).withValues(alpha: 0.1), const Color(0xFF5C79FF), () => _showEditDialog(guardian)),
                const SizedBox(width: 8),
                _buildCircularBtn(Icons.delete_outline, Colors.redAccent.withValues(alpha: 0.1), Colors.redAccent, () => _showDeleteConfirm(guardian)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularBtn(IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          const Icon(Icons.people_alt_outlined, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          const Text('No Guardians Found', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Your SOS alerts need a destination.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddDialog,
      child: DottedBorder(
        color: const Color(0xFF5C79FF).withValues(alpha: 0.3),
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF5C79FF), size: 20),
              SizedBox(width: 12),
              Text('ADD NEW GUARDIAN', style: TextStyle(color: Color(0xFF5C79FF), fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    _showGuardianDialog(null);
  }

  void _showEditDialog(Guardian g) {
    _showGuardianDialog(g);
  }

  void _showGuardianDialog(Guardian? guardian) {
    final nameCtrl = TextEditingController(text: guardian?.fullName);
    final phoneCtrl = TextEditingController(text: guardian?.phone);
    String? fullPhone = guardian?.phone;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(guardian == null ? 'ADD GUARDIAN' : 'EDIT GUARDIAN', style: const TextStyle(color: Color(0xFF5C79FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Trusted Contact Info', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildModalField(nameCtrl, 'Full Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildModalPhoneField(phoneCtrl, (val) => fullPhone = val),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C79FF), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || fullPhone == null) return;
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    try {
                      if (guardian == null) {
                        await ref.read(guardianNotifierProvider.notifier).addGuardian(fullName: nameCtrl.text, phone: fullPhone!);
                      } else {
                        await ref.read(guardianNotifierProvider.notifier).updateGuardian(guardianId: guardian.id, fullName: nameCtrl.text, phone: fullPhone!);
                      }
                    } catch (e) {
                      _showSnack(e.toString());
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: Text(guardian == null ? 'ADD CONTACT' : 'SAVE CHANGES', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(icon: Icon(icon, color: Colors.white38, size: 20), hintText: hint, hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none),
      ),
    );
  }

  Widget _buildModalPhoneField(TextEditingController ctrl, ValueChanged<String?> onChange) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: IntlPhoneField(
        controller: ctrl,
        initialCountryCode: 'IN',
        dropdownTextStyle: const TextStyle(color: Colors.white),
        style: const TextStyle(color: Colors.white),
        onChanged: (p) => onChange(p.completeNumber),
        decoration: const InputDecoration(hintText: 'Phone Number', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }

  void _showDeleteConfirm(Guardian g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2633),
        title: const Text('Remove Guardian?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove ${g.fullName} from your security circle?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            await ref.read(guardianNotifierProvider.notifier).removeGuardian(g.id);
          }, child: const Text('REMOVE', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
  }
}

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  const DottedBorder({super.key, required this.child, this.color = Colors.black, this.strokeWidth = 1, this.dashPattern = const [3, 1], this.borderType = BorderType.Rect, this.radius = Radius.zero});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(color: color, strokeWidth: strokeWidth, dashPattern: dashPattern, borderType: borderType, radius: radius),
      child: child,
    );
  }
}

enum BorderType { Rect, RRect, Circle, Oval }

class _DottedPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  _DottedPainter({required this.color, required this.strokeWidth, required this.dashPattern, required this.borderType, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    final Path path = Path();

    if (borderType == BorderType.RRect) {
      path.addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, radius));
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        final double len = dashPattern[0];
        dashPath.addPath(measurePath.extractPath(distance, distance + len), Offset.zero);
        distance += len + dashPattern[1];
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedPainter oldDelegate) => false;
}
