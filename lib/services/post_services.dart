import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class PostService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  // Define a common User-Agent string to reuse
  static const Map<String, String> _commonHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36', // Updated User-Agent
    'Accept': 'application/json', // Indicate that we prefer JSON responses
  };

  // READ: Get posts
  Future<List<Post>> fetchPosts({int page = 1, int limit = 10}) async {
    final uri = Uri.parse('$baseUrl?_page=$page&_limit=$limit');
    print('Fetching posts from: $uri');
    final response = await http.get(
      uri,
      headers: _commonHeaders,
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((postJson) => Post.fromJson(postJson)).toList();
    } else {
      print('Failed to load posts. Status Code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  // CREATE: Add a new post
  Future<Post> createPost(Post post) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        ..._commonHeaders,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(post.toJson()),
    );

    if (response.statusCode == 201) {
      print("yes");
      return Post.fromJson(json.decode(response.body));
    } else {
      print("no");
      print('Failed to create post. Status Code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to create post: ${response.statusCode}');
    }
  }

  // Update an existing post
  Future<Post> updatePost(Post post) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${post.id}'),
      headers: {
        ..._commonHeaders,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(post.toJson()),
    );

    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else {
      print('Failed to update post. Status Code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to update post: ${response.statusCode}');
    }
  }

  // Delete a post
  Future<void> deletePost(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _commonHeaders,
    );

    if (response.statusCode == 200) {
      print('Post $id deleted successfully.');
    } else {
      print('Failed to delete post. Status Code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to delete post: ${response.statusCode}');
    }
  }
}
