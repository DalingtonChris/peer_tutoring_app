import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// TUTOR SETUP SCREEN  —  TabBar: "My Profile"  |  "My Subjects"
// ─────────────────────────────────────────────────────────────────────────────
class TutorSetupScreen extends StatefulWidget {
  final int tutorId;
  final VoidCallback onComplete;

  const TutorSetupScreen({
    super.key,
    required this.tutorId,
    required this.onComplete,
  });

  @override
  State<TutorSetupScreen> createState() => _TutorSetupScreenState();
}

class _TutorSetupScreenState extends State<TutorSetupScreen>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'http://192.168.1.145:3000';
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tutor Profile Setup',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7B2FBE),
          unselectedLabelColor: const Color(0xFF8A8A9A),
          indicatorColor: const Color(0xFF7B2FBE),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'My Profile'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'My Subjects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Bio + course chips (existing flow)
          _ProfileTab(
            tutorId: widget.tutorId,
            baseUrl: _baseUrl,
            onComplete: widget.onComplete,
          ),
          // Tab 2: Add subjects with descriptions (NEW)
          _SubjectsTab(
            tutorId: widget.tutorId,
            baseUrl: _baseUrl,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: MY PROFILE  (bio + course chips — your existing logic, unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  final int tutorId;
  final String baseUrl;
  final VoidCallback onComplete;

  const _ProfileTab({
    required this.tutorId,
    required this.baseUrl,
    required this.onComplete,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _bioController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;

  final List<String> _allCourses = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology',
    'Computer Science', 'Databases', 'Data Structures', 'Algorithms',
    'Networks', 'Cybersecurity', 'Web Development', 'Mobile Development',
    'Statistics', 'Linear Algebra', 'Discrete Mathematics', 'English',
    'French', 'Economics', 'Accounting', 'Management',
  ];

  final Set<String> _selectedCourses = {};

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final response = await http
          .get(Uri.parse('${widget.baseUrl}/api/tutor/profile/${widget.tutorId}'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == true) {
          _bioController.text = data['bio'] ?? '';
          final List<dynamic> courses = data['courses'] ?? [];
          setState(() {
            _selectedCourses.addAll(courses.map((c) => c.toString()));
          });
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one course')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/tutor/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tutor_id': widget.tutorId,
          'bio': _bioController.text.trim(),
          'courses': _selectedCourses.toList(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved! Now add your subjects in the next tab.'),
            backgroundColor: Color(0xFF7B2FBE),
          ),
        );
        widget.onComplete();
      } else {
        _showError(data['message'] ?? 'Could not save profile');
      }
    } catch (e) {
      _showError('Connection error. Check your server.');
    }
    setState(() => _isSaving = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FBE)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF9B59D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.school, color: Colors.white, size: 30),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tell students who you are',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Write a bio and pick your subjects.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Bio
          const Text(
            'About You',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'e.g. "3rd year CS student. Strong in Algorithms."',
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7B2FBE)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Course picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Courses I Can Help With',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              Text(
                '${_selectedCourses.length} selected',
                style: const TextStyle(fontSize: 13, color: Color(0xFF7B2FBE), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to select all subjects you are confident teaching',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A8A9A)),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCourses.map((course) {
              final isSelected = _selectedCourses.contains(course);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCourses.remove(course);
                    } else {
                      _selectedCourses.add(course);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7B2FBE) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF7B2FBE) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    course,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FBE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: widget.onComplete,
              child: const Text('Skip for now', style: TextStyle(color: Color(0xFF8A8A9A), fontSize: 13)),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: MY SUBJECTS  —  Tutor adds subject + description. Students see these.
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectsTab extends StatefulWidget {
  final int tutorId;
  final String baseUrl;

  const _SubjectsTab({required this.tutorId, required this.baseUrl});

  @override
  State<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<_SubjectsTab> {
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  List<dynamic> _subjects = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('${widget.baseUrl}/api/tutor/subjects/${widget.tutorId}'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        setState(() {
          _subjects = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSubject() async {
    final subject = _subjectController.text.trim();
    final description = _descController.text.trim();

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/tutor/subjects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tutor_id': widget.tutorId,
          'subject': subject,
          'description': description,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _subjectController.clear();
        _descController.clear();
        FocusScope.of(context).unfocus();
        await _fetchSubjects();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject added! Students can now see it.'),
            backgroundColor: Color(0xFF7B2FBE),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to save')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error')),
      );
    }

    setState(() => _isSaving = false);
  }

  Future<void> _deleteSubject(int id) async {
    try {
      await http
          .delete(Uri.parse('${widget.baseUrl}/api/tutor/subjects/$id'))
          .timeout(const Duration(seconds: 5));
      await _fetchSubjects();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject removed')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete')),
      );
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info banner ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2FBE).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7B2FBE).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF7B2FBE), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Add each subject you teach with a description. Students will see these on your profile in the marketplace.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A3080), height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Add subject form ────────────────────────────────────────────
          const Text(
            'Add a Subject',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),

          // Subject name field
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject Name *',
              hintText: 'e.g. Data Structures, Calculus',
              prefixIcon: const Icon(Icons.subject, color: Color(0xFF7B2FBE)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7B2FBE)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Description field
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'What can you help with?',
              hintText: 'e.g. "I can explain trees, graphs, sorting algos and dynamic programming."',
              hintStyle: const TextStyle(fontSize: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7B2FBE)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _addSubject,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                _isSaving ? 'Saving...' : 'Add Subject',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FBE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Current subjects list ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Current Subjects',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FBE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_subjects.length} subjects',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B2FBE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FBE)))
          else if (_subjects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.menu_book_outlined, size: 40, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 10),
                  Text(
                    'No subjects added yet',
                    style: TextStyle(color: Color(0xFF8A8A9A), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add your first subject above so students can find you!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _subjects.map((s) {
                final int id = s['id'];
                final String subject = s['subject'] ?? '';
                final String description = s['description'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FBE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book, color: Color(0xFF7B2FBE), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: Color(0xFF666677),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Remove Subject'),
                              content: Text('Remove "$subject" from your profile?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) _deleteSubject(id);
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Remove subject',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}