import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/config/app_environment.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../contracts/i_chat_repository.dart';
import '../chat_repository_impl.dart';

class FirebaseChatRepository implements IChatRepository {
  final FirebaseFirestore? _injectedFirestore;
  final ChatRepositoryImpl _localFallback = ChatRepositoryImpl();
  final Map<String, List<ChatMessageModel>> _sessionSentByConversation = {};
  final Map<String, StreamController<List<ChatMessageModel>>>
      _liveStreamControllers = {};
  final Set<String> _existingConversationIds = {};
  int _liveMsgSeq = 0;

  FirebaseChatRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  /// Closes and evicts all active broadcast controllers to prevent memory leaks.
  Future<void> dispose() async {
    final controllers = List<StreamController<List<ChatMessageModel>>>.from(
      _liveStreamControllers.values,
    );
    _liveStreamControllers.clear();
    for (final controller in controllers) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  bool get _isLiveBackendMode =>
      AppEnvironment.isFirebaseRuntimeActive ||
      AppEnvironment.flavor != AppFlavor.development;

  bool get _canUseFirestore {
    if (_injectedFirestore != null) return true;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String? get _currentAuthUid {
    try {
      if (Firebase.apps.isEmpty) return null;
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      return (uid != null && uid.trim().isNotEmpty) ? uid.trim() : null;
    } catch (_) {
      return null;
    }
  }

  bool get _isFirestoreSessionActive =>
      _canUseFirestore &&
      (_injectedFirestore != null || _currentAuthUid != null);

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  List<ChatMessageModel> _mergeSessionMessages(
    String conversationId,
    List<ChatMessageModel> remoteMessages,
  ) {
    final sessionSent =
        _sessionSentByConversation[conversationId] ?? const <ChatMessageModel>[];
    if (remoteMessages.isEmpty && sessionSent.isEmpty) {
      return const <ChatMessageModel>[];
    }
    final byId = <String, ChatMessageModel>{};
    for (final m in sessionSent) {
      if (m.id.isNotEmpty) {
        byId[m.id] = m;
      }
    }
    for (final m in remoteMessages) {
      if (m.id.isNotEmpty) {
        byId[m.id] = m;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return List<ChatMessageModel>.unmodifiable(merged);
  }

  StreamController<List<ChatMessageModel>> _ensureLiveController(String cleanId) {
    final existing = _liveStreamControllers[cleanId];
    if (existing != null && !existing.isClosed) {
      return existing;
    }
    late final StreamController<List<ChatMessageModel>> controller;
    controller = StreamController<List<ChatMessageModel>>.broadcast(
      onCancel: () {
        if (!controller.hasListener) {
          _liveStreamControllers.remove(cleanId);
          unawaited(controller.close());
        }
      },
    );
    _liveStreamControllers[cleanId] = controller;
    return controller;
  }

  Stream<List<ChatMessageModel>> _streamSessionMessages(String cleanId) {
    final controller = _ensureLiveController(cleanId);
    return Stream<List<ChatMessageModel>>.multi((subscriber) {
      final initial = List<ChatMessageModel>.unmodifiable(
        _sessionSentByConversation[cleanId] ?? const <ChatMessageModel>[],
      );
      subscriber.add(initial);
      final sub = controller.stream.listen(
        subscriber.add,
        onError: subscriber.addError,
        onDone: subscriber.close,
      );
      subscriber.onCancel = sub.cancel;
    });
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    String? peerName,
    String? routeContext,
  }) async {
    final cleanId =
        conversationId.trim().isEmpty ? 'chat_default' : conversationId.trim();

    if (!_isFirestoreSessionActive) {
      if (_isLiveBackendMode) {
        return List<ChatMessageModel>.unmodifiable(
          _sessionSentByConversation[cleanId] ?? const <ChatMessageModel>[],
        );
      }
      return _localFallback.getMessages(
        cleanId,
        peerName: peerName,
        routeContext: routeContext,
      );
    }

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.conversations)
          .doc(cleanId)
          .collection(FirestoreCollections.messages)
          .orderBy('timestamp', descending: false)
          .get()
          .timeout(const Duration(seconds: 4));

      final remoteMessages = snapshot.docs
          .map(
            (doc) => ChatMessageModel.fromJson(
              normalizeFirestoreDocument(doc.data(), fallbackId: doc.id),
            ),
          )
          .toList();

      return _mergeSessionMessages(cleanId, remoteMessages);
    } catch (_) {
      return List<ChatMessageModel>.unmodifiable(
        _sessionSentByConversation[cleanId] ?? const <ChatMessageModel>[],
      );
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? attachmentUrl,
    String? recipientId,
  }) async {
    final cleanId =
        conversationId.trim().isEmpty ? 'chat_default' : conversationId.trim();
    final authUid = _currentAuthUid;
    final effectiveSenderId = (authUid != null && authUid.isNotEmpty)
        ? authUid
        : (senderId.trim().isEmpty ? 'usr_me_local' : senderId.trim());
    final effectiveSenderName =
        senderName.trim().length >= 2 ? senderName.trim() : 'مستخدم مشوار';

    if (!_isFirestoreSessionActive && !_isLiveBackendMode) {
      return _localFallback.sendMessage(
        conversationId: cleanId,
        senderId: effectiveSenderId,
        senderName: effectiveSenderName,
        text: text,
        attachmentUrl: attachmentUrl,
        recipientId: recipientId,
      );
    }

    final localMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${++_liveMsgSeq}',
      conversationId: cleanId,
      senderId: effectiveSenderId,
      senderName: effectiveSenderName,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: true,
      attachmentUrl:
          (attachmentUrl != null && attachmentUrl.trim().isNotEmpty)
              ? attachmentUrl.trim()
              : null,
    );

    final sessionList = _sessionSentByConversation.putIfAbsent(
      cleanId,
      () => <ChatMessageModel>[],
    );
    sessionList.add(localMessage);

    final controller = _liveStreamControllers[cleanId];
    if (controller != null && !controller.isClosed) {
      controller.add(List<ChatMessageModel>.unmodifiable(sessionList));
    }

    if (!_isFirestoreSessionActive) {
      return localMessage;
    }

    try {
      final convRef =
          _firestore.collection(FirestoreCollections.conversations).doc(cleanId);
      final msgRef =
          convRef.collection(FirestoreCollections.messages).doc(localMessage.id);

      final truncatedPreview =
          text.trim().length > 500 ? text.trim().substring(0, 500) : text.trim();

      bool conversationExists = _existingConversationIds.contains(cleanId);
      if (!conversationExists) {
        try {
          final snap = await convRef.get().timeout(const Duration(seconds: 4));
          conversationExists = snap.exists;
          if (conversationExists) {
            _existingConversationIds.add(cleanId);
          }
        } catch (_) {
          // If read fails (e.g., conversation not created yet), attempt initial create below.
        }
      }

      if (conversationExists) {
        // Never touch immutable `id`, `participantIds`, or `createdAt` on message #2+.
        await convRef
            .update({
              'lastMessage': truncatedPreview,
              'lastMessageTimestamp': FieldValue.serverTimestamp(),
              'lastSenderId': effectiveSenderId,
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 4));
      } else {
        final cleanRecipient = recipientId?.trim();
        final resolvedPeerId =
            (cleanRecipient != null &&
                    cleanRecipient.isNotEmpty &&
                    cleanRecipient != effectiveSenderId)
                ? cleanRecipient
                : 'peer_$cleanId';
        await convRef
            .set({
              'id': cleanId,
              'participantIds': <String>[effectiveSenderId, resolvedPeerId],
              'lastMessage': truncatedPreview,
              'lastMessageTimestamp': FieldValue.serverTimestamp(),
              'lastSenderId': effectiveSenderId,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 4));
        _existingConversationIds.add(cleanId);
      }

      final payload = <String, dynamic>{
        'id': localMessage.id,
        'conversationId': cleanId,
        'senderId': effectiveSenderId,
        'senderName': effectiveSenderName,
        'text': localMessage.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        if (localMessage.attachmentUrl != null)
          'attachmentUrl': localMessage.attachmentUrl,
      };

      await msgRef.set(payload).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Keep session message intact if network or rules reject Firestore write.
    }

    return localMessage;
  }

  @override
  Stream<List<ChatMessageModel>> streamMessages(String conversationId) {
    final cleanId =
        conversationId.trim().isEmpty ? 'chat_default' : conversationId.trim();

    if (!_isFirestoreSessionActive) {
      if (_isLiveBackendMode) {
        return _streamSessionMessages(cleanId);
      }
      return _localFallback.streamMessages(cleanId);
    }

    return Stream<List<ChatMessageModel>>.multi((subscriber) {
      StreamSubscription<List<ChatMessageModel>>? sessionSub;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? firestoreSub;

      void switchToSessionFallback() {
        if (sessionSub != null) return;
        sessionSub = _streamSessionMessages(cleanId).listen(
          subscriber.add,
          onError: subscriber.addError,
        );
      }

      try {
        firestoreSub = _firestore
            .collection(FirestoreCollections.conversations)
            .doc(cleanId)
            .collection(FirestoreCollections.messages)
            .orderBy('timestamp', descending: false)
            .snapshots()
            .listen(
          (snapshot) {
            final remote = snapshot.docs
                .map(
                  (doc) => ChatMessageModel.fromJson(
                    normalizeFirestoreDocument(doc.data(), fallbackId: doc.id),
                  ),
                )
                .toList();
            final merged = _mergeSessionMessages(cleanId, remote);
            if (!subscriber.isClosed) {
              subscriber.add(merged);
            }
          },
          onError: (_) {
            switchToSessionFallback();
          },
        );
      } catch (_) {
        switchToSessionFallback();
      }

      subscriber.onCancel = () async {
        await firestoreSub?.cancel();
        await sessionSub?.cancel();
      };
    });
  }
}
