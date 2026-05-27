import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/journey_provider.dart';
import '../models/chat_message.dart';
import '../models/guardian.dart';
import '../providers/chat_provider.dart';
import '../widgets/live_map_tab.dart';
import '../widgets/dynamic_ui.dart';

import '../theme/app_theme.dart';

class SafeCircleChatScreen extends ConsumerStatefulWidget {
  const SafeCircleChatScreen({super.key});

  @override
  ConsumerState<SafeCircleChatScreen> createState() => _SafeCircleChatScreenState();
}

class _SafeCircleChatScreenState extends ConsumerState<SafeCircleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  Guardian? _selectedGuardian;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final guardiansAsync = ref.watch(guardiansProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentIndex == 0 
            ? (_selectedGuardian == null ? 'Safe Circle Chat' : _selectedGuardian!.fullName)
            : 'Live Map', 
          style: theme.textTheme.titleLarge,
        ),
        leading: _selectedGuardian != null 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => setState(() => _selectedGuardian = null),
            )
          : null,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.info_outline, color: colorScheme.primary),
              onPressed: () {
                 showDialog(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     title: const Text('Security Alerts'),
                     content: const Text(
                       'The SYSTEM channel provides official OTPs and security updates. '
                       'Guardian chats allow you to communicate with your trust circle during journeys.',
                     ),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('GOT IT')),
                     ],
                   ),
                 );
              },
            ),
          // Sub-tab switcher in AppBar instead of bottom nav to avoid conflict with MainLayout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, icon: Icon(Icons.chat_bubble_outline, size: 18), label: Text('CHAT', style: TextStyle(fontSize: 10))),
                ButtonSegment(value: 1, icon: Icon(Icons.map_outlined, size: 18), label: Text('MAP', style: TextStyle(fontSize: 10))),
              ],
              selected: {_currentIndex},
              onSelectionChanged: (val) => setState(() => _currentIndex = val.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Chat
          guardiansAsync.when(
            data: (guardians) {
              if (_selectedGuardian == null) {
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: guardians.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // SYSTEM CHAT ITEM
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedGuardian = Guardian(
                                id: 'system',
                                userId: 'system',
                                fullName: 'SYSTEM Alert',
                                phone: 'Official Channel',
                                createdAt: DateTime.now(),
                                isAppUser: true,
                              ));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.shield_outlined, color: colorScheme.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('SYSTEM Alert', style: theme.textTheme.titleMedium),
                                        Text('Official OTP & Security Updates', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.24)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final g = guardians[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        child: InkWell(
                          onTap: () => setState(() => _selectedGuardian = g),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                UserAvatar(
                                  url: g.avatarUrl,
                                  name: g.fullName,
                                  size: 40,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(g.fullName, style: theme.textTheme.titleMedium),
                                      Text(g.phone, style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                 Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.24)),
                                 const SizedBox(width: 8),
                                 // Permission Toggle (only for real guardians)
                                 Column(
                                   children: [
                                     Transform.scale(
                                       scale: 0.7,
                                       child: CupertinoSwitch(
                                         value: ref.watch(journeyProvider).locationPermissionIds.contains(g.id),
                                         activeColor: colorScheme.primary,
                                         onChanged: (_) => ref.read(journeyProvider.notifier).toggleLocationPermission(g.id),
                                       ),
                                     ),
                                     Text('LIVE ON', style: theme.textTheme.labelSmall?.copyWith(fontSize: 8)),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                         ),
                       ),
                     );
                  },
                );
              }

              return _ChatView(
                guardian: _selectedGuardian!,
                onBack: () => setState(() => _selectedGuardian = null),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.error))),
          ),
          
          // Tab 1: Map
          const LiveMapTab(),
        ],
      ),
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  final Guardian guardian;
  final VoidCallback onBack;

  const _ChatView({required this.guardian, required this.onBack});

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    // System channel is read-only for users
    if (widget.guardian.id == 'system') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System alerts are broadcast-only.'))
      );
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    ref.read(optimisticMessagesProvider.notifier).addMessage(
      widget.guardian.id,
      ChatMessage(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUser.id,
        receiverId: widget.guardian.id,
        content: content,
        createdAt: DateTime.now(),
      ),
    );

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
        currentUser.id,
        widget.guardian.id,
        content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messagesAsync = ref.watch(allMessagesProvider(widget.guardian.id));

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.guardian.id == 'system' ? Icons.shield_outlined : Icons.chat_bubble_outline,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.guardian.id == 'system' 
                          ? 'Waiting for security updates...' 
                          : 'Start a conversation with ${widget.guardian.fullName}',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  return _MessageBubble(
                    message: msg,
                    isMe: msg.senderId != 'system' && msg.senderId != widget.guardian.id,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Error: $e')),
          ),
        ),
        if (widget.guardian.id != 'system') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24)),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: colorScheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  String _getTimeRemaining() {
    final now = DateTime.now().toUtc();
    final isSos = message.content.toUpperCase().contains('SOS ALERT');
    final isOtp = message.senderId == 'system' || message.content.contains('OTP');
    
    // SOS alerts last 30 minutes, OTPs last 10, regular messages last 5
    final duration = isSos ? 30 : (isOtp ? 10 : 5);
    
    final remaining = Duration(minutes: duration) - now.difference(message.createdAt.toUtc());
    if (remaining.isNegative) return "00:00";
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeString = _getTimeRemaining();
    if (timeString == '00:00') return const SizedBox.shrink();

    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final currentTimer = _getTimeRemaining();
        if (currentTimer == '00:00') return const SizedBox.shrink();

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: message.senderId == 'system' 
                ? colorScheme.primary.withValues(alpha: 0.15)
                : (isMe ? colorScheme.primary.withValues(alpha: 0.8) : theme.colorScheme.surface),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
              border: message.senderId == 'system' 
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3)) 
                : (isMe ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.12))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.senderId == 'system')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: colorScheme.primary, size: 10),
                        const SizedBox(width: 4),
                        Text('SYSTEM SECURE', style: TextStyle(color: colorScheme.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Text(message.content, style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.createdAt.toLocal()),
                      style: TextStyle(color: (isMe ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.38)), fontSize: 8),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 10, color: (isMe ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.38))),
                    const SizedBox(width: 4),
                    Text(currentTimer, style: TextStyle(color: colorScheme.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
