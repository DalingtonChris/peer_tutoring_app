import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'find_tutor_screen.dart';
import 'profile_screen.dart';
import 'request_help_screen.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final Map<String, dynamic> userData;

  const DashboardScreen({
    super.key,
    required this.userRole,
    required this.userData,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late List<NavigationDestination> _navDestinations;

  @override
  void initState() {
    super.initState();
    _buildScreens();
  }

  void _buildScreens() {
    if (widget.userRole == 'tutor') {
      _screens = [
        TutorHomeTab(currentUserData: widget.userData),
        TutorMessagesTab(tutorId: widget.userData['id']),
        ProfileScreen(
          userData: widget.userData,
          userRole: widget.userRole,
        ),
      ];
      _navDestinations = const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Tutor Desk',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      _screens = [
        LearnerHomeTab(currentUserData: widget.userData),
        FindTutorScreen(currentUserId: widget.userData['id']),
        ProfileScreen(
          userData: widget.userData,
          userRole: widget.userRole,
        ),
      ];
      _navDestinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          selectedIcon: Icon(Icons.search_sharp),
          label: 'Find Tutors',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        destinations: _navDestinations,
      ),
    );
  }
}

// ==========================================
// 1. LEARNER HOME TAB  (unchanged)
// ==========================================
class LearnerHomeTab extends StatefulWidget {
  final Map<String, dynamic> currentUserData;
  const LearnerHomeTab({super.key, required this.currentUserData});

  @override
  State<LearnerHomeTab> createState() => _LearnerHomeTabState();
}

class _LearnerHomeTabState extends State<LearnerHomeTab> {
  static const String _baseUrl = AppConfig.baseUrl;

  List<dynamic> _requests = [];
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final studentId = widget.currentUserData['id'];
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/student/requests/$studentId'))
            .timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$_baseUrl/api/student/conversations/$studentId'))
            .timeout(const Duration(seconds: 10)),
      ]);

      setState(() {
        _requests = results[0].statusCode == 200
            ? jsonDecode(results[0].body)
            : [];
        _conversations = results[1].statusCode == 200
            ? jsonDecode(results[1].body)
            : [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ LearnerHomeTab load error: $e');
      setState(() => _loading = false);
    }
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.currentUserData['name'] ?? 'Learner';
    final int studentId = widget.currentUserData['id'] is int
        ? widget.currentUserData['id']
        : int.tryParse(widget.currentUserData['id'].toString()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerConnect',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestHelpScreen(studentId: studentId),
            ),
          );
          _loadData();
        },
        icon: const Icon(Icons.add_task),
        label: const Text("Request Help"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back, $displayName! 👋",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text("What are we mastering today?",
                        style: TextStyle(color: Colors.grey)),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        const Icon(Icons.help_outline,
                            size: 20, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          'My Requests',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_requests.isEmpty)
                      _emptyBox("You haven't sent any requests yet.")
                    else
                      ..._requests.map((req) {
                        final bool hasReply = req['reply_text'] != null &&
                            (req['reply_text'] as String).isNotEmpty;
                        final bool isAnswered = req['status'] == 'answered';

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: hasReply
                                  ? Colors.green.withOpacity(0.35)
                                  : Colors.grey.withOpacity(0.18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor:
                                          Colors.deepPurple.withOpacity(0.1),
                                      child: const Icon(Icons.menu_book,
                                          color: Colors.deepPurple, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        req['course_name'] ?? 'General',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isAnswered
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isAnswered ? 'Answered' : 'Pending',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isAnswered
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  req['issue_description'] ?? 'No description',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                ),

                                const SizedBox(height: 10),

                                if (hasReply) ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.reply,
                                            size: 14, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (req['tutor_name'] != null)
                                                Text(
                                                  req['tutor_name'],
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green),
                                                ),
                                              const SizedBox(height: 2),
                                              Text(
                                                req['reply_text'],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              Colors.orange.withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Awaiting tutor reply…',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 20, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          'My Tutors',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_conversations.isEmpty)
                      _emptyBox(
                          "You haven't messaged any tutor yet.\nGo to Find Tutors to get started.")
                    else
                      ..._conversations.map((conv) {
                        final tutorName = conv['tutor_name'] ?? 'Tutor';
                        final lastMsg =
                            conv['last_message'] ?? 'No messages yet';
                        final tutorId = conv['tutor_id'] is int
                            ? conv['tutor_id']
                            : int.tryParse(conv['tutor_id'].toString()) ?? 0;

                        final colors = [
                          const Color(0xFF7B2FBE),
                          const Color(0xFF2196F3),
                          const Color(0xFF00897B),
                          const Color(0xFFE91E63),
                        ];
                        final color =
                            colors[tutorName.codeUnitAt(0) % colors.length];

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.grey.withOpacity(0.18)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: color.withOpacity(0.15),
                              child: Text(
                                tutorName[0].toUpperCase(),
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            title: Text(tutorName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            subtitle: Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            trailing: Text(
                              _formatTime(conv['last_time']?.toString()),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    currentUserId: studentId,
                                    receiverId: tutorId,
                                    receiverName: tutorName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}

// ==========================================
// 2. TUTOR HOME TAB  (updated — shows student requests with reply)
// ==========================================
class TutorHomeTab extends StatefulWidget {
  final Map<String, dynamic> currentUserData;
  const TutorHomeTab({super.key, required this.currentUserData});

  @override
  State<TutorHomeTab> createState() => _TutorHomeTabState();
}

class _TutorHomeTabState extends State<TutorHomeTab> {
  static const String _baseUrl = AppConfig.baseUrl;

  int _ratingScore = 0;
  int _answeredRequests = 0;
  bool _statsLoading = true;

  List<dynamic> _activeStudents = [];
  bool _studentsLoading = true;

  List<dynamic> _requests = [];
  bool _requestsLoading = true;

  // tracks which request card is expanded for reply input
  int? _expandedRequestId;
  final Map<int, TextEditingController> _replyControllers = {};
  final Map<int, bool> _sendingReply = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadActiveStudents();
    _loadRequests();
  }

  @override
  void dispose() {
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load tutor stats ────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final tutorId = widget.currentUserData['id'];
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tutor/stats/$tutorId'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ratingScore       = (data['rating_score']      as num).toInt();
          _answeredRequests  = (data['answered_requests'] as num).toInt();
          _statsLoading      = false;
        });
      } else {
        setState(() => _statsLoading = false);
      }
    } catch (_) {
      setState(() => _statsLoading = false);
    }
  }

  // ── Load active students list ───────────────────────────────────────────────
  Future<void> _loadActiveStudents() async {
    setState(() => _studentsLoading = true);
    try {
      final tutorId = widget.currentUserData['id'];
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tutor/active-students/$tutorId'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() {
          _activeStudents = jsonDecode(response.body);
          _studentsLoading = false;
        });
      } else {
        setState(() => _studentsLoading = false);
      }
    } catch (_) {
      setState(() => _studentsLoading = false);
    }
  }

  // ── Load all student requests ───────────────────────────────────────────────
  Future<void> _loadRequests() async {
    setState(() => _requestsLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/requests'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          _requests = jsonDecode(response.body);
          _requestsLoading = false;
        });
      } else {
        setState(() => _requestsLoading = false);
      }
    } catch (e) {
      debugPrint('❌ TutorHomeTab load requests error: $e');
      setState(() => _requestsLoading = false);
    }
  }

  // ── Send reply ──────────────────────────────────────────────────────────────
  Future<void> _sendReply(int requestId) async {
    final controller = _replyControllers[requestId];
    final replyText = controller?.text.trim() ?? '';
    if (replyText.isEmpty) return;

    setState(() => _sendingReply[requestId] = true);

    try {
      final tutorId = widget.currentUserData['id'];
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tutor/reply/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tutor_id': tutorId, 'reply_text': replyText}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          controller?.clear();
          setState(() {
            _expandedRequestId = null;
            _sendingReply[requestId] = false;
          });
          // Refresh requests + stats (new +2 credits were just awarded)
          await Future.wait([_loadRequests(), _loadStats(), _loadActiveStudents()]);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Reply sent! The student has been notified.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          _showReplyError(requestId, result['message'] ?? 'Failed to send');
        }
      } else {
        _showReplyError(requestId, 'Server error ${response.statusCode}');
      }
    } catch (e) {
      _showReplyError(requestId, 'Could not connect to server');
    }
  }

  void _showReplyError(int requestId, String msg) {
    setState(() => _sendingReply[requestId] = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $msg'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  TextEditingController _controllerFor(int requestId) {
    return _replyControllers.putIfAbsent(
        requestId, () => TextEditingController());
  }

  // ── Build a single request card ─────────────────────────────────────────────
  Widget _buildRequestCard(Map<String, dynamic> req) {
    final int requestId = req['id'] is int
        ? req['id']
        : int.tryParse(req['id'].toString()) ?? 0;

    final String studentName  = req['student_name']      ?? 'Student';
    final String courseName   = req['course_name']        ?? 'General';
    final String issueText    = req['issue_description']  ?? 'No description';
    final bool   isAnswered   = req['status'] == 'answered';
    final String? existingReply = req['reply_text'] as String?;
    final bool hasReply = existingReply != null && existingReply.isNotEmpty;

    final bool isExpanded = _expandedRequestId == requestId;
    final bool isSending  = _sendingReply[requestId] ?? false;

    // avatar colour based on student name
    const avatarColors = [
      Color(0xFF7B2FBE),
      Color(0xFF2196F3),
      Color(0xFF00897B),
      Color(0xFFE91E63),
      Color(0xFFFF6F00),
    ];
    final avatarColor =
        avatarColors[studentName.codeUnitAt(0) % avatarColors.length];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasReply
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor.withOpacity(0.13),
                  child: Text(
                    studentName[0].toUpperCase(),
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        courseName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.deepPurple.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAnswered
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAnswered ? 'Answered' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAnswered
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Issue text ────────────────────────────────────────────────
            Text(
              issueText,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),

            // ── Existing reply preview ────────────────────────────────────
            if (hasReply) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.reply, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        existingReply,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Reply button / expanded reply box ─────────────────────────
            if (!isExpanded)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _expandedRequestId = requestId);
                  },
                  icon: Icon(
                    hasReply ? Icons.edit_outlined : Icons.reply_outlined,
                    size: 16,
                  ),
                  label: Text(
                    hasReply ? 'Edit Reply' : 'Reply',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3)),
                    ),
                  ),
                ),
              )
            else ...[
              // Reply input area
              TextField(
                controller: _controllerFor(requestId),
                maxLines: 3,
                minLines: 2,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Write your reply here…',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.25)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        setState(() => _expandedRequestId = null),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isSending ? null : () => _sendReply(requestId),
                    icon: isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 15),
                    label: Text(isSending ? 'Sending…' : 'Send Reply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.currentUserData['name'] ?? 'Tutor';

    // Split requests into pending vs answered for better UX
    final pendingRequests =
        _requests.where((r) => r['status'] != 'answered').toList();
    final answeredRequests =
        _requests.where((r) => r['status'] == 'answered').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tutor Command Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Chip(
              avatar: const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
              label: Text(
                _statsLoading ? '… pts' : '$_ratingScore pts total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.orange.withOpacity(0.1),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadStats(), _loadActiveStudents(), _loadRequests()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ─────────────────────────────────────────────────
              Text(
                "Welcome, $displayName",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // ── Stats Row ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      "Rating Score",
                      _statsLoading ? "…" : "$_ratingScore pts",
                      Icons.star_rounded,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      "Active Students",
                      _studentsLoading ? "…" : "${_activeStudents.length}",
                      Icons.people_outline,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    '+5 new student · +2 answered request',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Active Students List ──────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.people, size: 20, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Active Students',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_studentsLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_activeStudents.isEmpty)
                _emptyBox('No active students yet.\nStudents will appear here once they message you.')
              else
                ...(_activeStudents.map((s) {
                  final name    = s['student_name'] ?? 'Student';
                  final course  = s['course'] ?? '';
                  final credits = s['credits_given'] ?? 0;
                  const avatarColors = [
                    Color(0xFF7B2FBE), Color(0xFF2196F3),
                    Color(0xFF00897B), Color(0xFFE91E63), Color(0xFFFF6F00),
                  ];
                  final color = avatarColors[name.codeUnitAt(0) % avatarColors.length];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: course.isNotEmpty
                          ? Text(course,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey))
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+$credits pts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                })),

              const SizedBox(height: 28),

              // ── Pending Requests ──────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.pending_actions,
                      size: 20, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Requests',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (!_requestsLoading && pendingRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingRequests.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        size: 20, color: Colors.deepPurple),
                    tooltip: 'Refresh',
                    onPressed: _loadRequests,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_requestsLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (pendingRequests.isEmpty)
                _emptyBox(
                    "No pending requests right now.\nCheck back soon! 🎉")
              else
                ...pendingRequests.map((req) =>
                    _buildRequestCard(Map<String, dynamic>.from(req))),

              // ── Answered Requests ─────────────────────────────────────────
              if (!_requestsLoading && answeredRequests.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Answered Requests',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${answeredRequests.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...answeredRequests.map((req) =>
                    _buildRequestCard(Map<String, dynamic>.from(req))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}

// ==========================================
// 3. TUTOR MESSAGES TAB  (unchanged)
// ==========================================
class TutorMessagesTab extends StatefulWidget {
  final dynamic tutorId;
  const TutorMessagesTab({super.key, required this.tutorId});

  @override
  State<TutorMessagesTab> createState() => _TutorMessagesTabState();
}

class _TutorMessagesTabState extends State<TutorMessagesTab> {
  static const String _baseUrl = AppConfig.baseUrl;
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/conversations/${widget.tutorId}'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        setState(() {
          _conversations = jsonDecode(response.body);
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
        _error = 'Could not connect to server.';
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

  String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day &&
          dt.month == now.month &&
          dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7B2FBE)),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B2FBE)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadConversations,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B2FBE)),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8A8A9A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Students will appear here\nwhen they message you',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFAAAAAA), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7B2FBE),
                      onRefresh: _loadConversations,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 76, endIndent: 16),
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final studentName =
                              conv['student_name'] ?? 'Student';
                          final lastMessage =
                              conv['last_message'] ?? 'No messages yet';
                          final lastTime = conv['last_time'];
                          final studentId = conv['student_id'];
                          final color = _avatarColor(studentName);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: color.withOpacity(0.15),
                              child: Text(
                                studentName[0].toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8A8A9A),
                                fontSize: 13,
                              ),
                            ),
                            trailing: Text(
                              _formatTime(lastTime?.toString()),
                              style: const TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 11,
                              ),
                            ),
                            onTap: () {
                              final int tutorIdInt = widget.tutorId is int
                                  ? widget.tutorId
                                  : int.tryParse(
                                          widget.tutorId.toString()) ??
                                      0;
                              final int studentIdInt = studentId is int
                                  ? studentId
                                  : int.tryParse(
                                          studentId.toString()) ??
                                      0;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    currentUserId: tutorIdInt,
                                    receiverId: studentIdInt,
                                    receiverName: studentName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}