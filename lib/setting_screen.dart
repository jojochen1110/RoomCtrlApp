import 'package:flutter/material.dart';
import './tool.dart';
import './main.dart';
import './user_session.dart';
import './professor_console.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 這些變數未來可以儲存在 SharedPreferences 中


  void _handleLogout() {
    // 清除本地資料 (範例)
    // SharedPreferences.getInstance().then((prefs) => prefs.clear());
    timer?.cancel();
    timer = null; // 清空變數

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false, // 移除所有先前的路由
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Professor Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Account"),
            onTap: () { _showChangeAccountDialog();},
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            onTap: () { _showChangePasswordDialog();/* 導航到密碼修改頁 */ },
          ),


          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () => _handleLogout(),
          ),
        ],
      ),
    );
  }

  void _showChangeAccountDialog() {
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text("Change Account Name"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Account"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // 呼叫 API 進行修改
              UserSession.changeAccount(newController.text);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text("Change Password"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current Password"),
              ),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm New Password"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // 1. 基本前端檢查
              if (oldController.text != UserSession.getPassword()) {
                AlarmService.show("New passwords do not match!");
                return;
              }
              if (newController.text != confirmController.text) {
                AlarmService.show("New passwords do not match!");
                return;
              }
              if (newController.text.length < 4) {
                AlarmService.show("Password too short (min 4 chars)");
                return;
              }

              // 2. 呼叫 API 進行修改
              UserSession.changePassword(newController.text);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

}

