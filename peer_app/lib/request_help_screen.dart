import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestHelpScreen extends StatefulWidget {
  final int studentId;

  const RequestHelpScreen({super.key, required this.studentId});

  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _courseController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_courseController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.145:3000/api/student/request'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_id": widget.studentId,
          "course_name": _courseController.text,
          "issue_description": _descController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception("Server responded with: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ask for Help")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: "Course Name"),
            ),
            TextField(
              controller: _descController,
              decoration:
                  const InputDecoration(labelText: "Describe your issue"),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRequest,
              child: const Text("Submit Request"),
            ),
          ],
        ),
      ),
    );
  }
}