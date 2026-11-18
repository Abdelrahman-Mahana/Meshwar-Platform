import '../../models/chat_message_model.dart';

abstract class IChatRepository {
  Future<List<ChatMessageModel>> getMessages(String conversationId);
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  });
  Stream<List<ChatMessageModel>> streamMessages(String conversationId);
}
