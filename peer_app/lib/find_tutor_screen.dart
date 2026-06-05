import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FIND TUTOR SCREEN  —  100% dynamic, no static data
// ─────────────────────────────────────────────────────────────────────────────
class FindTutorScreen extends StatefulWidget {
  // Pass the logged-in student's ID so we can open the chat correctly
  final int currentUserId;

  const FindTutorScreen({super.key, required this.currentUserId});

  @override
  State<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends State<FindTutorScreen> {
  static const String _baseUrl = AppConfig.baseUrl;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<dynamic> _tutors = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _staticCategories = [
    'All',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Databases',
    'Data Structures',
    'Algorithms',
    'Networks',
    'Cybersecurity',
    'Web Development',
    'Mobile Development',
    'Statistics',
    'Linear Algebra',
    'English',
    'French',
    'Economics',
    'Accounting',
    'Management',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTutors();
    _searchController.addListener(() {
      _fetchTutors(search: _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTutors({String search = '', String? category}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final cat = category ?? _selectedCategory;
    final queryParams = <String, String>{};
    if (search.trim().isNotEmpty) queryParams['search'] = search.trim();
    if (cat != 'All') queryParams['category'] = cat;

    final uri =
        Uri.parse('$_baseUrl/api/tutors').replace(queryParameters: queryParams);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        setState(() {
          _tutors = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Server error ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server. Is it running?';
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _fetchTutors(search: _searchController.text, category: category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find a Peer Tutor',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or subject...',
                hintStyle:
                    const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF7B2FBE)),
                filled: true,
                fillColor: const Color(0xFFF3EEF9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchTutors();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Category Chips ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              itemCount: _staticCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _staticCategories[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => _onCategorySelected(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7B2FBE)
                          : const Color(0xFFF3EEF9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF7B2FBE),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // ── Tutor List ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF7B2FBE)),
                  )
                : _error != null
                    ? _buildError()
                    : _tutors.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: const Color(0xFF7B2FBE),
                            onRefresh: () => _fetchTutors(
                              search: _searchController.text,
                              category: _selectedCategory,
                            ),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _tutors.length,
                              itemBuilder: (context, index) {
                                return _TutorCard(
                                  tutor: _tutors[index],
                                  baseUrl: _baseUrl,
                                  currentUserId: widget.currentUserId,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchTutors(),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FBE)),
            child:
                const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined,
              size: 56, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            'No tutors found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8A8A9A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different search or category',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TUTOR CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TutorCard extends StatelessWidget {
  final Map<String, dynamic> tutor;
  final String baseUrl;
  final int currentUserId;

  const _TutorCard({
    required this.tutor,
    required this.baseUrl,
    required this.currentUserId,
  });

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF7B2FBE),
      const Color(0xFF2196F3),
      const Color(0xFF00897B),
      const Color(0xFFE91E63),
      const Color(0xFFFF6F00),
      const Color(0xFF5C6BC0),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = tutor['name'] ?? 'Tutor';
    final bio = tutor['bio'] ?? '';
    final courses = tutor['courses'] as List<dynamic>? ?? [];
    final color = _avatarColor(name);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TutorDetailScreen(
              tutorId: tutor['user_id'],
              tutorName: name,
              baseUrl: baseUrl,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tutor['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8A9A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B2FBE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tutor',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7B2FBE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555566),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (courses.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: courses.take(4).map((course) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEF9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7B2FBE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (courses.isEmpty && bio.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Profile not set up yet',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                  ),
                ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TutorDetailScreen(
                          tutorId: tutor['user_id'],
                          tutorName: name,
                          baseUrl: baseUrl,
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward,
                      size: 16, color: Color(0xFF7B2FBE)),
                  label: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: Color(0xFF7B2FBE),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TUTOR DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class TutorDetailScreen extends StatefulWidget {
  final int tutorId;
  final String tutorName;
  final String baseUrl;
  final int currentUserId;

  const TutorDetailScreen({
    super.key,
    required this.tutorId,
    required this.tutorName,
    required this.baseUrl,
    required this.currentUserId,
  });

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http
          .get(Uri.parse(
              '${widget.baseUrl}/api/tutors/${widget.tutorId}/full'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error';
        _isLoading = false;
      });
    }
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF7B2FBE),
      const Color(0xFF2196F3),
      const Color(0xFF00897B),
      const Color(0xFFE91E63),
      const Color(0xFFFF6F00),
      const Color(0xFF5C6BC0),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  // ── Navigate to chat ──────────────────────────────────────────────────────
  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUserId: widget.currentUserId,
          receiverId: widget.tutorId,
          receiverName: widget.tutorName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.tutorName,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B2FBE)))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile header ───────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  _avatarColor(widget.tutorName)
                                      .withOpacity(0.15),
                              child: Text(
                                widget.tutorName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _avatarColor(widget.tutorName),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _profile!['name'] ?? widget.tutorName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile!['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A9A),
                              ),
                            ),
                            if ((_profile!['bio'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                _profile!['bio'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF555566),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Subjects ─────────────────────────────────────
                      const Text(
                        'Subjects This Tutor Teaches',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Builder(builder: (context) {
                        final subjects =
                            _profile!['subjects'] as List<dynamic>? ?? [];
                        if (subjects.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.15)),
                            ),
                            child: const Text(
                              'This tutor has not added any subjects yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFFAAAAAA), fontSize: 13),
                            ),
                          );
                        }
                        return Column(
                          children: subjects.map((s) {
                            final subject = s['subject'] ?? '';
                            final description = s['description'] ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.15)),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B2FBE)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book,
                                      color: Color(0xFF7B2FBE),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        if (description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            description,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF555566),
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }),

                      const SizedBox(height: 24),

                      // ── ✅ Message This Tutor button ──────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _openChat, // ← wired up!
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text(
                            'Message This Tutor',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B2FBE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}