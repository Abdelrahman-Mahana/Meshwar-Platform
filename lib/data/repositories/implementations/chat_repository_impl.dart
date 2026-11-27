import 'dart:async';
import '../../models/chat_message_model.dart';
import '../contracts/i_chat_repository.dart';

class ChatRepositoryImpl implements IChatRepository {
  final Map<String, List<ChatMessageModel>> _conversations = {};
  final Map<String, StreamController<List<ChatMessageModel>>> _streamControllers = {};
  int _messageSeq = 0;

  List<ChatMessageModel> _ensureConversationSeeded(
    String conversationId, {
    String? peerName,
    String? routeContext,
  }) {
    final cleanId = conversationId.trim().isEmpty ? 'chat_default' : conversationId.trim();
    if (_conversations.containsKey(cleanId)) {
      return _conversations[cleanId]!;
    }

    final resolvedPeer = (peerName != null && peerName.trim().isNotEmpty)
        ? peerName.trim()
        : 'الكابتن';
    final resolvedRoute = (routeContext != null && routeContext.trim().isNotEmpty)
        ? routeContext.trim()
        : 'المسار المتفق عليه';
    final now = DateTime.now();

    final seeded = <ChatMessageModel>[
      ChatMessageModel(
        id: 'seed_1_$cleanId',
        conversationId: cleanId,
        senderId: 'peer_seed',
        senderName: resolvedPeer,
        text:
            'السلام عليكم، أنا جاهز للتنسيق بخصوص ($resolvedRoute) والالتزام بالموعد المحدد.',
        timestamp: now.subtract(const Duration(minutes: 12)),
        isRead: true,
      ),
      ChatMessageModel(
        id: 'seed_2_$cleanId',
        conversationId: cleanId,
        senderId: 'peer_seed',
        senderName: resolvedPeer,
        text:
            'يرجى مشاركة موقعك عند الوصول لنقطة الالتقاء لتسهيل الوصول المباشر.',
        timestamp: now.subtract(const Duration(minutes: 9)),
        isRead: true,
      ),
    ];

    _conversations[cleanId] = seeded;
    return seeded;
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    String? peerName,
    String? routeContext,
  }) async {
    final list = _ensureConversationSeeded(
      conversationId,
      peerName: peerName,
      routeContext: routeContext,
    );
    return List<ChatMessageModel>.unmodifiable(list);
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? attachmentUrl,
  }) async {
    final cleanId = conversationId.trim().isEmpty ? 'chat_default' : conversationId.trim();
    _ensureConversationSeeded(cleanId);

    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${++_messageSeq}',
      conversationId: cleanId,
      senderId: senderId.trim().isEmpty ? 'usr_me_local' : senderId.trim(),
      senderName: senderName.trim().length >= 2 ? senderName.trim() : 'مستخدم مشوار',
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: true,
      attachmentUrl: (attachmentUrl != null && attachmentUrl.trim().isNotEmpty)
          ? attachmentUrl.trim()
          : null,
    );

    _conversations.putIfAbsent(cleanId, () => <ChatMessageModel>[]).add(message);
    final controller = _streamControllers[cleanId];
    if (controller != null && !controller.isClosed) {
      controller.add(List<ChatMessageModel>.unmodifiable(_conversations[cleanId]!));
    }

    return message;
  }

  /// Synchronizes external messages (e.g. fetched from Firestore) into the local cache.
  void mergeRemoteMessages(
    String conversationId,
    List<ChatMessageModel> remoteMessages,
  ) {
    final cleanId = conversationId.trim().isEmpty ? 'chat_default' : conversationId.trim();
    if (remoteMessages.isEmpty) return;

    final existing = _conversations[cleanId] ?? <ChatMessageModel>[];
    final byId = <String, ChatMessageModel>{
      for (final m in existing)
        if (!m.id.startsWith('seed_')) m.id: m,
    };
    for (final rm in remoteMessages) {
      if (rm.id.isNotEmpty) {
        byId[rm.id] = rm;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _conversations[cleanId] = merged;

    final controller = _streamControllers[cleanId];
    if (controller != null && !controller.isClosed) {
      controller.add(List<ChatMessageModel>.unmodifiable(merged));
    }
  }

  @override
  Stream<List<ChatMessageModel>> streamMessages(String conversationId) {
    final cleanId = conversationId.trim().isEmpty ? 'chat_default' : conversationId.trim();
    _streamControllers.putIfAbsent(
      cleanId,
      () => StreamController<List<ChatMessageModel>>.broadcast(),
    );

    return Stream<List<ChatMessageModel>>.multi((subscriber) {
      final initial = List<ChatMessageModel>.unmodifiable(
        _ensureConversationSeeded(cleanId),
      );
      subscriber.add(initial);
      final sub = _streamControllers[cleanId]!.stream.listen(
        subscriber.add,
        onError: subscriber.addError,
        onDone: subscriber.close,
      );
      subscriber.onCancel = sub.cancel;
    });
  }
}
