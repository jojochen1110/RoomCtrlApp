import 'package:flutter/material.dart';
import './professor_console.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _login() {
    if (_userController.text == 'abc' && _passController.text == '1234') {
      // 登入成功：跳轉並移除登入頁
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfessorConsole()),
      );
    } else {
      // 登入失敗：彈出警告
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login failed: Incorrect username or password"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("Login", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "account", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: true, // 密碼遮罩
              decoration: const InputDecoration(labelText: "password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text("Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Office',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(), // 啟動點改為登入頁
    );
  }
}

void main() {
  runApp(const MyApp());
}

