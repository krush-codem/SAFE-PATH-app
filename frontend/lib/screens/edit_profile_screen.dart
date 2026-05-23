import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _sosPhoneController;
  String? _fullPhoneNumber;
  String? _fullSOSPhoneNumber;
  Uint8List? _localImageBytes;
  String? _localImageName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _sosPhoneController = TextEditingController();
    
    // Initial load if data is already there
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        _updateControllers(profile);
      }
    });
  }

  void _updateControllers(Profile profile) {
    setState(() {
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = _stripCountryCode(profile.phoneNumber) ?? '';
      _sosPhoneController.text = _stripCountryCode(profile.sosPhone) ?? '';
      _fullPhoneNumber = profile.phoneNumber;
      _fullSOSPhoneNumber = profile.sosPhone;
    });
  }

  String? _stripCountryCode(String? phone) {
    if (phone == null) return null;
    // Basic stripping logic for initial controller text if using IntlPhoneField
    // IntlPhoneField usually handles the initial value better if we pass the whole thing
    // but here we just want the national number if possible.
    return phone; 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sosPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _localImageBytes = bytes;
        _localImageName = pickedFile.name;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _fullPhoneNumber?.trim(),
      'sos_phone': _fullSOSPhoneNumber?.trim(),
    };

    try {
      if (_localImageBytes != null) {
        await ref.read(authNotifierProvider.notifier).uploadAvatar(
          bytes: _localImageBytes,
          filePath: _localImageName,
        );
      }
      await ref.read(authNotifierProvider.notifier).updateProfile(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for profile changes to update controllers if they were empty
    ref.listen<AsyncValue<Profile?>>(profileProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        // Only update if the user hasn't started typing yet or if we just got the data
        if (_nameController.text.isEmpty && next.value!.fullName.isNotEmpty) {
          _updateControllers(next.value!);
        }
      }
    });

    final profile = ref.watch(profileProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFILE SETTINGS',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Profile Settings',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your security profile and personal preferences.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                        ],
                        image: _localImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_localImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : (profile?.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(profile!.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image: NetworkImage(
                                        'https://via.placeholder.com/150'),
                                    fit: BoxFit.cover,
                                  )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        'EDIT PHOTO',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSecurityStatusCard(context),
              const SizedBox(height: 32),
              _buildInputField(
                context,
                label: 'FULL NAME',
                controller: _nameController,
                hint: 'Enter your full name',
              ),
              const SizedBox(height: 24),
              _buildInputField(
                context,
                label: 'EMAIL ADDRESS',
                controller: _emailController,
                hint: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              _FieldLabel(context, 'PHONE NUMBER'),
              const SizedBox(height: 8),
              _buildPhoneField(
                context,
                initialValue: _fullPhoneNumber,
                onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
              ),
              const SizedBox(height: 24),
              _FieldLabel(context, 'SOS MESSAGE NUMBER', isSOS: true),
              const SizedBox(height: 8),
              _buildPhoneField(
                context,
                initialValue: _fullSOSPhoneNumber,
                isSOS: true,
                onChanged: (phone) => _fullSOSPhoneNumber = phone.completeNumber,
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Discard\nChanges',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.dark 
                            ? theme.primaryColor.withValues(alpha: 0.8) 
                            : theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Update Profile',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Status',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ENCRYPTED & ACTIVE',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your personal data is protected by AES-256 military-grade encryption.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _FieldLabel(BuildContext context, String label, {bool isSOS = false}) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isSOS ? const Color(0xFFF25C05) : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildPhoneField(
    BuildContext context, {
    required String? initialValue,
    required Function(PhoneNumber) onChanged,
    bool isSOS = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isSOS 
            ? const Color(0xFFF25C05).withValues(alpha: 0.05) 
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSOS ? const Color(0xFFF25C05).withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: IntlPhoneField(
        initialValue: initialValue,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyLarge?.color,
        ),
        dropdownTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: 'Phone Number',
          hintStyle: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          suffixIcon: isSOS ? const Icon(Icons.emergency_share, color: Color(0xFFF25C05), size: 20) : null,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool isSOS = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(context, label, isSOS: isSOS),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
            filled: true,
            fillColor: isSOS 
                ? const Color(0xFFF25C05).withValues(alpha: 0.05) 
                : Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            suffixIcon: isSOS ? const Icon(Icons.emergency_share, color: Color(0xFFF25C05), size: 20) : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isSOS ? const Color(0xFFF25C05).withValues(alpha: 0.1) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isSOS ? const Color(0xFFF25C05) : Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
