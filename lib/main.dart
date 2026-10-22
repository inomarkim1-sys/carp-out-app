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

  void _updateMarkersList(List<String> newMarkers) {
    setState(() {
      _markerNames = newMarkers;
    });
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () async {
              if (controller.text.isNotEmpty && !_lakesList.contains(controller.text)) {
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
                Navigator.pop(context);
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
      CarpFeedScreen(lakeKey: _selectedLake), // Наше Питание и Таймер обратного отсчёта!
      FishSocialScreen(lakeKey: _selectedLake), // Наша Лента Трофеев
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
                                Navigator.pop(context); // СРАЗУ ЗАКРЫВАЕМ ШТОРКУ ПРИ УДАЛЕНИИ
                                setState(() {
                                  _lakesList.remove(lakeItem);
                                  if (isCurrent) _selectedLake = _lakesList.first;
                                });
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
                                  Navigator.pop(context); // МГНОВЕННО ЗАКРЫВАЕМ ШТОРКУ ПРИ НАЖАТИИ
                                  setState(() {
                                    _selectedLake = lakeItem;
                                    _sectorName = sectorCtrl.text;
                                    _sessionDuration = durationCtrl.text;
                                  });
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

// ===================================================================
// ЧАСТЬ 2А: ДАШБОРД ХАКИ С ИЗОЛИРОВАННЫМИ ФОРМАМИ И АСИНХРОННОЙ ПАМЯТЬЮ
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
                onUpdateStats(val, weight, bigFish);
                Navigator.pop(context);
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
                onUpdateStats(catches, val, bigFish);
                Navigator.pop(context);
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
                onUpdateStats(catches, weight, controller.text);
                Navigator.pop(context);
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
                int newCatches = catches + 1;
                double newTotalWeight = weight + inputWeight;
                double currentBig = double.tryParse(bigFish) ?? 0.0;
                String newBigString = bigFish;
                if (inputWeight > currentBig) { newBigString = inputWeight.toStringAsFixed(3); }
                onUpdateStats(newCatches, newTotalWeight, newBigString);
                Navigator.pop(context);
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
class MarkerPoint {
  String name;
  double distance;
  double depth;
  String bottomType;
  double angle;

  MarkerPoint({
    required this.name,
    required this.distance,
    required this.depth,
    required this.bottomType,
    required this.angle,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'distance': distance,
        'depth': depth,
        'bottomType': bottomType,
        'angle': angle,
      };

  factory MarkerPoint.fromJson(Map<String, dynamic> json) => MarkerPoint(
        name: json['name'] ?? '',
        distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
        depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
        bottomType: json['bottomType'] ?? '',
        angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
      );
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
    if (oldWidget.lakeKey != widget.lakeKey) {
      _loadMarkerPoints();
    }
  }

  Future<void> _loadMarkerPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pointsJson = prefs.getString('markers_${widget.lakeKey}');
    if (pointsJson != null) {
      final List<dynamic> decoded = jsonDecode(pointsJson);
      setState(() {
        _points = decoded.map((item) => MarkerPoint.fromJson(item)).toList();
      });
      _notifyParent();
    } else {
      setState(() {
        _points = [
          MarkerPoint(name: 'Дальняя бровка', distance: 91.2, depth: 3.2, bottomType: '🐚 Ракушка', angle: 0.2),
        ];
      });
      _saveMarkerPoints();
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
          backgroundColor: const Color(0xFF2E3B1E),
          title: const Text('🎯 Засечь точку ловли', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Название / Ориентир', labelStyle: TextStyle(color: Colors.white60))),
                TextField(controller: _distanceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Дистанция (метры)', labelStyle: TextStyle(color: Colors.white60))),
                TextField(controller: _depthController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Глубина (метры)', labelStyle: TextStyle(color: Colors.white60))),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Структура дна в точке:', style: TextStyle(color: Colors.white70, fontSize: 12))),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF2E3B1E),
                  value: _selectedBottomType,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: <String>['🐚 Ракушка', '🍃 Ил', '🪨 Камни', '🪵 Коряга', '🏖️ Песок'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setDialogState(() { _selectedBottomType = newValue!; });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
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
                  Navigator.pop(context);
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
      backgroundColor: const Color(0xFFA2B574), // Оливковый фон камуфляжа
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 4.0,
              child: GestureDetector(
                onTapUp: (details) {
                  double boxWidth = 380.0;
                  double boxHeight = 540.0;
                  double centerX = boxWidth / 2;
                  double bottomY = boxHeight - 45;

                  double dx = details.localPosition.dx - centerX;
                  double dy = bottomY - details.localPosition.dy;
                  double distancePixels = Math.sqrt(dx * dx + dy * dy);

                  double maxRadiusPixels = boxHeight - 95;
                  double calculatedDist = 55.0 + (distancePixels / maxRadiusPixels) * 105.0;

                  // Вычисляем честный угол тапа пальцем через арктангенс
                  double angleRad = Math.atan2(dx, dy);
                  
                  if (calculatedDist >= 55 && calculatedDist <= 160) {
                    _addPointFromRadar(calculatedDist, angleRad);
                  }
                },
                child: Container(
                  width: 380,
                  height: 540,
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: CarpOutRadarPainterNew(savedPoints: _points),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2E3B1E),
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
                        const Text('ЖУРНАЛ МАРКЕРНЫХ ТОЧЕК', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _points.isEmpty
                              ? const Center(child: Text('Нет сохраненных точек', style: TextStyle(color: Colors.white60)))
                              : ListView.builder(
                                  itemCount: _points.length,
                                  itemBuilder: (context, index) {
                                    final point = _points[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      color: const Color(0xFF4A5D32),
                                      child: ListTile(
                                        leading: const Icon(Icons.location_on, color: Color(0xFFC5E1A5)),
                                        title: Text(point.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        subtitle: Text('Дно: ${point.bottomType} | Гл: ${point.depth}м', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('${point.distance.toStringAsFixed(1)} м', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                              onPressed: () {
                                                setState(() { _points.removeAt(index); });
                                                setSheetState(() {});
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
              icon: const Icon(Icons.analytics, color: Colors.white),
              label: const Text('Журнал точек', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class CarpOutRadarPainterNew extends CustomPainter {
  final List<MarkerPoint> savedPoints;
  CarpOutRadarPainterNew({required this.savedPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = const Color(0xFF2E3B1E)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFF4A5D32).withOpacity(0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    final textPaint = TextStyle(color: const Color(0xFF2E3B1E).withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold);
    const logoPaint = TextStyle(color: Color(0xFF2E3B1E), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2);
    final markerLabelPaint = TextStyle(color: const Color(0xFF1B2611), fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white.withOpacity(0.8));

    double centerX = size.width / 2;
    double bottomY = size.height - 45;
    double maxRadiusPixels = size.height - 95;

    // Сетка лучей веера
    for (int angle = -40; angle <= 40; angle += 10) {
      double rad = (angle - 90) * 3.141592653589793 / 180;
      double endX = centerX + maxRadiusPixels * Math.cos(rad);
      double endY = bottomY + maxRadiusPixels * Math.sin(rad);
      canvas.drawLine(Offset(centerX, bottomY), Offset(endX, endY), (angle % 20 == 0) ? mainPaint : dashPaint);
    }

    // НАМЕРТВО ЗАШИТЫЙ ТЕКСТОВЫЙ СПИСОК ВСЕХ КОЛЕЦ ДАЛЬНОСТИ
    final List<int> distances = [
      60, 75, 90, 105, 120, 135, 150
    ];
    
    for (int d in distances) {
      double radius = (d - 55) * maxRadiusPixels / 105;
      Rect rect = Rect.fromCircle(center: Offset(centerX, bottomY), radius: radius);
      canvas.drawArc(rect, 3.14159 + 0.5, 3.14159 - 1.0, false, mainPaint);

      final textPainter = TextPainter(text: TextSpan(text: '${d}м', style: textPaint), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, bottomY - radius - 12));
    }

    // ОТРИСОВКА МИШЕНЕЙ С УЧЕТОМ ЧЕСТНОГО УГЛА ИЗ ПАМЯТИ
    for (var point in savedPoints) {
      if (point.distance >= 55 && point.distance <= 160) {
        double pointRadiusPixels = (point.distance - 55) * maxRadiusPixels / 105;
        
        // Восстанавливаем точные радианы направления пальца
        double rad = (point.angle - (90 * 3.141592653589793 / 180));

        double pX = centerX + pointRadiusPixels * Math.cos(rad);
        double pY = bottomY + pointRadiusPixels * Math.sin(rad);

        canvas.drawCircle(Offset(pX, pY), 5, pointPaint);
        canvas.drawCircle(Offset(pX, pY), 9, mainPaint..strokeWidth = 1.0);

        String shortName = point.name.length > 12 ? '${point.name.substring(0, 12)}...' : point.name;
        String labelText = '$shortName\n${point.distance.toStringAsFixed(1)}м ${point.bottomType}';
        
        final labelPainter = TextPainter(text: TextSpan(text: labelText, style: markerLabelPaint), textDirection: TextDirection.ltr)..layout();
        labelPainter.paint(canvas, Offset(pX + 12, pY - 10));
      }
    }

    // ЛОГОТИП CARPOUT СМЕЩЕН В САМЫЙ НИЗ ПОД НАЧАЛО ЛУЧЕЙ
    final logoPainter = TextPainter(text: const TextSpan(text: 'CARPOUT', style: logoPaint), textDirection: TextDirection.ltr)..layout();
    logoPainter.paint(canvas, Offset(centerX - logoPainter.width / 2, bottomY + 15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
// ===================================================================
// ЧАСТЬ 3В: МАТЕМАТИЧЕСКИЙ МОДУЛЬ И ДВУХСТОРОННИЙ КАЛЬКУЛЯТОР КЛИПСЫ
// ===================================================================
class Math {
  static double sqrt(double value) {
    if (value < 0) return 0;
    double x = value; double y = 1.0;
    for (int i = 0; i < 10; i++) { x = (x + y) / 2; y = value / x; }
    return x;
  }
  static double sin(double rad) {
    double x = rad; double t = x; double sum = x;
    for (int i = 1; i <= 5; i++) { t = -t * x * x / ((2 * i) * (2 * i + 1)); sum += t; }
    return sum;
  }
  static double cos(double rad) {
    double x = rad; double t = 1.0; double sum = 1.0;
    for (int i = 1; i <= 5; i++) { t = -t * x * x / ((2 * i - 1) * (2 * i)); sum += t; }
    return sum;
  }
  static double atan2(double x, double y) {
    if (y == 0) return x > 0 ? 1.57079632679 : -1.57079632679;
    double z = x / y;
    double sum = z; double t = z;
    for (int i = 1; i <= 5; i++) {
      t = -t * z * z;
      sum += t / (2 * i + 1);
    }
    return y > 0 ? sum : (x >= 0 ? sum + 3.14159265359 : sum - 3.14159265359);
  }
}

class CarpClipsCalculator extends StatefulWidget {
  const CarpClipsCalculator({Key? key}) : super(key: key);
  @override
  _CarpClipsCalculatorState createState() => _CarpClipsCalculatorState();
}

class _CarpClipsCalculatorState extends State<CarpClipsCalculator> {
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _turnsController = TextEditingController();
  double _distanceBetweenSticks = 4.0;
  double _turnsResult = 0.0; double _metersResult = 0.0;

  void _calculateFromMeters() {
    double distance = double.tryParse(_distanceController.text) ?? 0.0;
    if (distance > 0 && _distanceBetweenSticks > 0) { setState(() { _turnsResult = distance / _distanceBetweenSticks; }); }
    else { setState(() { _turnsResult = 0.0; }); }
  }

  void _calculateFromTurns() {
    double turns = double.tryParse(_turnsController.text) ?? 0.0;
    if (turns > 0 && _distanceBetweenSticks > 0) { setState(() { _metersResult = turns * _distanceBetweenSticks; }); }
    else { setState(() { _metersResult = 0.0; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2B574), // Оливковый фон камуфляжа
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Калькулятор дистанции', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2611))),
            const SizedBox(height: 16),
            const Text('База между колышками:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2611))),
            const SizedBox(height: 8),
            Row(children: [_buildDistanceChip(3.0, '3 м'), const SizedBox(width: 8), _buildDistanceChip(4.0, '4 м (Стандарт)'), const SizedBox(width: 8), _buildDistanceChip(5.0, '5 м')]),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFD4D9A1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Из метров в обороты', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Дистанция ловли (метры)', labelStyle: const TextStyle(color: Color(0xFF2E3B1E)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.straighten, color: Color(0xFF2E3B1E))),
                    onChanged: (_) { _turnsController.clear(); _metersResult = 0.0; _calculateFromMeters(); },
                  ),
                  if (_turnsResult > 0) ...[const SizedBox(height: 16), Center(child: Column(children: [Text(_turnsResult.toStringAsFixed(2), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))), const Text('оборотов на колышках', style: TextStyle(color: Color(0xFF1B2611), fontSize: 12))]))]
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFD4D9A1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Из оборотов в метры (Обратный счет)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _turnsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Количество оборотов на колышках', labelStyle: const TextStyle(color: Color(0xFF2E3B1E)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.refresh, color: Color(0xFF2E3B1E))),
                    onChanged: (_) { _distanceController.clear(); _turnsResult = 0.0; _calculateFromTurns(); },
                  ),
                  if (_metersResult > 0) ...[const SizedBox(height: 16), Center(child: Column(children: [Text('${_metersResult.toStringAsFixed(1)} м', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))), const Text('дистанция до точки ловли', style: TextStyle(color: Color(0xFF1B2611), fontSize: 12))]))]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceChip(double value, String label) {
    bool isSelected = _distanceBetweenSticks == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      selected: isSelected, selectedColor: const Color(0xFF2E3B1E), backgroundColor: Colors.white,
      onSelected: (bool selected) { if (selected) { setState(() { _distanceBetweenSticks = value; if (_distanceController.text.isNotEmpty) _calculateFromMeters(); if (_turnsController.text.isNotEmpty) _calculateFromTurns(); }); } },
    );
  }
}
// ===================================================================
// ЧАСТЬ 4А: МОДЕЛЬ ДАННЫХ ТРОФЕЕВ И ЛЕНТА "СОЦИАЛЬНОЙ СЕТИ" РЫБ
// ===================================================================
class FishTrophy {
  String id;
  String fishType;
  double weight;
  String dateTime;
  String bait;
  String notes;
  String imagePath; // Путь к локальной фотографии на телефоне

  FishTrophy({
    required this.id,
    required this.fishType,
    required this.weight,
    required this.dateTime,
    required this.bait,
    required this.notes,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fishType': fishType,
        'weight': weight,
        'dateTime': dateTime,
        'bait': bait,
        'notes': notes,
        'imagePath': imagePath,
      };

  factory FishTrophy.fromJson(Map<String, dynamic> json) => FishTrophy(
        id: json['id'] ?? '',
        fishType: json['fishType'] ?? 'Карп',
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        dateTime: json['dateTime'] ?? '',
        bait: json['bait'] ?? '',
        notes: json['notes'] ?? '',
        imagePath: json['imagePath'] ?? '',
      );
}

class FishSocialScreen extends StatefulWidget {
  final String lakeKey;
  const FishSocialScreen({Key? key, required this.lakeKey}) : super(key: key);

  @override
  _FishSocialScreenState createState() => _FishSocialScreenState();
}

class _FishSocialScreenState extends State<FishSocialScreen> {
  List<FishTrophy> _trophies = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTrophies();
  }

  @override
  void didUpdateWidget(covariant FishSocialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lakeKey != widget.lakeKey) {
      _loadTrophies();
    }
  }

  Future<void> _loadTrophies() async {
    final prefs = await SharedPreferences.getInstance();
    final String? trophiesJson = prefs.getString('trophies_${widget.lakeKey}');
    if (trophiesJson != null) {
      final List<dynamic> decoded = jsonDecode(trophiesJson);
      setState(() {
        _trophies = decoded.map((item) => FishTrophy.fromJson(item)).toList();
      });
    } else {
      setState(() { _trophies = []; });
    }
  }

  Future<void> _saveTrophies() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_trophies.map((t) => t.toJson()).toList());
    await prefs.setString('trophies_${widget.lakeKey}', encoded);
  }

  Future<String> _pickAndSaveImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'fish_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
        return localImage.path;
      }
    } catch (e) {
      debugPrint('Ошибка выбора фото: $e');
    }
    return '';
  }
  void _addTrophyDialog() {
    final weightCtrl = TextEditingController();
    final baitCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String fishType = 'Карп';
    String imagePath = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2E3B1E),
          title: const Text('Записать трофей в соцсеть 🏆', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    String path = await _pickAndSaveImage();
                    if (path.isNotEmpty) {
                      setDialogState(() { imagePath = path; });
                    }
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC5E1A5), width: 2),
                    ),
                    child: imagePath.isEmpty
                        ? const Icon(Icons.add_a_photo, color: Colors.white, size: 28)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: Image.file(File(imagePath), width: 90, height: 90, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Нажмите, чтобы загрузить фото', style: TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF2E3B1E),
                  value: fishType,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: <String>['Карп', 'Амур', 'Толстолобик'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) { setDialogState(() { fishType = newValue!; }); },
                ),
                TextField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Сколько кг', labelStyle: TextStyle(color: Colors.white60))),
                TextField(controller: baitCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'На что поймался (насадка)', labelStyle: TextStyle(color: Colors.white60))),
                TextField(controller: notesCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Заметка (время, погода)', labelStyle: TextStyle(color: Colors.white60))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
              onPressed: () {
                double w = double.tryParse(weightCtrl.text) ?? 0.0;
                if (w > 0) {
                  final now = DateTime.now();
                  String timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
                  setState(() {
                    _trophies.add(FishTrophy(
                      id: now.millisecondsSinceEpoch.toString(),
                      fishType: fishType,
                      weight: w,
                      dateTime: timeStr,
                      bait: baitCtrl.text.isEmpty ? 'Не указана' : baitCtrl.text,
                      notes: notesCtrl.text.isEmpty ? 'Без заметок' : notesCtrl.text,
                      imagePath: imagePath,
                    ));
                  });
                  _saveTrophies();
                  Navigator.pop(context);
                }
              },
              child: const Text('Опубликовать', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewAndEditDetails(FishTrophy trophy, int index) {
    final notesEditCtrl = TextEditingController(text: trophy.notes);
    final baitEditCtrl = TextEditingController(text: trophy.bait);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E3B1E),
        title: Text('${trophy.fishType} — ${trophy.weight} кг', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trophy.imagePath.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(trophy.imagePath), width: 240, height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
              ],
              Text('Время поимки: ${trophy.dateTime}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(controller: baitEditCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Изменить насадку', labelStyle: TextStyle(color: Colors.white60))),
              TextField(controller: notesEditCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Изменить заметку', labelStyle: TextStyle(color: Colors.white60))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() { _trophies.removeAt(index); });
              _saveTrophies();
              Navigator.pop(context);
            },
            child: const Text('Удалить улов', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () {
              setState(() {
                trophy.bait = baitEditCtrl.text;
                trophy.notes = notesEditCtrl.text;
              });
              _saveTrophies();
              Navigator.pop(context);
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    _trophies.sort((a, b) => b.id.compareTo(a.id)); // Свежие уловы всегда сверху ленты

    return Scaffold(
      backgroundColor: const Color(0xFFA2B574), // Оливковый фон камуфляжа
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0, left: 14.0, right: 12.0, bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Рыболовная Лента', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2611))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _addTrophyDialog,
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text('Рыба', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _trophies.isEmpty
                  ? const Center(child: Text('Лента пуста. Нажмите "+ Рыба", чтобы выложить первый трофей!', style: TextStyle(color: Color(0xFF1B2611), fontSize: 13), textAlign: TextAlign.center))
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _trophies.length,
                      itemBuilder: (context, index) {
                        final trophy = _trophies[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: const Color(0xFFD4D9A1), // Песочно-оливковый контрастный цвет карточки
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF2E3B1E), width: 0.5)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A5D32),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF2E3B1E), width: 1.5),
                              ),
                              child: trophy.imagePath.isEmpty
                                  ? const Icon(Icons.phishing, color: Colors.white, size: 24)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(26),
                                      child: Image.file(File(trophy.imagePath), width: 52, height: 52, fit: BoxFit.cover),
                                    ),
                            ),
                            title: Text('${trophy.fishType} — ${trophy.weight} кг', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B2611), fontSize: 15)),
                            subtitle: Text('Насадка: ${trophy.bait}\nЗаметка: ${trophy.notes}', style: const TextStyle(color: Colors.black87, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF2E3B1E), size: 20),
                              onPressed: () => _viewAndEditDetails(trophy, index),
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
  }
}
 // ===================================================================
// ТАКТИЧЕСКИЙ ЦЕНТР ПИТАНИЯ CARPOUT: БАЗА ДАННЫХ И ХРАНИЛИЩЕ МИКСОВ
// ===================================================================
class BaitMix {
  String id; String liquid; String boilieType; String boilieSize; String notes;
  BaitMix({required this.id, required this.liquid, required this.boilieType, required this.boilieSize, required this.notes});
  Map<String, dynamic> toJson() => {'id': id, 'liquid': liquid, 'boilieType': boilieType, 'boilieSize': boilieSize, 'notes': notes};
  factory BaitMix.fromJson(Map<String, dynamic> json) => BaitMix(id: json['id'] ?? '', liquid: json['liquid'] ?? '', boilieType: json['boilieType'] ?? '', boilieSize: json['boilieSize'] ?? '', notes: json['notes'] ?? '');
}

class PvaStickLog {
  String id; String pvaType; String hookBait; String rodType; String time;
  PvaStickLog({required this.id, required this.pvaType, required this.hookBait, required this.rodType, required this.time});
  Map<String, dynamic> toJson() => {'id': id, 'pvaType': pvaType, 'hookBait': hookBait, 'rodType': rodType, 'time': time};
  factory PvaStickLog.fromJson(Map<String, dynamic> json) => PvaStickLog(id: json['id'] ?? '', pvaType: json['pvaType'] ?? '', hookBait: json['hookBait'] ?? '', rodType: json['rodType'] ?? '', time: json['time'] ?? '');
}

class CarpFeedScreen extends StatefulWidget {
  final String lakeKey;
  const CarpFeedScreen({Key? key, required this.lakeKey}) : super(key: key);
  @override
  _CarpFeedScreenState createState() => _CarpFeedScreenState();
}

class _CarpFeedScreenState extends State<CarpFeedScreen> with TickerProviderStateMixin {
  List<BaitMix> _mixes = [];
  List<PvaStickLog> _sticks = [];
  late TabController _tabController;

  int _timerSeconds = 2400; 
  int _currentCountdown = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFeedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mixJson = prefs.getString('feed_mixes_${widget.lakeKey}');
    final String? stickJson = prefs.getString('feed_sticks_${widget.lakeKey}');
    setState(() {
      if (mixJson != null) { _mixes = (jsonDecode(mixJson) as List).map((i) => BaitMix.fromJson(i)).toList(); } else { _mixes = []; }
      if (stickJson != null) { _sticks = (jsonDecode(stickJson) as List).map((i) => PvaStickLog.fromJson(i)).toList(); } else { _sticks = []; }
    });
  }

  Future<void> _saveFeedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('feed_mixes_${widget.lakeKey}', jsonEncode(_mixes.map((m) => m.toJson()).toList()));
    await prefs.setString('feed_sticks_${widget.lakeKey}', jsonEncode(_sticks.map((s) => s.toJson()).toList()));
  }

  void _addMixDialog() {
    String liquid = '🍓 Клубничный Ликвид';
    String boilieType = 'Вареные бойлы';
    String boilieSize = 'Крушеные бойлы';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B2611),
          title: const Text('Записать Сподовый Микс 🪣', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: liquid, isExpanded: true, style: const TextStyle(color: Colors.white),
                  items: <String>['🍓 Клубничный Ликвид', '🍍 Ананасовый Амино', '🧄 Чесночный CSL', '🦀 Криль Натурал', '🚫 Без ликвида'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { setDialogState(() { liquid = v!; }); },
                ),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: boilieType, isExpanded: true, style: const TextStyle(color: Colors.white),
                  items: <String>['Вареные бойлы', 'Растворимые бойлы', 'Пеллетс жирный', 'Зерновой микс'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { setDialogState(() { boilieType = v!; }); },
                ),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: boilieSize, isExpanded: true, style: const TextStyle(color: Colors.white),
                  items: <String>['Целые бойлы', 'Резаные (половинки)', 'Крушеные бойлы', 'Микс фракций'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { setDialogState(() { boilieSize = v!; }); },
                ),
                TextField(controller: notesCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Заметка (кол-во спомбов)', labelStyle: TextStyle(color: Colors.white60))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
              onPressed: () {
                setState(() {
                  _mixes.add(BaitMix(id: DateTime.now().millisecondsSinceEpoch.toString(), liquid: liquid, boilieType: boilieType, boilieSize: boilieSize, notes: notesCtrl.text.isEmpty ? 'Плановое кормление' : notesCtrl.text));
                });
                _saveFeedData();
                Navigator.pop(context);
              },
              child: const Text('Всыпать', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _addStickDialog() {
    String pvaType = 'Сетка ПВА-стик';
    String hookBait = 'Pop-up 10мм (Плавающий)';
    String rodType = 'Рабочее №1';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B2611),
          title: const Text('Заброс поискового удилища 🎯', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: pvaType, isExpanded: true, style: const TextStyle(color: Colors.white),
                  items: <String>['Сетка ПВА-стик', 'ПВА-пакет (с пеллетсом)', '🚫 Без ПВА (одиночная)'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { setDialogState(() { pvaType = v!; }); },
                ),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: hookBait, isExpanded: true, style: const TextStyle(color: Colors.white),
                  items: <String>['Pop-up 10мм (Плавающий)', 'Wafters (Сбалансированный)', 'Искусственная кукуруза', 'Двойной тонущий 20мм'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { setDialogState(() { hookBait = v!; }); },
                ),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: rodType, isExpanded: true, style: const TextStyle(color: Colors.white),
                  items: <String>['Рабочее №1', 'Рабочее №2', 'Рабочее №3', 'Маркерное / Поиск'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { setDialogState(() { rodType = v!; }); },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
              onPressed: () {
                final now = DateTime.now();
                setState(() {
                  _sticks.add(PvaStickLog(id: now.millisecondsSinceEpoch.toString(), pvaType: pvaType, hookBait: hookBait, rodType: rodType, time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}'));
                });
                _saveFeedData();
                Navigator.pop(context);
              },
              child: const Text('В точку!', style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2611),
        title: const Text('Тактика Питания & Тайминг', style: TextStyle(color: Color(0xFFD4D9A1), fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4D9A1),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFFD4D9A1),
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Миксы'),
            Tab(icon: Icon(Icons.gpp_good), text: 'Стики'),
            Tab(icon: Icon(Icons.timer), text: 'Таймер'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ВКЛАДКА 1: МИКСЫ КОРМЛЕНИЯ ХАКИ
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('История кормления сектора:', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold, fontSize: 13)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611), side: const BorderSide(color: Color(0xFFD4D9A1), width: 1)),
                      onPressed: _addMixDialog,
                      icon: const Icon(Icons.add, color: Color(0xFFD4D9A1), size: 16),
                      label: const Text('Корм', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _mixes.isEmpty
                      ? const Center(child: Text('Сводка пуста. Запишите первый закорм!', style: TextStyle(color: Colors.white38, fontSize: 13)))
                      : ListView.builder(
                          itemCount: _mixes.length,
                          itemBuilder: (context, idx) {
                            final m = _mixes[_mixes.length - 1 - idx];
                            return Card(
                              color: const Color(0xFF1B2611),
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: const Color(0xFFD4D9A1).withOpacity(0.2))),
                              child: ListTile(
                                leading: const Icon(Icons.opacity, color: Color(0xFFC5E1A5)),
                                title: Text(m.liquid, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('База: ${m.boilieType} (${m.boilieSize})\nИнфо: ${m.notes}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                  onPressed: () { setState(() { _mixes.remove(m); }); _saveFeedData(); },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ВКЛАДКА 2: ЖУРНАЛ АКТИВНЫХ ПВА-СТИКОВ
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Активные насадки в точках:', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold, fontSize: 13)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611), side: const BorderSide(color: Color(0xFFD4D9A1), width: 1)),
                      onPressed: _addStickDialog,
                      icon: const Icon(Icons.gps_fixed, color: Color(0xFFD4D9A1), size: 16),
                      label: const Text('Заброс', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _sticks.isEmpty
                      ? const Center(child: Text('Нет зафиксированных забросов', style: TextStyle(color: Colors.white38, fontSize: 13)))
                      : ListView.builder(
                          itemCount: _sticks.length,
                          itemBuilder: (context, idx) {
                            final s = _sticks[_sticks.length - 1 - idx];
                            return Card(
                              color: const Color(0xFF1B2611),
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: const Color(0xFFD4D9A1).withOpacity(0.2))),
                              child: ListTile(
                                leading: const Icon(Icons.track_changes, color: Color(0xFFFF5252)),
                                title: Text('${s.rodType} [${s.time}]', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('ПВА: ${s.pvaType}\nПрезентация: ${s.hookBait}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                  onPressed: () { setState(() { _sticks.remove(s); }); _saveFeedData(); },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // ВКЛАДКА 3: КРУГЛОЙ ТАЙМЕР ПЕРЕЗАБРОСА ХАКИ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ТАЙМЕР ОБНОВЛЕНИЯ ТОЧЕК', style: TextStyle(color: Color(0xFFD4D9A1), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 24),
                Container(
                  width: 190, height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2611),
                    shape: BoxShape.circle,
                    border: Border.all(color: _isTimerRunning ? const Color(0xFFD4D9A1) : Colors.white24, width: 4),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isTimerRunning 
                              ? '${(_currentCountdown ~/ 60)}:${(_currentCountdown % 60).toString().padLeft(2, '0')}'
                              : '${(_timerSeconds ~/ 60)}:00',
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _isTimerRunning ? const Color(0xFFD4D9A1) : Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(_isTimerRunning ? 'ИДЕТ ОТСЧЕТ' : 'ОЖИДАНИЕ', style: TextStyle(color: _isTimerRunning ? const Color(0xFFC5E1A5) : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimerPresetAction(2400, '40 мин'),
                    const SizedBox(width: 8),
                    _buildTimerPresetAction(3600, '1 час'),
                    const SizedBox(width: 8),
                    _buildTimerPresetAction(7200, '2 часа'),
                  ],
                ),
                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130, height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _isTimerRunning ? Colors.orange.shade900 : const Color(0xFF4A5D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          if (_isTimerRunning) {
                            setState(() { _isTimerRunning = false; });
                          } else {
                            setState(() {
                              _isTimerRunning = true;
                              _currentCountdown = _timerSeconds;
                            });
                            _startCountdownLoop();
                          }
                        },
                        child: Text(_isTimerRunning ? 'Пауза' : 'Старт', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130, height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () { setState(() { _isTimerRunning = false; _currentCountdown = 0; }); },
                        child: const Text('Сброс', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerPresetAction(int secs, String label) {
    bool isSelected = _timerSeconds == secs;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
      selected: isSelected, selectedColor: const Color(0xFFD4D9A1), backgroundColor: const Color(0xFF1B2611),
      onSelected: (b) { if (b) { setState(() { _timerSeconds = secs; if (_isTimerRunning) _currentCountdown = secs; }); } },
    );
  }

  void _startCountdownLoop() async {
    while (_isTimerRunning && _currentCountdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isTimerRunning) return;
      setState(() {
        _currentCountdown--;
        if (_currentCountdown <= 0) {
          _isTimerRunning = false;
          _showTimerAlert();
        }
      });
    }
  }

  void _showTimerAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFF5252),
        title: const Text('ВРЕМЯ ПЕРЕЗАБРОСА! ⏱️🔥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Стик растворился, насадка отработала время в точке. Пора обновить оснастку!', style: TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Принято', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
