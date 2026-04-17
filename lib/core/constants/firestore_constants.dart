/// Firestore collection name constants
class FirestoreConstants {
  FirestoreConstants._();

  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String statusCollection = 'status';
  static const String callsCollection = 'calls';
  static const String pollsCollection = 'polls';
  static const String scheduledMessagesCollection = 'scheduled_messages';

  // Sub-collections
  static const String typingSubCollection = 'typing';
}
