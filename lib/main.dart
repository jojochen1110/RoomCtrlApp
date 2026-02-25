import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SensorCard extends StatelessWidget {
  final String type; // 'temp', 'humidity', 'light', 'co'
  final double value;
  final Color themeColor;

  const SensorCard({
    required this.type,
    required this.value,
    required this.themeColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getDisplayName(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 11),

            // 核心：根據類型顯示不同的動態圖標
            _buildDynamicIcon(),

            const SizedBox(height: 8),
            // 具體數值顯示（點開才顯示的邏輯可以之後再加，這裡先常態顯示）
            Text(_getValueText(), style: const TextStyle(fontSize: 12, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  // 1. 根據類型決定要畫什麼圖標
  Widget _buildDynamicIcon() {
    switch (type) {
      case 'temp':
        // 溫度：圓形變色
        double t = (value - 16) / (30 - 16);
        Color tempColor;
        if (t < 0.5) {
          // 前半段：藍色 (16°C) -> 橙色 (23°C)
          // 將 0.0~0.5 的 t 映射到 0.0~1.0
          tempColor = Color.lerp(Colors.blue, Colors.orange, t.clamp(0, 0.5) * 2)!;
        } else {
          // 後半段：橙色 (23°C) -> 紅色 (30°C)
          // 將 0.5~1.0 的 t 映射到 0.0~1.0
          tempColor = Color.lerp(Colors.orange, Colors.red, (t.clamp(0.5, 1)-0.5) * 2)!;
        }
        return Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: tempColor, shape: BoxShape.circle),
          child: Center(child: Text("${value.toStringAsFixed(1)}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        );

      case 'humidity':
        // 濕度：水滴填滿
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            const Icon(Icons.water_drop_outlined, size: 60, color: Colors.grey),
            ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: (value / 100).clamp(0, 1),
                child: const Icon(Icons.water_drop, size: 60, color: Colors.blue),
              ),
            ),
          ],
        );

      case 'light':
        // 亮度：燈泡色調
        double opacity = (value / 100).clamp(0.1, 1.0); // 假設亮度最大 100
        return Icon(Icons.lightbulb, size: 60, //color: Colors.yellow.withOpacity(opacity),

        color: Color.lerp(Colors.grey, Colors.yellow, opacity));

      case 'CO':
        final double safeValue = value;
        // 計算角度：從 -1.57 (左) 到 1.57 (右)
        double angle = (safeValue / 100).clamp(0, 1) * 3.14 - 1.57;

        return Column(
          children: [
            SizedBox(
              width: 100,
              height: 50,
              child: Stack(
                alignment: Alignment.bottomCenter, // 統一基準點在底部中心
                children: [
                  // 1. 底層：彩色半圓 (寬80, 高40)
                  Container(
                    width: 80,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(80)),
                      gradient: SweepGradient(
                        center: Alignment.bottomCenter,
                        startAngle: 3.14,
                        endAngle: 6.28,
                        colors: [Colors.green, Colors.orange, Colors.red],
                        stops: const [0.1, 0.5, 0.9],
                      ),
                    ),
                  ),

                  // 2. 中層：灰色遮罩 (寬60, 高30)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // 確保與 Card 顏色完全一致
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
                      ),
                    ),
                  ),

                  // 3. 頂層：順暢旋轉指針
                  // 我們建立一個 80x80 的透明容器，旋轉中心就在正中間
                  Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomCenter, // 完美的旋轉點
                    child: Container(
                      width: 45,
                      height: 45,
                      alignment: Alignment.topCenter, // 讓「針」長在容器的上半部
                      child: Container(
                        width: 3,
                        height: 35, // 針的長度
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // 4. 圓心軸點 (裝飾用)
                  Positioned(
                    bottom: -4,
                    child:Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        );

      default:
        return const Icon(Icons.sensors, size: 60);
    }
  }

  String _getDisplayName() {
    Map<String, String> names = {'temp': 'Temperature', 'humidity': 'Humidity', 'light': 'Brightness', 'CO': 'CoLevel'};
    return names[type] ?? 'unknown sensor';
  }

  String _getValueText() {
    if (type == 'temp') return ""; // 溫度已寫在圓圈內
    return "${value.toStringAsFixed(1)}${type == 'humidity' ? '%' : ''}";
  }
}//       SensorCard

class ControlSection extends StatefulWidget {
  final String title;
  const ControlSection({super.key, required this.title});

  @override
  State<ControlSection> createState() => _ControlSectionState();
}

class _ControlSectionState extends State<ControlSection> {
  // 設備狀態變數
  double _lightValue = 50.0;
  double _fanValue = 3.0;
  double _tempValue = 26.0;

  // 溫度輸入框的控制項
  final TextEditingController _tempController = TextEditingController(text: "26.0");

  // 空調模式切換 (使用 Set 因為 SegmentedButton 支援多選，但我們設為單選)
  Set<String> _acMode = {'off'};

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),

            // --- 燈光控制 ---
            _buildSliderRow("Light", _lightValue, 0, 100, (val) {
              setState(() => _lightValue = val);
            }, Icons.lightbulb),

            // --- 風扇控制 ---
            _buildSliderRow("Fan", _fanValue, 0, 10, (val) {
              setState(() => _fanValue = val);
            }, Icons.air),

            const SizedBox(height: 20),

            // --- 溫度控制 (滑塊 + 輸入框) ---
            const Text("Temperature (°C)", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _tempValue,
                    min: 16,
                    max: 30,
                    divisions: 28, // (30-16) * 2 = 28 個刻度，達成 0.5 單位
                    label: _tempValue.toString(),
                    onChanged: (val) {
                      setState(() {
                        _tempValue = val;
                        _tempController.text = val.toStringAsFixed(1);
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _tempController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    onSubmitted: (String value) {
                      double? newValue = double.tryParse(value);
                      if (newValue != null){
                          if (newValue >= 16 && newValue <= 30) {
                          setState(() {
                            _tempValue = ((newValue ?? 0.0) * 2).round() / 2; // 修正為最接近的 0.5
                            _tempController.text = _tempValue.toStringAsFixed(1);
                          });
                        }else if (newValue < 16){
                          newValue = 16;
                        }else if (newValue > 30){
                          newValue = 30;
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  // 輔助函式：建立滑塊列
  Widget _buildSliderRow(String label, double value, double min, double max, Function(double) onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
            const Spacer(),
            Text(value.toInt().toString()),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}//       ControlSection

class RoomStatusCard extends StatefulWidget {
  const RoomStatusCard({super.key});

  @override
  State<RoomStatusCard> createState() => _RoomStatusCardState();
}

class _RoomStatusCardState extends State<RoomStatusCard> {
  bool isDNDMode = false; // 勿擾模式狀態
  bool isRoomEmpty = true; // 模擬房間是否無人

  // 模擬的門鈴與紀錄數據
  final List<String> _records = [
    "10:30 - Door Bell Ring",
    "09:15 - Room into occupied",
  ];

  // 顯示詳細紀錄的底部彈窗
  void _showDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 根據內容自動調整高度
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("State Record", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const Text("Room Empty for ${1}h ${15}m", style: TextStyle(color: Colors.blue)),
              const SizedBox(height: 10),
              const Text("Door Bell Record：", style: TextStyle(fontWeight: FontWeight.bold)),
              ..._records.map((msg) => ListTile(
                leading: const Icon(Icons.notifications_active, size: 20),
                title: Text(msg, style: const TextStyle(fontSize: 14)),
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 點選此 ListTile 會彈出詳細資訊
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isRoomEmpty ? Colors.grey : Colors.green,
              child: Icon(isRoomEmpty ? Icons.person_off : Icons.person, color: Colors.white),
            ),
            title: Text(isRoomEmpty ? "The office is unoccupied" : "The office is occupied"),
            subtitle: const Text("View vacant time & doorbell logs"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showDetails,
          ),

          const Divider(height: 1),

          // 按鈕區
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 一鍵離開按鈕
                ElevatedButton.icon(
                  onPressed: () {
                    // 這裡未來可以串接 Flask 關閉所有燈光與冷氣
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("One-click exit has been executed: Turn off all devices.")),
                    );
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text("Exit Room"),
                ),

                // 勿擾模式切換
                FilterChip(
                  label: const Text("Do Not Disturb"),
                  selected: isDNDMode,
                  onSelected: (val) {
                    setState(() => isDNDMode = val);
                  },
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}//     RoomStatusCard

class ProfessorConsole extends StatefulWidget {
  const ProfessorConsole({super.key});

  @override
  State<ProfessorConsole> createState() => _ProfessorConsoleState();
}

class _ProfessorConsoleState extends State<ProfessorConsole> {
  bool hasAlarm = true; // test the warning state
  // 1. 定義數據變數
  double _temp = 30;
  double _humidity = 100;
  double _light = 100;
  double _coLevel = 50;

  // 2. 抓取 Flask 數據的函式
  Future<void> _refreshData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.165.252:5000/sensors'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // 將 JSON 數據填入變數
          _temp = data['temperature'].toDouble();
          _humidity = data['humidity'].toDouble();
          _light = data['light_level'].toDouble();
          _coLevel = data['co_ppm'].toDouble();
        });
      }
    } catch (e) {
    }
  }

  // 3. 設定定時器 (例如每 2 秒更新一次)
  @override
  void initState() {
    super.initState();
    _refreshData(); // 初始抓取一次
    Timer.periodic(const Duration(seconds: 2), (timer) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Office Control Panel")),
      body: SingleChildScrollView( // that it could Scroll
        child: Column(
          children: [
            // e. Warning area (on top of the screen)
            if (hasAlarm)
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.all(12),
                child: const Text("Warning：Excessive carbon monoxide!",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),

            // a. data card
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Wrap( // 自動換行的布局
                spacing: 10,
                runSpacing: 10,
                children: [
                  SensorCard(type: "temp", value: _temp, themeColor: Colors.orange),
                  SensorCard(type: "humidity", value: _humidity, themeColor: Colors.blue),
                  SensorCard(type: "light", value: _light, themeColor: Colors.yellow),
                  SensorCard(type: "CO", value: _coLevel, themeColor: Colors.black38),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Slider(
                    value: _temp,
                    min: 16,
                    max: 30,
                    onChanged: (newValue) {
                      setState(() {
                        _temp = newValue; // 當滑桿移動，更新變數並重繪 UI
                      });
                    },
                  ),Slider(
                    value: _humidity,
                    min: 0,
                    max: 100,
                    onChanged: (newValue) {
                      setState(() {
                        _humidity = newValue; // 當滑桿移動，更新變數並重繪 UI
                      });
                    },
                  ),Slider(
                    value: _light,
                    min: 0,
                    max: 100,
                    onChanged: (newValue) {
                      setState(() {
                        _light = newValue; // 當滑桿移動，更新變數並重繪 UI
                      });
                    },
                  ),Slider(
                    value: _coLevel,
                    min: 0,
                    max: 100,
                    onChanged: (newValue) {
                      setState(() {
                        _coLevel = newValue; // 當滑桿移動，更新變數並重繪 UI
                      });
                    },
                  ),
                ],
              ),
            ),


            // b. Control Section
            const ControlSection(title: "Control Panel"),

            // c. Room Status
            const RoomStatusCard(),

            // d. Scheduling and Settings
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Scheduling"),
              trailing: const Badge(label: Text("3")), // message hadn't read
              onTap: () {/* into Scheduling page */},
            ),
          ],
        ),
      ),
    );
  }
}

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

