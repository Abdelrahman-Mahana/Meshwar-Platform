import 'dart:async';
import '../../models/chat_message_model.dart';
import '../contracts/i_chat_repository.dart';

class ChatRepositoryImpl implements IChatRepository {
  final Map<String, List<ChatMessageModel>> _conversations = {};
  final Map<String, StreamController<List<ChatMessageModel>>> _streamControllers = {};

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    return _conversations[conversationId] ?? [];
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      isRead: true,
    );

    _conversations.putIfAbsent(conversationId, () => []).add(message);
    if (_streamControllers.containsKey(conversationId)) {
      _streamControllers[conversationId]?.add(List.from(_conversations[conversationId]!));
    }

    return message;
  }

  @override
  Stream<List<ChatMessageModel>> streamMessages(String conversationId) {
    if (!_streamControllers.containsKey(conversationId)) {
      _streamControllers[conversationId] = StreamController<List<ChatMessageModel>>.broadcast();
    }
    // Emit initial messages
    Timer.run(() {
      _streamControllers[conversationId]?.add(_conversations[conversationId] ?? []);
    });
    return _streamControllers[conversationId]!.stream;
  }
}
