import 'package:flutter/material.dart';
import './tool.dart';
import './main.dart';
import './user_session.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 這些變數未來可以儲存在 SharedPreferences 中
  String _displayName = "Prof. Chen";
  bool _autoCloseAC = true;
  bool _autoCloseLight = true;

  void _editName() {
    TextEditingController controller = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Display Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => _displayName = controller.text);
              Navigator.pop(context);

              UserSession.changePassword(controller.text);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    // 清除本地資料 (範例)
    // SharedPreferences.getInstance().then((prefs) => prefs.clear());

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
          _buildSectionTitle("Profile"),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Display Name"),
            subtitle: Text(_displayName),
            onTap: () => _editName(), // 彈出對話框修改
          ),
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
          _buildSectionTitle("One-Tap Leave Configuration"),
          SwitchListTile(
            secondary: const Icon(Icons.ac_unit),
            title: const Text("Turn off AC"),
            value: _autoCloseAC,
            onChanged: (val) => setState(() => _autoCloseAC = val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lightbulb_outline),
            title: const Text("Turn off Lights"),
            value: _autoCloseLight,
            onChanged: (val) => setState(() => _autoCloseLight = val),
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

              // 2. 呼叫 API 進行修改
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  // 在 ProfessorConsole 中呼叫
  Future<void> handleOneTapLeave() async {
    AlarmService.show("Executing One-Tap Leave...");

    // 1. 同步執行多個請求
    List<Future> tasks = [];
    tasks.add(HttpRequest.send("presence", false)); // 設為不在位

    if (_autoCloseAC) tasks.add(HttpRequest.send("ac", false));
    if (_autoCloseLight) tasks.add(HttpRequest.send("light", 0));

    await Future.wait(tasks);

    AlarmService.show("Office is now in Power-Saving mode.");
  }
}

