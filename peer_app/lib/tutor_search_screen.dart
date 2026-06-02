import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
//  TutorSetupScreen
//  Shown ONCE after a tutor logs in (or from Profile → Edit)
//  Tutor picks their courses + writes a short bio → saved to MySQL
// ─────────────────────────────────────────────────────────────────────────────
class TutorSetupScreen extends StatefulWidget {
  final int tutorId;
  final VoidCallback onComplete; // called after save → navigate to dashboard

  const TutorSetupScreen({
    super.key,
    required this.tutorId,
    required this.onComplete,
  });

  @override
  State<TutorSetupScreen> createState() => _TutorSetupScreenState();
}

class _TutorSetupScreenState extends State<TutorSetupScreen> {
  final String _baseUrl = 'http://192.168.1.145:3000';
  final _bioController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;

  // All available courses in your university — extend this list freely
  final List<String> _allCourses = [
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
    'Discrete Mathematics',
    'English',
    'French',
    'Economics',
    'Accounting',
    'Management',
  ];

  final Set<String> _selectedCourses = {};

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  // Pre-fill if tutor already has a profile saved
  Future<void> _loadExistingProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tutor/profile/${widget.tutorId}'))
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
    } catch (_) {
      // If server is unreachable just show empty form
    }
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
        Uri.parse('$_baseUrl/api/tutor/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tutor_id': widget.tutorId,
          'bio': _bioController.text.trim(),
          'courses': _selectedCourses.toList(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _bioController.dispose();
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
          'Set Up Your Tutor Profile',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FBE)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
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
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.school, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
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
                                'Select courses you can help with\nand write a short bio.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Bio ──────────────────────────────────────────
                  const Text(
                    'About You',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. "3rd year CS student. I am strong in Algorithms and can explain step by step."',
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

                  // ── Course picker ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Courses I Can Help With',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${_selectedCourses.length} selected',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7B2FBE),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to select all subjects you are confident teaching',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A8A9A)),
                  ),
                  const SizedBox(height: 12),

                  // Wrap of selectable chips
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7B2FBE)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7B2FBE)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            course,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 36),

                  // ── Save button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2FBE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save & Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip link (tutor can fill later)
                  Center(
                    child: TextButton(
                      onPressed: widget.onComplete,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Color(0xFF8A8A9A),
                          fontSize: 13,
                        ),
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