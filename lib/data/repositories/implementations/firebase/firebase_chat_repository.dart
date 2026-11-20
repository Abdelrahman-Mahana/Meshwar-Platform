import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/chat_message_model.dart';
import '../../contracts/i_chat_repository.dart';
import '../../../services/firebase_firestore_service.dart';

class FirebaseChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore;

  FirebaseChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.conversations)
        .doc(conversationId)
        .collection(FirestoreCollections.messages)
        .orderBy('timestamp', descending: false)
        .get();

    return snapshot.docs.map((doc) => ChatMessageModel.fromJson(doc.data())).toList();
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final msgRef = _firestore
        .collection(FirestoreCollections.conversations)
        .doc(conversationId)
        .collection(FirestoreCollections.messages)
        .doc();

    final message = ChatMessageModel(
      id: msgRef.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    await msgRef.set(message.toJson());
    await _firestore.collection(FirestoreCollections.conversations).doc(conversationId).set({
      'lastMessageText': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return message;
  }

  @override
  Stream<List<ChatMessageModel>> streamMessages(String conversationId) {
    return _firestore
        .collection(FirestoreCollections.conversations)
        .doc(conversationId)
        .collection(FirestoreCollections.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessageModel.fromJson(doc.data())).toList();
    });
  }
}
