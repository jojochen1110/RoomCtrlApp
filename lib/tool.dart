import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//about alarm
class AlarmService {
  // 用來儲存目前正在顯示的 Entry 和訊息
  static final List<_AlarmEntry> _activeAlarms = [];
  static BuildContext? _context;

  // 初始化，在 main.dart 或首頁呼叫一次
  static void init(BuildContext context) {
    _context = context;
  }

  static void show(String message) {
    if (_context == null) return;

    // 如果訊息已存在，就不重複顯示
    if (_activeAlarms.any((e) => e.message == message)) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AlarmVisual(
        message: message,
        // 動態計算位置：根據自己在列表中的 index
        onDismiss: () => _remove(message),
      ),
    );

    _activeAlarms.insert(0, _AlarmEntry(message, entry));
    Overlay.of(_context!).insert(entry);

    // 讓所有現有的橫幅重新整理位置
    _refreshAll();
    Future.delayed(const Duration(seconds: 5), () => _remove(message));
  }

  static void _remove(String message) {
    final index = _activeAlarms.indexWhere((e) => e.message == message);
    if (index != -1) {
      _activeAlarms[index].entry.remove();
      _activeAlarms.removeAt(index);
      _refreshAll(); // 移除後，下方的橫幅會自動上移
    }
  }

  static void _refreshAll() {
    for (var alarm in _activeAlarms) {
      alarm.entry.markNeedsBuild(); // 觸發重繪以更新 Positioned 的 top 值
    }
  }
}

class _AlarmEntry {
  final String message;
  final OverlayEntry entry;
  _AlarmEntry(this.message, this.entry);
}

class _AlarmVisual extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _AlarmVisual({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    // 找到自己在列表中的位置
    final index = AlarmService._activeAlarms.indexWhere((e) => e.message == message);
    if (index == -1) return const SizedBox();

    // 計算 top 位置 (假設 AppBar 高度 + 狀態欄約 80)
    // 每個橫幅高度約 55，自動根據 index 疊加或上移
    double topPosition = 85.0 + (index * 58.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: topPosition,
      left: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<Offset>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: const Offset(0, -1), end: const Offset(0, 0)),
          curve: Curves.easeOutBack,
          builder: (context, offset, child) {
            return FractionalTranslation(
              translation: offset,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
//about alarm
//notice

class NoticeService {
  static final List<_NoticeEntry> _activeNotices = [];
  static BuildContext? _context;

  static void init(BuildContext context) => _context = context;

  static void show(String message) {
    if (_context == null) return;
    if (_activeNotices.any((e) => e.message == message)) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NoticeVisual(
        message: message,
        onDismiss: () => _remove(message),
      ),
    );

    _activeNotices.insert(0, _NoticeEntry(message, entry));
    Overlay.of(_context!).insert(entry);

    _refreshAll();
    // 通知通常停留時間可以短一點，比如 3 秒
    Future.delayed(const Duration(seconds: 3), () => _remove(message));
  }

  static void _remove(String message) {
    final index = _activeNotices.indexWhere((e) => e.message == message);
    if (index != -1) {
      _activeNotices[index].entry.remove();
      _activeNotices.removeAt(index);
      _refreshAll();
    }
  }

  static void _refreshAll() {
    for (var notice in _activeNotices) {
      notice.entry.markNeedsBuild();
    }
  }
}

class _NoticeEntry {
  final String message;
  final OverlayEntry entry;
  _NoticeEntry(this.message, this.entry);
}
class _NoticeVisual extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _NoticeVisual({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final index = NoticeService._activeNotices.indexWhere((e) => e.message == message);
    if (index == -1) return const SizedBox();

    // 這裡我們稍微偏移一點，避免跟 Alarm 重疊
    // 或者你可以把 Notice 放在底部 (bottomPosition)
    double topPosition = 85.0 + (index * 58.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: topPosition,
      left: 15,
      right: 15,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<Offset>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: const Offset(0, -1), end: const Offset(0, 0)),
          curve: Curves.easeOutBack,
          builder: (context, offset, child) {
            return FractionalTranslation(
              translation: offset,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800.withOpacity(0.9), // 深色質感的背景
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 18),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
//notice

//http request
class HttpRequest {
  // 將重複的 Base URL 抽出，未來如果要換伺服器，只要改這裡就好
  static const String baseUrl = 'http://192.168.13.251:5000';

  /// 發送 POST 請求更新設備狀態
  static Future<void> send(String item, dynamic value) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/device_state/$item'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({item: value}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        AlarmService.show("Update failed: ${response.statusCode}");
      }
    } catch (e) {
      AlarmService.show("Network error: $e");
    }
  }

  static Future<Map<String, dynamic>?> getPresence() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/device_state/presence'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        AlarmService.show("Failed to load data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      AlarmService.show("Network error: $e");
        return null;
    }
  }

  /// 發送 GET 請求獲取感測器數據
  static Future<Map<String, dynamic>?> getSensors() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/sensors'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // 解析 JSON 並回傳 Map
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        AlarmService.show("Failed to fetch sensors: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      AlarmService.show("Network error: $e");
      return null;
    }
  }
  static Future<List<dynamic>> getAppointments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/appointments'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // 假設回傳的是預約列表
      }
    } catch (e) {
      AlarmService.show("Fetch error: $e");
    }
    return [];
  }
  static Future<void> respondAppointment(int id, String status) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/appointments/respond'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id, "status": status}),
      );
    } catch (e) {
      AlarmService.show("Respond error: $e");
    }
  }
}
//http request