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
    final guardiansAsync = ref.watch(guardiansProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1724),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentIndex == 0 
            ? (_selectedGuardian == null ? 'Safe Circle Chat' : _selectedGuardian!.fullName)
            : 'Live Map', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentIndex == 0 && _selectedGuardian != null) {
              setState(() => _selectedGuardian = null);
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
              onPressed: () {
                 showDialog(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     backgroundColor: const Color(0xFF1E2633),
                     title: const Text('Security Alerts', style: TextStyle(color: Colors.white)),
                     content: const Text(
                       'The SYSTEM channel provides official OTPs and security updates. '
                       'Guardian chats allow you to communicate with your trust circle during journeys.',
                       style: TextStyle(color: Colors.white70),
                     ),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('GOT IT')),
                     ],
                   ),
                 );
              },
            )
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
                  padding: const EdgeInsets.all(24),
                  itemCount: guardians.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // SYSTEM CHAT ITEM
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blueAccent.withAlpha(25), Colors.transparent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blueAccent.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shield_outlined, color: Colors.blueAccent),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('SYSTEM Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text('Official OTP & Security Updates', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white24),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final g = guardians[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedGuardian = g),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2633),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: g.isAppUser ? Colors.transparent : Colors.blueAccent.withAlpha(50),
                                backgroundImage: g.avatarUrl != null ? NetworkImage(g.avatarUrl!) : null,
                                child: g.avatarUrl == null 
                                    ? Text(g.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent))
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(g.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(g.phone, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  ],
                                ),
                              ),
                               const Icon(Icons.chevron_right, color: Colors.white24),
                               const SizedBox(width: 8),
                               // Permission Toggle (only for real guardians)
                               Column(
                                 children: [
                                   CupertinoSwitch(
                                     value: ref.watch(journeyProvider).locationPermissionIds.contains(g.id),
                                     activeColor: Colors.blueAccent,
                                     onChanged: (_) => ref.read(journeyProvider.notifier).toggleLocationPermission(g.id),
                                   ),
                                   const Text('LIVE ON', style: TextStyle(color: Colors.white24, fontSize: 8)),
                                 ],
                               ),
                             ],
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
            error: (e, __) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
          
          // Tab 1: Map
          const LiveMapTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF1E2633),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Live Map'),
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
                        color: Colors.white10,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.guardian.id == 'system' 
                          ? 'Waiting for security updates...' 
                          : 'Start a conversation with ${widget.guardian.fullName}',
                        style: const TextStyle(color: Colors.white24),
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
            decoration: const BoxDecoration(
              color: Color(0xFF1E2633),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F1724),
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
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
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
                ? Colors.blueAccent.withValues(alpha: 0.15)
                : (isMe ? Colors.blueAccent.withValues(alpha: 0.8) : const Color(0xFF1E2633)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
              border: message.senderId == 'system' ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.senderId == 'system')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.blueAccent, size: 10),
                        SizedBox(width: 4),
                        Text('SYSTEM SECURE', style: TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.createdAt.toLocal()),
                      style: const TextStyle(color: Colors.white38, fontSize: 8),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.timer_outlined, size: 10, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(currentTimer, style: const TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold)),
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
