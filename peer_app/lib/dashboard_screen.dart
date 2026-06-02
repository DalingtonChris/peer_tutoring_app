import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'find_tutor_screen.dart';
import 'profile_screen.dart';
import 'request_help_screen.dart';

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
        const TutorSlotsTab(),
        ProfileScreen(
          userData: widget.userData,   // ✅ pass userData
          userRole: widget.userRole,   // ✅ pass userRole
        ),
      ];
      _navDestinations = const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Tutor Desk',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'My Slots',
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
          userData: widget.userData,   // ✅ pass userData
          userRole: widget.userRole,   // ✅ pass userRole
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
// 1. LEARNER HOME TAB
// ==========================================
class LearnerHomeTab extends StatelessWidget {
  final Map<String, dynamic> currentUserData;
  const LearnerHomeTab({super.key, required this.currentUserData});

  @override
  Widget build(BuildContext context) {
    final String displayName = currentUserData['name'] ?? 'Learner';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PeerConnect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final myId = currentUserData['id'];
          final int parsedCurrentUserId =
              myId is int ? myId : int.tryParse(myId.toString()) ?? 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RequestHelpScreen(studentId: parsedCurrentUserId),
            ),
          );
        },
        icon: const Icon(Icons.add_task),
        label: const Text("Request Help"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 8),
            const Text(
              "What are we mastering today?",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              "Your Upcoming Sessions",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.menu_book, color: Colors.white),
                ),
                title: Text("Database Normalization (1NF to 3NF)"),
                subtitle: Text("With Tutor Alex • Tomorrow at 4:00 PM"),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. TUTOR HOME TAB
// ==========================================
class TutorHomeTab extends StatelessWidget {
  final Map<String, dynamic> currentUserData;
  const TutorHomeTab({super.key, required this.currentUserData});

  Future<List<dynamic>> _fetchData(String url) async {
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Server error: ${response.statusCode}');
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = currentUserData['name'] ?? 'Tutor';

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
              label: const Text(
                "Active Balance: 140 pts",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green.withOpacity(0.1),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $displayName",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, "Hours Taught", "18.5 hrs",
                      Icons.history_toggle_off, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, "Total Earnings", "\$370.00",
                      Icons.payments_outlined, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, "Rating Score", "4.9 ★",
                      Icons.star_border, Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, "Active Match", "3 Students",
                      Icons.people_outline, Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'General Help Requests',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRequestList(
              'http://192.168.1.145:3000/api/requests',
              'No student requests at the moment.',
            ),
            const SizedBox(height: 32),
            Text(
              'Needs by Course',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRequestList(
              'http://192.168.1.145:3000/api/course-needs',
              'No specialized course demands found.',
            ),
          ],
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

  Widget _buildRequestList(String apiUrl, String emptyMessage) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchData(apiUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Could not load data. Check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.15)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child: const Icon(Icons.school, color: Colors.deepPurple),
                ),
                title: Text(
                  item['course_name'] ?? 'General Engineering',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    item['issue_description'] ?? 'No description provided'),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey),
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 3. TUTOR AVAILABILITY PLACEHOLDER
// ==========================================
class TutorSlotsTab extends StatelessWidget {
  const TutorSlotsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Availability',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'Availability logic & calendar grids here.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}