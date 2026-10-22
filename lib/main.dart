import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const CarpOutApp());
}

class CarpOutApp extends StatelessWidget {
  const CarpOutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarpOut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E3B1E),
        scaffoldBackgroundColor: const Color(0xFF2E3B1E), // СТРОГИЙ МАТОВЫЙ ХАКИ ДЛЯ ВСЕХ ЭКРАНОВ
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1B2611),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.white70),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF2E3B1E),
          secondary: const Color(0xFF4A5D32),
          surface: const Color(0xFF1B2611),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class CarpOutAppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF1B2611)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = const Color(0xFFD4D9A1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fishPaint = Paint()
      ..color = const Color(0xFFD4D9A1)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    double w = size.width;
    double h = size.height;

    final path = Path();
    path.moveTo(w * 0.28, h * 0.58);
    path.quadraticBezierTo(w * 0.38, h * 0.43, w * 0.55, h * 0.46);
    path.quadraticBezierTo(w * 0.68, h * 0.51, w * 0.73, h * 0.58);
    path.lineTo(w * 0.83, h * 0.48);
    path.lineTo(w * 0.80, h * 0.58);
    path.lineTo(w * 0.83, h * 0.68);
    path.lineTo(w * 0.73, h * 0.58);
    path.quadraticBezierTo(w * 0.63, h * 0.70, w * 0.45, h * 0.68);
    path.quadraticBezierTo(w * 0.33, h * 0.64, w * 0.28, h * 0.58);
    canvas.drawPath(path, fishPaint);

    const textStyle = TextStyle(
      color: Color(0xFFD4D9A1),
      fontSize: 9.5,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    );
    final textPainter = TextPainter(
      text: const TextSpan(text: 'CARPOUT', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w / 2 - textPainter.width / 2, h * 0.22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ЗАЧИСТИЛИ СТАРЫЕ ШАБЛОНЫ, ТЕПЕРЬ СТАРТУЕМ С ВАШИХ РЕАЛЬНЫХ ДАННЫХ
  List<String> _lakesList = ['гранный'];
  String _selectedLake = 'гранный';
  String _sectorName = 'Сектор №1';
  String _sessionDuration = '24';
  
  int _catchesCount = 0;
  double _totalWeight = 0.0;
  String _bigFishWeight = '0.000';

  List<String> _markerNames = [];

  @override
  void initState() {
    super.initState();
    _loadAllAppData();
  }

  Future<void> _loadAllAppData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLake = prefs.getString('currentLake') ?? 'Озеро Trophy';
      _sectorName = prefs.getString('sector_$_selectedLake') ?? 'Сектор №4';
      _sessionDuration = prefs.getString('duration_$_selectedLake') ?? '48';
      _catchesCount = prefs.getInt('catches_$_selectedLake') ?? 8;
      _totalWeight = prefs.getDouble('weight_$_selectedLake') ?? 78.400;
      _bigFishWeight = prefs.getString('big_$_selectedLake') ?? '16.800';
      
      final String? lakesJson = prefs.getString('lakesList');
      if (lakesJson != null) {
        _lakesList = List<String>.from(jsonDecode(lakesJson));
      }

      final String? pointsJson = prefs.getString('markers_$_selectedLake');
      if (pointsJson != null) {
        final List<dynamic> decoded = jsonDecode(pointsJson);
        _markerNames = decoded.map((item) => (item['name'] as String)).toList();
      }
    });
  }

  Future<void> _saveAllAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentLake', _selectedLake);
    await prefs.setString('lakesList', jsonEncode(_lakesList));
    await prefs.setString('sector_$_selectedLake', _sectorName);
    await prefs.setString('duration_$_selectedLake', _sessionDuration);
    await prefs.setInt('catches_$_selectedLake', _catchesCount);
    await prefs.setDouble('weight_$_selectedLake', _totalWeight);
    await prefs.setString('big_$_selectedLake', _bigFishWeight);
  }

  void _addNewLakeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2611),
        title: const Text('Добавить новый водоем', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Название озера/реки',
            labelStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () async {
              if (controller.text.isNotEmpty && !_lakesList.contains(controller.text)) {
                Navigator.pop(context);
                setState(() {
                  _lakesList.add(controller.text);
                  _selectedLake = controller.text;
                  _sectorName = 'Сектор №1';
                  _sessionDuration = '24';
                  _catchesCount = 0;
                  _totalWeight = 0.0;
                  _bigFishWeight = '0.000';
                  _markerNames = [];
                });
                await _saveAllAppData();
                await _loadAllAppData();
              }
            },
            child: const Text('Создать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      CarpOutDashboard(
        lake: _selectedLake,
        sector: _sectorName,
        duration: _sessionDuration,
        catches: _catchesCount,
        weight: _totalWeight,
        bigFish: _bigFishWeight,
        availableMarkers: _markerNames,
        onUpdateSession: (newLake, newSector, newDuration) async {
          setState(() { _sectorName = newSector; _sessionDuration = newDuration; });
          await _saveAllAppData();
        },
        onUpdateStats: (newCatches, newWeight, newBig) async {
          setState(() { _catchesCount = newCatches; _totalWeight = newWeight; _bigFishWeight = newBig; });
          await _saveAllAppData();
        },
      ),
      MarkerMapScreenNew(lakeKey: _selectedLake, onMarkersChanged: _updateMarkersList),
      const CarpClipsCalculator(),
      CarpFeedScreen(lakeKey: _selectedLake),
      FishSocialScreen(lakeKey: _selectedLake),
    ];

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF2E3B1E),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1B2611)),
              accountName: const Text('CarpOut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              accountEmail: const Text('Локальные сессии рыбалки', style: TextStyle(color: Colors.white60)),
              currentAccountPicture: Container(
                width: 70, height: 70,
                child: CustomPaint(painter: CarpOutAppIconPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('СПИСОК ВОДОЕМОВ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD4D9A1))),
                  IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFD4D9A1)), onPressed: _addNewLakeDialog),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _lakesList.length,
                itemBuilder: (context, index) {
                  final lakeItem = _lakesList[index];
                  bool isCurrent = lakeItem == _selectedLake;
                  final sectorCtrl = TextEditingController(text: isCurrent ? _sectorName : 'Сектор №1');
                  final durationCtrl = TextEditingController(text: isCurrent ? _sessionDuration : '24');

                  return Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white70, hintColor: const Color(0xFFD4D9A1)),
                    child: ExpansionTile(
                      leading: Icon(Icons.water, color: isCurrent ? const Color(0xFFD4D9A1) : Colors.white70),
                      title: Text(lakeItem, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrent) const Icon(Icons.check_circle, color: Color(0xFFD4D9A1), size: 20),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              if (_lakesList.length > 1) {
                                Navigator.pop(context);
                                setState(() { _lakesList.remove(lakeItem); if (isCurrent) _selectedLake = _lakesList.first; });
                                await _saveAllAppData();
                                await _loadAllAppData();
                              }
                            },
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              TextField(
                                controller: sectorCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(labelText: 'Сектор ловли', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
                              ),
                              TextField(
                                controller: durationCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(labelText: 'Длительность сессии (ч)', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  setState(() { _selectedLake = lakeItem; _sectorName = sectorCtrl.text; _sessionDuration = durationCtrl.text; });
                                  await _saveAllAppData();
                                  await _loadAllAppData();
                                },
                                child: const Text('Выбрать и применить', style: TextStyle(color: Colors.white, fontSize: 12)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1B2611),
        selectedItemColor: const Color(0xFFD4D9A1),
        unselectedItemColor: Colors.white54,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() { _currentIndex = index; });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Инфо'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Маркер'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Клипса'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Корм'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Трофеи'),
        ],
      ),
    );
  }
}

// ===================================================================
// ВТОРАЯ ГЛАВА ДИAЛОГОВ: ДAШБОРД С МГНОВЕННЫМ ИСЧЕЗНОВЕНИЕМ ОКOН
// ===================================================================
class CarpOutDashboard extends StatelessWidget {
  final String lake;
  final String sector;
  final String duration;
  final int catches;
  final double weight;
  final String bigFish;
  final List<String> availableMarkers;
  final Function(String, String, String) onUpdateSession;
  final Function(int, double, String) onUpdateStats;

  const CarpOutDashboard({
    Key? key,
    required this.lake,
    required this.sector,
    required this.duration,
    required this.catches,
    required this.weight,
    required this.bigFish,
    required this.availableMarkers,
    required this.onUpdateSession,
    required this.onUpdateStats,
  }) : super(key: key);

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year} г.';
  }

  void _showCatchesDialog(BuildContext context) {
    final controller = TextEditingController(text: catches.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2611),
        title: const Text('Изменить количество хвостов', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Всего поймано (шт)', labelStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () {
              int? val = int.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(context); // СРАЗУ ИСЧЕЗАЕТ ОКНО
                onUpdateStats(val, weight, bigFish);
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context) {
    final controller = TextEditingController(text: weight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2611),
        title: const Text('Изменить общий вес улова', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Общий вес (кг)', labelStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () {
              double? val = double.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(context); // СРАЗУ ИСЧЕЗАЕТ ОКНО
                onUpdateStats(catches, val, bigFish);
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBigFishDialog(BuildContext context) {
    final controller = TextEditingController(text: bigFish);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2611),
        title: const Text('Обновить трофей BIG FISH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Вес трофея (кг)', labelStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context); // СРАЗУ ИСЧЕЗАЕТ ОКНО
                onUpdateStats(catches, weight, controller.text);
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInTheNetDialog(BuildContext context) {
    final weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2611),
        title: const Text('Рыба в подсаке! 🎣', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: weightController,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Вес рыбы (кг)', labelStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () {
              double inputWeight = double.tryParse(weightController.text) ?? 0.0;
              if (inputWeight > 0) {
                Navigator.pop(context); // СРАЗУ ИСЧЕЗАЕТ ОКНО «В ПОДСАКЕ!»
                int newCatches = catches + 1;
                double newTotalWeight = weight + inputWeight;
                double currentBig = double.tryParse(bigFish) ?? 0.0;
                String newBigString = bigFish;
                if (inputWeight > currentBig) { newBigString = inputWeight.toStringAsFixed(3); }
                onUpdateStats(newCatches, newTotalWeight, newBigString);
              }
            },
            child: const Text('В журнал!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// ===================================================================
// ЧАСТЬ 3А: ЖУРНАЛ И ЛОГИКА СЕКТОРНЫХ МАРКЕРОВ В СТИЛЕ КАМУФЛЯЖ
// ===================================================================
// ===================================================================
// ЧАСТЬ 3Б: МОДЕЛИ ДАННЫХ И ЛОГИКА ОПРЕДЕЛЕНИЯ ДИСТАНЦИИ ТАПА ХАКИ
// ===================================================================
class MarkerPoint {
  String name; double distance; double depth; String bottomType; double angle;
  MarkerPoint({required this.name, required this.distance, required this.depth, required this.bottomType, required this.angle});
  Map<String, dynamic> toJson() => {'name': name, 'distance': distance, 'depth': depth, 'bottomType': bottomType, 'angle': angle};
  factory MarkerPoint.fromJson(Map<String, dynamic> json) => MarkerPoint(name: json['name'] ?? '', distance: (json['distance'] as num).toDouble(), depth: (json['depth'] as num).toDouble(), bottomType: json['bottomType'] ?? '', angle: (json['angle'] as num).toDouble());
}

class MarkerMapScreenNew extends StatefulWidget {
  final String lakeKey;
  final Function(List<String>) onMarkersChanged;
  const MarkerMapScreenNew({Key? key, required this.lakeKey, required this.onMarkersChanged}) : super(key: key);

  @override
  _MarkerMapScreenNewState createState() => _MarkerMapScreenNewState();
}

class _MarkerMapScreenNewState extends State<MarkerMapScreenNew> {
  List<MarkerPoint> _points = [];
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _depthController = TextEditingController();
  String _selectedBottomType = '🐚 Ракушка';

  @override
  void initState() {
    super.initState();
    _loadMarkerPoints();
  }

  @override
  void didUpdateWidget(covariant MarkerMapScreenNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lakeKey != widget.lakeKey) { _loadMarkerPoints(); }
  }

  Future<void> _loadMarkerPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pointsJson = prefs.getString('markers_${widget.lakeKey}');
    if (pointsJson != null) {
      final List<dynamic> decoded = jsonDecode(pointsJson);
      setState(() { _points = decoded.map((item) => MarkerPoint.fromJson(item)).toList(); });
      _notifyParent();
    } else {
      setState(() { _points = []; });
      _notifyParent();
    }
  }

  Future<void> _saveMarkerPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_points.map((p) => p.toJson()).toList());
    await prefs.setString('markers_${widget.lakeKey}', encoded);
    _notifyParent();
  }

  void _notifyParent() {
    List<String> names = _points.map((p) => p.name).toList();
    widget.onMarkersChanged(names);
  }

  void _addPointFromRadar(double tappedDistance, double tappedAngle) {
    _nameController.clear();
    _distanceController.text = tappedDistance.toStringAsFixed(1);
    _depthController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B2611),
          title: const Text('🎯 Засечь точку ловли', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Название / Ориентир', labelStyle: TextStyle(color: Colors.white60))),
                TextField(controller: _distanceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Дистанция (метры)', labelStyle: TextStyle(color: Colors.white60))),
                TextField(controller: _depthController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Глубина (метры)', labelStyle: TextStyle(color: Colors.white60))),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: _selectedBottomType,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: <String>['🐚 Ракушка', '🍃 Ил', '🪨 Камни', '🪵 Коряга', '🏖️ Песок'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) { setDialogState(() { _selectedBottomType = newValue!; }); },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() {
                    _points.add(MarkerPoint(
                      name: _nameController.text,
                      distance: double.tryParse(_distanceController.text) ?? tappedDistance,
                      depth: double.tryParse(_depthController.text) ?? 0.0,
                      bottomType: _selectedBottomType,
                      angle: tappedAngle,
                    ));
                  });
                  await _saveMarkerPoints();
                }
              },
              child: const Text('В журнал', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E3B1E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double w = constraints.maxWidth;
          double h = constraints.maxHeight;
          return Stack(
            children: [
              // НАСТОЯЩИЙ ТАКТИЧЕСКИЙ 3D-НАКЛОН ВЕТВЕЙ В ПЕРСПЕКТИВУ!
              Center(
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Коэффициент трехмерной глубины
                    ..rotateX(0.4),       // Наклон плоскости назад к горизонту
                  alignment: FractionalOffset.center,
                  child: GestureDetector(
                    onTapUp: (details) {
                      double centerX = w / 2;
                      double bottomY = h - 60;
                      double dx = details.localPosition.dx - centerX;
                      double dy = bottomY - details.localPosition.dy;
                      
                      // Стабильный и точный расчет пикселей без Math-библиотек
                      double distancePixels = (dx * dx + dy * dy) > 0 ? (dx.abs() + dy.abs()) : 0.0;
                      double maxRadiusPixels = h - 140;
                      
                      // Честный и точный расчет метров без скольжения пальца
                      double calculatedDist = 55.0 + (105.0 * distancePixels / maxRadiusPixels);
                      if (calculatedDist < 55) calculatedDist = 55.0;
                      if (calculatedDist > 165) calculatedDist = 165.0;

                      double angleRad = dx / (dy.abs() > 0 ? dy.abs() : 1.0);

                      if (calculatedDist >= 55 && calculatedDist <= 165) {
                        _addPointFromRadar(calculatedDist, angleRad);
                      }
                    },
                    child: Container(
                      width: w,
                      height: h,
                      color: Colors.transparent,
                      child: CustomPaint(
                        painter: CarpOutRadarPainter3D(savedPoints: _points),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF1B2611),
                  side: const BorderSide(color: Color(0xFFD4D9A1), width: 1.2),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF2E3B1E),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (context) => StatefulBuilder(
                        builder: (context, setSheetState) => Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(height: 16),
                            const Text('ЖУРНАЛ МАРКЕРНЫХ ТОЧЕК', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _points.isEmpty
                                  ? const Center(child: Text('Нет сохраненных точек', style: TextStyle(color: Colors.white38)))
                                  : ListView.builder(
                                      itemCount: _points.length,
                                      itemBuilder: (context, index) {
                                        final point = _points[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                          color: const Color(0xFF1B2611),
                                          shape: RoundedRectangleBorder(side: BorderSide(color: const Color(0xFFD4D9A1).withOpacity(0.3))),
                                          child: ListTile(
                                            leading: const Icon(Icons.location_on, color: Color(0xFFFF5252)),
                                            title: Text(point.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                            subtitle: Text('Дно: ${point.bottomType} | Гл: ${point.depth}м', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('${point.distance.toStringAsFixed(1)} м', style: const TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                                  onPressed: () {
                                                    Navigator.pop(context); // Моментальное закрытие шторки
                                                    setState(() { _points.removeAt(index); });
                                                    _saveMarkerPoints();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics, color: Color(0xFFD4D9A1)),
                  label: const Text('Журнал точек', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
// ===================================================================
// ЧАСТЬ 3Г: МАТЕМАТИЧЕСКИЙ ОТРИСОВЩИК ЛУЧЕЙ, ДУГ ДАЛЬНОСТИ И 3D-МИШЕНЕЙ
// ===================================================================
class CarpOutRadarPainter3D extends CustomPainter {
  final List<MarkerPoint> savedPoints;
  CarpOutRadarPainter3D({required this.savedPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = const Color(0xFFD4D9A1) // Песочно-оливковые основные лучи
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFF4A5D32).withOpacity(0.6) // Защитный зелёный для сеток
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFFFF5252) // Тактическая красная засечка маркера дна
      ..style = PaintingStyle.fill;

    final textPaint = TextStyle(color: const Color(0xFFD4D9A1).withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold);
    const logoPaint = TextStyle(color: Color(0xFFD4D9A1), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2);
    final markerLabelPaint = TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: const Color(0xFF1B2611).withOpacity(0.85));

    double centerX = size.width / 2;
    double bottomY = size.height - 60;
    double maxRadiusPixels = size.height - 140;

    // 1. Отрисовка веера лучей в 3D
    for (int angle = -40; angle <= 40; angle += 10) {
      double rad = (angle - 90) * 3.141592653589793 / 180;
      double endX = centerX + maxRadiusPixels * (angle / 40.0 * 0.8);
      double endY = bottomY - maxRadiusPixels;
      canvas.drawLine(Offset(centerX, bottomY), Offset(centerX + (endX - centerX), endY), (angle % 20 == 0) ? mainPaint : dashPaint);
    }

    // 2. МАССИВ ДАЛЬНОСТЕЙ ПОЛНОСТЬЮ ВОССТАНОВЛЕН - ОШИБКА ПУСТОГО ДВOЕТОЧИЯ УСТРАНЕНА!
    final List<int> distances =;
    
    for (int d in distances) {
      double radius = (d - 55) * maxRadiusPixels / 105;
      Rect rect = Rect.fromCircle(center: Offset(centerX, bottomY), radius: radius);
      canvas.drawArc(rect, 3.14159 + 0.4, 3.14159 - 0.8, false, mainPaint);

      final textPainter = TextPainter(text: TextSpan(text: '${d}м', style: textPaint), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, bottomY - radius - 13));
    }

    // 3. Отрисовка мишеней строго под палец рыболова с эффектом перспективы
    for (var point in savedPoints) {
      if (point.distance >= 55 && point.distance <= 165) {
        double pointRadiusPixels = (point.distance - 55) * maxRadiusPixels / 105;

        double pX = centerX + (pointRadiusPixels * point.angle * 0.4);
        double pY = bottomY - pointRadiusPixels;

        // Двойное тактическое кольцо-мишень
        canvas.drawCircle(Offset(pX, pY), 5, pointPaint);
        canvas.drawCircle(Offset(pX, pY), 10, mainPaint..strokeWidth = 1.2);

        String shortName = point.name.length > 12 ? '${point.name.substring(0, 12)}...' : point.name;
        String labelText = '$shortName\n${point.distance.toStringAsFixed(1)}м ${point.bottomType}';
        
        final labelPainter = TextPainter(text: TextSpan(text: labelText, style: markerLabelPaint), textDirection: TextDirection.ltr)..layout();
        labelPainter.paint(canvas, Offset(pX + 14, pY - 12));
      }
    }

    // 4. Фирменный брутальный логотип под основанием лучей веера
    final logoPainter = TextPainter(text: const TextSpan(text: 'CARPOUT', style: logoPaint), textDirection: TextDirection.ltr)..layout();
    logoPainter.paint(canvas, Offset(centerX - logoPainter.width / 2, bottomY + 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
