import 'package:flutter/material.dart';
import 'dart:async';
import './tool.dart';
import './setting_screen.dart';


double _ensureDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble(); // int 有 toDouble()
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class SensorCard extends StatelessWidget {
  final String type; // 'temp', 'humidity', 'light', 'co'
  final double value;

  const SensorCard({
    required this.type,
    required this.value,
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
          tempColor = Color.lerp(Colors.blue[300], Colors.orange[300], t.clamp(0, 0.5) * 2)!;
        } else {
          // 後半段：橙色 (23°C) -> 紅色 (30°C)
          // 將 0.5~1.0 的 t 映射到 0.0~1.0
          tempColor = Color.lerp(Colors.orange[300], Colors.red[400], (t.clamp(0.5, 1)-0.5) * 2)!;
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
                heightFactor: (value / 100).clamp(0.05, 0.95),
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
        double angle = (safeValue / 100).clamp(0.03, 0.97) * 3.14 - 1.57;

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
    return "${value.toStringAsFixed(1)}${type == 'humidity' ? ' %' : type == 'CO' ? ' ppm' : ''}";
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
  double _fanValue = 0;
  double _tempValue = 26.0;
  double _acOn = 0;

  // 溫度輸入框的控制項
  final TextEditingController _tempController = TextEditingController(text: "26.0");

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
            }, (val) {
              HttpRequest.send("target_brightness", val);
            }, Icons.lightbulb),

            // --- 燈光開關 ---
            const Text("Light Switch", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('off')),
                  ButtonSegment(value: 1, label: Text('on')),
                ],
                selected: {_acOn},
                onSelectionChanged: (newSelection) {
                  setState(() => _acOn = newSelection.first);
                  HttpRequest.send("light_switch", _acOn);
                },
              ),
            ),

            // --- 風扇控制 ---
            const Text("Fan", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('off')),
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                ],
                selected: {_fanValue},
                onSelectionChanged: (newSelection) {
                  setState(() => _fanValue = newSelection.first);
                  HttpRequest.send("fan", _fanValue);
                },
              ),
            ),

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
                    divisions: 14, // (30-16) * 2 = 28 個刻度，達成 0.5 單位
                    label: _tempValue.toString(),
                    onChanged: (val) {
                      setState(() {
                        _tempValue = val;
                        _tempController.text = val.toStringAsFixed(1);
                      });
                    },
                    onChangeEnd: (val) {
                      HttpRequest.send("target_temp", val);
                    }
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
                        setState(() {
                          _tempValue = newValue.clamp(16, 30).round().toDouble();
                          _tempController.text = _tempValue.toStringAsFixed(1);
                        });
                        HttpRequest.send("target_temp", newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
            // --- 空調模式 (開關) ---
            const Text("Air Conditioner", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('off')),
                  ButtonSegment(value: 1, label: Text('on')),
                ],
                selected: {_acOn},
                onSelectionChanged: (newSelection) {
                  setState(() => _acOn = newSelection.first);
                  HttpRequest.send("ac", _acOn);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  // 輔助函式：建立滑塊列
  Widget _buildSliderRow(String label, double value, double min, double max, Function(double) onChanged, Function(double) onChangeEnd, IconData icon) {
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
          onChangeEnd: onChangeEnd,
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
  // 1. 定義數據變數
  double _temp = 30;
  double _humidity = 100;
  double _light = 100;
  double _coLevel = 50;

  // 2. 抓取 Flask 數據的函式
  Future<void> _refreshData() async {
    final data = await HttpRequest.getSensors();
    if (data != null) {
      setState(() {
        // 將 JSON 數據填入變數
        _temp = _ensureDouble(data['temperature']).toDouble();
        _humidity = _ensureDouble(data['humidity']).toDouble();
        _light = _ensureDouble(data['light_level']).toDouble();
        _coLevel = _ensureDouble(data['co_ppm']).toDouble();
        if (_coLevel >= 60){
          AlarmService.show("Warning : Excessive carbon monoxide");
        }
      });
    }
  }

  // 3. 設定定時器 (例如每 2 秒更新一次)
  @override
  void initState() {
    super.initState();
    _refreshData(); // 初始抓取一次
    Timer.periodic(const Duration(seconds: 5), (timer) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    AlarmService.init(context); // 註冊 context 給全域使用
    return Scaffold(
      appBar: AppBar(title: const Text("Office Control Panel")),
      body: Stack(
        children: [
          SingleChildScrollView( // that it could Scroll
            child: Column(
              children: [
                // a. data card
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Wrap( // 自動換行的布局
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SensorCard(type: "temp", value: _temp),
                      SensorCard(type: "humidity", value: _humidity),
                      SensorCard(type: "light", value: _light),
                      SensorCard(type: "CO", value: _coLevel),
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
                  title: const Text("ManageAppointments"),
                  trailing: const Badge(label: Text("3")), // message hadn't read
                  onTap: () {/* into Scheduling page */},
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("setting"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );/* into setting page */},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}