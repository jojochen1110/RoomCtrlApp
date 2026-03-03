import 'dart:convert';
import 'package:flutter/material.dart';
import './tool.dart';



// ===================== HOME SCREEN =====================
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  bool professorInOffice = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPresence(); // ← 起動時にAPI取得
  }

  // ===================== API: presence取得 =====================
  Future<void> loadPresence() async {
    setState(() => isLoading = true);

    Map<String, dynamic>? data = await HttpRequest.getPresence();
    if(data != null){
      setState(() {
            //  ここはAPIの返却形式により調整
            professorInOffice =
                data['presence'] == true ||
                data['presence'] == 1;
          });
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home'),
        backgroundColor: Colors.grey.shade200, // 薄いグレー
        foregroundColor: Colors.black,         // 文字・アイコン黒
        elevation: 0,                          // フラットで今風
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        professorInOffice
                          ? Icons.check_circle
                          : Icons.cancel,
                        size: 64,
                        color: professorInOffice
                          ? Colors.lightGreen   // ← 在室：薄緑
                          : Colors.red,          // ← 不在：赤
                        ),
                      const SizedBox(height: 16),
                      Text(
                        professorInOffice
                            ? 'Professor is in the office'
                            : 'Professor is not in the office',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentRequestScreen(),
                      ),
                    );
                  },
                  child: const Text('Request Appointment'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentStatusScreen(),
                      ),
                    );
                  },
                  child: const Text('View Appointment Status'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== REQUEST SCREEN =====================
class AppointmentRequestScreen extends StatefulWidget {
  const AppointmentRequestScreen({super.key});

  @override
  State<AppointmentRequestScreen> createState() =>
      _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState
    extends State<AppointmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final studentIdController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final reasonController = TextEditingController();

  bool isSubmitting = false;

  Future<void> submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('http://YOUR_API_BASE_URL/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text,
          'student_id': studentIdController.text,
          'date': dateController.text,
          'time': timeController.text,
          'reason': reasonController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your appointment has been submitted'),
          ),
        );

        Navigator.pop(context);
      } else {
        throw Exception('Failed to submit');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget buildField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Appointment'),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  buildField('Name', nameController),
                  buildField('Student ID', studentIdController),
                  buildField('Date (YYYY-MM-DD)', dateController),
                  buildField('Time (HH:MM)', timeController),
                  buildField('Reason', reasonController, maxLines: 3),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submitAppointment,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== STATUS SCREEN =====================
class AppointmentStatusScreen extends StatefulWidget {
  const AppointmentStatusScreen({super.key});

  @override
  State<AppointmentStatusScreen> createState() =>
      _AppointmentStatusScreenState();
}

class _AppointmentStatusScreenState
    extends State<AppointmentStatusScreen> {
  List appointments = [];
  bool isLoading = true;

  Future<void> fetchAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('http://YOUR_API_BASE_URL/appointments'),
      );

      if (response.statusCode == 200) {
        appointments = jsonDecode(response.body);
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade300; // 薄緑
      case 'rejected':
        return Colors.red;             // 赤
      case 'pending':
      default:
        return Colors.black;           // 保留
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Status'),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text('No appointments found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          '${appt['date']}  ${appt['time']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(appt['reason'] ?? ''),
                        trailing: Text(
                          (appt['status'] ?? '').toUpperCase(),
                          style: TextStyle(
                            color: statusColor(appt['status'] ?? 'pending'),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
