import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';
import '../models/guardian.dart';
import '../widgets/dynamic_ui.dart';
import '../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).value;
    final securityLevel = (_pendingGuardians.length / 7).clamp(0.0, 1.0);
    final levelText = _pendingGuardians.length < 2 ? 'BASIC' : _pendingGuardians.length < 4 ? 'MODERATE' : 'ULTRA-SECURE';
    final levelColor = _pendingGuardians.length < 2 ? Colors.orangeAccent : _pendingGuardians.length < 4 ? Colors.blueAccent : const Color(0xFF4CAF50);

    return Scaffold(
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
                          Text('INITIALIZING PROTOCOL', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Lifeline Setup', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900)),
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
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: CircularProgressIndicator(
                                    value: securityLevel,
                                    strokeWidth: 8,
                                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                                  ),
                                ),
                                Text(
                                  '${_pendingGuardians.length}/7',
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SECURITY STATUS', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(
                                    levelText,
                                    style: TextStyle(color: levelColor, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Guardian network strength', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.security, color: theme.colorScheme.onSurface.withValues(alpha: 0.38), size: 16),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Guardians will receive real-time SOS alerts and automated messages via secure channel.',
                                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text('ADD EMERGENCY OPERATIVE', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  
                  _buildInputField(context, controller: _nameCtrl, label: 'FULL NAME', icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  
                  _buildPhoneField(context),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _addPendingGuardian,
                      icon: const Icon(Icons.add_moderator),
                      label: const Text('ADD TO SOS CIRCLE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: theme.colorScheme.onSurface, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  if (_pendingGuardians.isNotEmpty) ...[
                    Text('ACTIVE SOS CIRCLE', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingGuardians.length,
                      itemBuilder: (context, index) {
                        final g = _pendingGuardians[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(name: g.name, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(g.name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 15)),
                                      Text(g.phone, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.onSurface.withValues(alpha: 0.38), size: 22),
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
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.onSurface,
                        foregroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                        ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: theme.colorScheme.surface, strokeWidth: 3))
                        : const Text('INITIALIZE NETWORK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, {required TextEditingController controller, required String label, required IconData icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          icon: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.38), size: 20),
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.5),
      ),
      child: IntlPhoneField(
        controller: _phoneCtrl,
        initialCountryCode: 'IN',
        dropdownTextStyle: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
        dropdownIcon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
        onChanged: (phone) {
          _fullPhoneNumber = phone.completeNumber;
        },
        decoration: InputDecoration(
          labelText: 'PHONE NUMBER',
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.12))),
      ),
    );
  }

  Future<bool> _showConfirmationDialog() async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.dividerColor, width: 2),
            ),
            title: Row(
              children: [
                Icon(Icons.verified_user, color: theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                Text('VERIFY CIRCLE', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
            content: Text(
              'These contacts will be alerted immediately if you trigger an SOS. Ensure these numbers are correct and the people are trusted.',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('RE-CHECK', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontWeight: FontWeight.w900)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.onSurface, foregroundColor: theme.colorScheme.surface),
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
