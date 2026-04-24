import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

class ForumService {
  final Client client = Client();
  late final Databases databases;

  static const String _endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String _projectId = '69a791fa002d1b9cbef8';
  static const String _dbId = 'crypto_db';
  static const String _topicsCollectionId = 'forum_topics';
  static const String _commentsCollectionId = 'forum_comments';

  ForumService() {
    client
        .setEndpoint(_endpoint)
        .setProject(_projectId); // .setSelfSigned(status: true) Appwrite Cloud ile kullanılmamalıdır, güvenlik açığı oluşturur ve bağlantı sorunlarına yol açabilir.
    databases = Databases(client);
  }

  // Konuları Listele
  Future<List<Document>> getTopics() async {
    try {
      final result = await databases.listDocuments(
        databaseId: _dbId,
        collectionId: _topicsCollectionId,
        queries: [
          Query.orderDesc('createdAt'),
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Get Topics Error: $e");
      return [];
    }
  }

  // Yeni Konu Oluştur
  Future<void> createTopic(String title, String content, String userId, String authorName) async {
    try {
      await databases.createDocument(
        databaseId: _dbId,
        collectionId: _topicsCollectionId,
        documentId: ID.unique(),
        data: {
          'title': title,
          'content': content,
          'userId': userId,
          'authorName': authorName,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint("Create Topic Error: $e");
      rethrow;
    }
  }

  // Yorumları Getir
  Future<List<Document>> getComments(String topicId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: _dbId,
        collectionId: _commentsCollectionId,
        queries: [
          Query.equal('topicId', topicId),
          Query.orderAsc('createdAt'),
        ],
      );
      return result.documents;
    } catch (e) {
      debugPrint("Get Comments Error: $e");
      return [];
    }
  }

  // Yorum Yap
  Future<void> createComment(String topicId, String content, String userId, String authorName) async {
    try {
      await databases.createDocument(
        databaseId: _dbId,
        collectionId: _commentsCollectionId,
        documentId: ID.unique(),
        data: {
          'topicId': topicId,
          'content': content,
          'userId': userId,
          'authorName': authorName,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint("Create Comment Error: $e");
      rethrow;
    }
  }
}