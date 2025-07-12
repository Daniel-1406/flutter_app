import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  int _currentPage = 1;
  final int _postsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  late ScrollController _scrollController;
  final PostService _postService = PostService();

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchInitialPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  void _fetchInitialPosts() {
    setState(() {
      _isLoadingMore = true;
      _allPosts = [];
      _filteredPosts = [];
      _currentPage = 1;
      _hasMoreData = true;
    });
    _postService.fetchPosts(
      page: 1,
      limit: _postsPerPage,
    ).then((posts) {
      if (!mounted) return;
      setState(() {
        _allPosts = posts;
        _isLoadingMore = false;
        _hasMoreData = posts.length == _postsPerPage;
        _applySearchFilter();
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load initial posts: $error')),
      );
      print('Error fetching initial posts: $error');
    });
  }

  //
  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore || !_hasMoreData) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newPosts = await _postService.fetchPosts(
        page: _currentPage + 1,
        limit: _postsPerPage,
      );

      if (!mounted) return;
      setState(() {
        _allPosts.addAll(newPosts);
        _currentPage++;
        _isLoadingMore = false;
        _hasMoreData = newPosts.length == _postsPerPage;
        _applySearchFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more posts: $e')),
      );
      print('Error fetching more posts: $e');
    }
  }

  void _applySearchFilter() {
    if (_currentSearchQuery.isEmpty) {
      _filteredPosts = List.from(_allPosts);
    } else {
      final queryLower = _currentSearchQuery.toLowerCase();
      _filteredPosts = _allPosts.where((post) {
        return post.title.toLowerCase().contains(queryLower) ||
            post.body.toLowerCase().contains(queryLower);
      }).toList();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _fetchMorePosts();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentSearchQuery = query;
      _applySearchFilter();
    });
  }

  // Method to clear the search
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _currentSearchQuery = '';
      _filteredPosts = List.from(_allPosts);
    });
  }

  Future<void> _showPostFormDialog({Post? post}) async {
    final TextEditingController titleController =
    TextEditingController(text: post?.title ?? '');
    final TextEditingController bodyController =
    TextEditingController(text: post?.body ?? '');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 10.0),
          title: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).colorScheme.primary, // Use theme primary color
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  post == null ? Icons.add_circle_outline : Icons.edit_note,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  post == null ? 'Add New Post' : 'Edit Post',
                  style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const SizedBox(height: 20), // Spacing after header
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter post title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded input field
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 15), // Add spacing
                TextFormField(
                  controller: bodyController,
                  decoration: InputDecoration(
                    labelText: 'Body',
                    hintText: 'Enter post body content',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded input field
                    ),
                    prefixIcon: const Icon(Icons.text_fields),
                  ),
                  maxLines: 4, // Allow more lines for body input
                  minLines: 2, // Minimum lines for body input
                ),
              ],
            ),
          ),
          actionsPadding:  EdgeInsets.all(16.0), // Padding for action buttons
          actions:[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.onSurface, // Text color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Use dialogContext
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.primary, // Button background color
                foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary, // Button text color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 3, // Subtle shadow for button
              ),
              child: Text(post == null ? 'Add Post' : 'Update Post'), // More descriptive text
              onPressed: () async {
                final String title = titleController.text;
                final String body = bodyController.text;

                if (title.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar( // Use dialogContext
                    const SnackBar(content: Text('Title and Body cannot be empty')),
                  );
                  return;
                }

                bool success = false; // Flag to track success
                String message = '';

                if (post == null) {
                  // Create new post
                  final newPost = Post(userId: 1, title: title, body: body);
                  try {
                    await _postService.createPost(newPost);
                    message = 'Post added successfully!';
                    success = true;
                  } catch (e) {
                    message = 'Failed to add post: $e';
                    success = false;
                  }
                } else {
                  // Update existing post
                  final updatedPost = Post(
                      id: post.id,
                      userId: post.userId,
                      title: title,
                      body: body);
                  try {
                    await _postService.updatePost(updatedPost);
                    message = 'Post updated successfully!';
                    success = true;
                  } catch (e) {
                    message = 'Failed to update post: $e';
                    success = false;
                  }
                }


                if (!context.mounted) { // Use context.mounted directly
                  Navigator.of(dialogContext).pop(); // Still pop the dialog
                  return; // If HomePage is unmounted, stop here.
                }

                ScaffoldMessenger.of(context).showSnackBar( // Use widget's context for HomePage Scaffold
                  SnackBar(content: Text(message)),
                );

                Navigator.of(dialogContext).pop(); // Use dialogContext

                if (success) {
                  if (!mounted) return;
                  _fetchInitialPosts(); // Refetch all data (no search query needed here)
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _deletePost(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use dialogContext here too
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Pop with false if cancelled
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _postService.deletePost(id);
        if (!context.mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully!')),
        );
        if (!mounted) return false;
        _fetchInitialPosts();
        return true;
      } catch (e) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar( // Use widget's context for HomePage Scaffold
          SnackBar(content: Text('Failed to delete post: $e')),
        );
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary, // Start color (e.g., blue)
                Theme.of(context).colorScheme.tertiary, // End color (e.g., a lighter blue or purple)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search posts...',
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearSearch,
            )
                : null,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: _onSearchChanged,
          onSubmitted: (value) => _onSearchChanged(value), // Also trigger on submission
        )
            : Text(
          'Posts CRUD App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.check : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _clearSearch();
                }
              });
            },
          ),
        ],
      ),
      body: _filteredPosts.isEmpty && _isLoadingMore && _hasMoreData ?
      const Center(child: CircularProgressIndicator()) :
      RefreshIndicator(
        onRefresh: () async {
          _fetchInitialPosts(); // Refresh always fetches from page 1
        },
        child: _filteredPosts.isEmpty && !_isLoadingMore && !_hasMoreData && _currentSearchQuery.isEmpty ?
        const Center(child: Text('No posts found. Pull down to refresh or add a new post.')) :
        _filteredPosts.isEmpty && !_isLoadingMore && _currentSearchQuery.isNotEmpty ?
        const Center(child: Text('No posts found matching your search.')) : // Message for no search results
        ListView.builder(
          controller: _scrollController,
          itemCount: _filteredPosts.length + (_hasMoreData && _currentSearchQuery.isEmpty ? 1 : 0), // Only show loading more if not searching
          itemBuilder: (context, index) {
            if (index == _filteredPosts.length) {
              // This is the last item, show a loading indicator if more data is expected
              // Only show if not actively searching (as search is local)
              if (_hasMoreData && _currentSearchQuery.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else {
                return const SizedBox.shrink(); // Hide if no more data or if searching
              }
            }

            final post = _filteredPosts[index]; // Use filtered posts
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Dismissible(
                key: ValueKey(post.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.delete_forever, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await _deletePost(post.id!);
                },
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 24),
                            onPressed: () => _showPostFormDialog(post: post),
                            tooltip: 'Edit Post',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostFormDialog(),
        tooltip: 'Add Post',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
