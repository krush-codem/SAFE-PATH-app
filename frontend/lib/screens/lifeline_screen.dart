import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';
import '../models/guardian.dart';
import '../widgets/dynamic_ui.dart';

class LifelineScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialPhone;

  const LifelineScreen({
    super.key,
    this.initialName,
    this.initialPhone,
  });

  @override
  ConsumerState<LifelineScreen> createState() => _LifelineScreenState();
}

class _LifelineScreenState extends ConsumerState<LifelineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _fullPhoneNumber;
  bool _isSaving = false;

  final List<_LocalGuardian> _pendingGuardians = [];
  List<Guardian> _initGuardians = [];

  @override
  void initState() {
    super.initState();
    
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameCtrl.text = widget.initialName!;
    } else {
      final user = ref.read(currentUserProvider);
      final metaName = user?.userMetadata?['full_name'] as String? ?? 
                       user?.userMetadata?['name'] as String?;
      if (metaName != null) {
        _nameCtrl.text = metaName;
      }
    }

    final existing = ref.read(guardiansProvider).value ?? [];
    _initGuardians = List.from(existing);
    for (var g in existing) {
      _pendingGuardians.add(_LocalGuardian(name: g.fullName, phone: g.phone, id: g.id));
    }

    if (widget.initialPhone != null) {
      _fullPhoneNumber = widget.initialPhone;
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _addPendingGuardian() {
    final name = _nameCtrl.text.trim();
    final phone = _fullPhoneNumber;

    if (name.isEmpty || phone == null) {
      _showSnack('Please fill in both name and a valid phone number');
      return;
    }
    
    String phoneDigits = phone.replaceFirst('+91', '');
    if (phoneDigits.length != 10) {
      _showSnack('Phone number must be exactly 10 digits');
      return;
    }

    final myProfile = ref.read(profileProvider).value;
    if (myProfile?.phoneNumber != null && myProfile!.phoneNumber == phone) {
      _showSnack('SECURITY ALERT: You cannot add your own number to your SOS circle.');
      return;
    }

    if (_pendingGuardians.length >= 7) {
      _showSnack('Maximum 7 guardians allowed');
      return;
    }

    setState(() {
      _pendingGuardians.add(_LocalGuardian(name: name, phone: phone, id: null));
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _fullPhoneNumber = null;
    });
  }

  void _removeGuardian(int index) {
    setState(() => _pendingGuardians.removeAt(index));
  }

  Future<void> _saveAndContinue() async {
    if (_pendingGuardians.isEmpty) {
      _showSnack('Add at least one guardian before continuing');
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(authRepositoryProvider);

      final currentIds = _pendingGuardians.where((g) => g.id != null).map((g) => g.id!).toSet();
      for (final oldG in _initGuardians) {
        if (!currentIds.contains(oldG.id)) {
          await repo.deleteGuardian(oldG.id);
        }
      }

      for (final g in _pendingGuardians) {
        if (g.id == null) {
          await repo.addGuardian(fullName: g.name, phone: g.phone);
        }
      }

      await repo.markLifelineComplete();

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      _showSnack('Error saving guardians: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final securityLevel = (_pendingGuardians.length / 7).clamp(0.0, 1.0);
    final levelText = _pendingGuardians.length < 2 ? 'BASIC' : _pendingGuardians.length < 4 ? 'MODERATE' : 'ULTRA-SECURE';
    final levelColor = _pendingGuardians.length < 2 ? Colors.orangeAccent : _pendingGuardians.length < 4 ? Colors.blueAccent : const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INITIALIZING', style: TextStyle(color: Color(0xFF5C79FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Lifeline Setup', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      UserAvatar(
                        url: profile?.avatarUrl,
                        name: profile?.fullName,
                        size: 44,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: CircularProgressIndicator(
                                    value: securityLevel,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                                  ),
                                ),
                                Text(
                                  '${_pendingGuardians.length}/7',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SECURITY STATUS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                    levelText,
                                    style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Guardian network strength', style: TextStyle(color: Colors.white24, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Guardians will receive real-time SOS alerts and automated messages.',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text('ADD EMERGENCY CONTACT', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildInputField(controller: _nameCtrl, label: 'GUARDIAN NAME', icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  
                  _buildPhoneField(),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addPendingGuardian,
                      icon: const Icon(Icons.add_moderator),
                      label: const Text('ADD TO SOS CIRCLE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C79FF).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFF5C79FF),
                        side: const BorderSide(color: Color(0xFF5C79FF), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (_pendingGuardians.isNotEmpty) ...[
                    const Text('YOUR SOS CIRCLE', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingGuardians.length,
                      itemBuilder: (context, index) {
                        final g = _pendingGuardians[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                UserAvatar(name: g.name, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(g.phone, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _removeGuardian(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C79FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: const Color(0xFF5C79FF).withValues(alpha: 0.5),
                      ),
                      child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('INITIALIZE SOS CIRCLE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white38, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: IntlPhoneField(
        controller: _phoneCtrl,
        initialCountryCode: 'IN',
        dropdownTextStyle: const TextStyle(color: Colors.white),
        style: const TextStyle(color: Colors.white),
        dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.white38),
        onChanged: (phone) {
          _fullPhoneNumber = phone.completeNumber;
        },
        decoration: const InputDecoration(
          labelText: 'PHONE NUMBER',
          labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1E2633),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E2633),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.blueAccent),
                SizedBox(width: 12),
                Text('Final Confirmation', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              'These contacts will be alerted immediately if you trigger an SOS. Ensure these numbers are correct and the people are trusted.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('RE-CHECK', style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('CONFIRM'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _LocalGuardian {
  final String name;
  final String phone;
  final String? id;
  _LocalGuardian({required this.name, required this.phone, this.id});
}
