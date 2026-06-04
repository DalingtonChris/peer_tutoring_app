import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'login_screen.dart';
import 'tutor_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  // ✅ Required parameters declared correctly
  final Map<String, dynamic> userData;
  final String userRole;

  const ProfileScreen({
    super.key,
    required this.userData,   // ✅
    required this.userRole,   // ✅
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _baseUrl = AppConfig.baseUrl;
  List<dynamic> _studentRequests = [];
  bool _loadingRequests = true;

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'tutor') {
      _fetchStudentRequests();
    } else {
      _loadingRequests = false;
    }
  }

  Future<void> _fetchStudentRequests() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/requests'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() {
          _studentRequests = jsonDecode(response.body);
        });
      }
    } catch (_) {}
    setState(() => _loadingRequests = false);
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.userData['name'] ?? 'User';
    final String email = widget.userData['email'] ?? 'user@university.edu';
    final bool isTutor = widget.userRole == 'tutor';
    final dynamic rawId = widget.userData['id'];
    final int tutorId =
        rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SECTION 1: Profile Card ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFF9B59D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isTutor ? '🎓 Tutor' : '📚 Learner',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── SECTION 2: Courses & Bio (Tutors only) ───────────
            if (isTutor) ...[
              _sectionTitle('Courses & Bio'),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(0xFF7B2FBE).withOpacity(0.1),
                    child: const Icon(Icons.edit_note,
                        color: Color(0xFF7B2FBE)),
                  ),
                  title: const Text(
                    'Edit Tutor Profile',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Update your bio and courses you teach',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TutorSetupScreen(
                          tutorId: tutorId,
                          onComplete: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── SECTION 3: Student Requests ──────────────────
              _sectionTitle('Student Requests'),
              const SizedBox(height: 12),
              _loadingRequests
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            color: Color(0xFF7B2FBE)),
                      ),
                    )
                  : _studentRequests.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No student requests at the moment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _studentRequests.length,
                          itemBuilder: (context, index) {
                            final req = _studentRequests[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Colors.grey.withOpacity(0.15)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.deepPurple.withOpacity(0.1),
                                  child: const Icon(Icons.school,
                                      color: Colors.deepPurple),
                                ),
                                title: Text(
                                  req['course_name'] ?? 'General Help',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  req['issue_description'] ??
                                      'No description provided',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                                onTap: () {},
                              ),
                            );
                          },
                        ),

              const SizedBox(height: 24),
            ],

            // ── SECTION 4: Logout ────────────────────────────────
            _sectionTitle('Account'),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.red.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log Out',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: _logout,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}