import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/env_config.dart';

enum WebSocketConnectionState { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  final String _jwtToken;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<WebSocketConnectionState>.broadcast();
  
  WebSocketConnectionState _currentState = WebSocketConnectionState.disconnected;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  WebSocketService(this._jwtToken) {
    _connect();
  }

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<WebSocketConnectionState> get connectionState => _stateController.stream;
  WebSocketConnectionState get currentState => _currentState;

  void _updateState(WebSocketConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  String _getWsUrl() {
    final baseUrl = EnvConfig.backendBaseUrl;
    final wsBase = baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/chat/ws';
  }

  void _connect() {
    if (_isDisposed) return;
    if (_currentState == WebSocketConnectionState.connected || 
        _currentState == WebSocketConnectionState.connecting) {
      return;
    }

    _updateState(WebSocketConnectionState.connecting);
    
    try {
      final wsUrl = _getWsUrl();
      debugPrint('Connecting to WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Send Auth Handshake
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'token': _jwtToken
      }));

      _channel!.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data);
            if (parsed['type'] == 'status' && parsed['message'] == 'Authenticated successfully') {
              debugPrint('WebSocket Authenticated.');
              _updateState(WebSocketConnectionState.connected);
              // Reset reconnect timer on successful connection
              _reconnectTimer?.cancel();
            } else {
              _messageController.add(parsed);
            }
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket Closed.');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket Connection Exception: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_isDisposed) return;
    _updateState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('Attempting to reconnect WebSocket...');
      _connect();
    });
  }

  void sendMessage(String receiverId, String content) {
    if (_currentState != WebSocketConnectionState.connected || _channel == null) {
      debugPrint('Cannot send message: WebSocket not connected.');
      return;
    }

    final payload = {
      'type': 'chat',
      'payload': {
        'receiver_id': receiverId,
        'content': content
      }
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _stateController.close();
    _updateState(WebSocketConnectionState.disconnected);
  }
}
