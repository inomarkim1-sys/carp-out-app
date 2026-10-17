import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF2E3B1E),
          secondary: const Color(0xFF4A5D32),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Общие данные сессии
  String _lakeName = 'Озеро Трофейное';
  String _sectorName = 'Сектор №4';
  int _catchesCount = 8;
  double _totalWeight = 78.400;
  String _bigFishWeight = '16.800';

  // Список маркерных точек (нужен здесь, чтобы передавать его в калькулятор поимок)
  List<String> _markerNames = ['Дальняя бровка (ракушка)', 'Ближнее плато (ил)'];

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lakeName = prefs.getString('lakeName') ?? 'Озеро Трофейное';
      _sectorName = prefs.getString('sectorName') ?? 'Сектор №4';
      _catchesCount = prefs.getInt('catchesCount') ?? 8;
      _totalWeight = prefs.getDouble('totalWeight') ?? 78.400;
      _bigFishWeight = prefs.getString('bigFishWeight') ?? '16.800';
      
      // Подгружаем список точек
      final String? pointsJson = prefs.getString('markerPoints');
      if (pointsJson != null) {
        final List<dynamic> decoded = jsonDecode(pointsJson);
        _markerNames = decoded.map((item) => (item['name'] as String)).toList();
      }
    });
  }

  Future<void> _saveSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lakeName', _lakeName);
    await prefs.setString('sectorName', _sectorName);
    await prefs.setInt('catchesCount', _catchesCount);
    await prefs.setDouble('totalWeight', _totalWeight);
    await prefs.setString('bigFishWeight', _bigFishWeight);
  }

  // Обновление списка доступных точек из вкладки Маркер
  void _updateAvailableMarkers(List<String> newNames) {
    setState(() {
      _markerNames = newNames;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      CarpOutDashboard(
        lake: _lakeName,
        sector: _sectorName,
        catches: _catchesCount,
        weight: _totalWeight,
        bigFish: _bigFishWeight,
        availableMarkers: _markerNames, // Передаем точки на главный экран!
        onUpdateSession: (newLake, newSector) {
          setState(() {
            _lakeName = newLake;
            _sectorName = newSector;
          });
          _saveSessionData();
        },
        onUpdateStats: (newCatches, newWeight, newBig) {
          setState(() {
            _catchesCount = newCatches;
            _totalWeight = newWeight;
            _bigFishWeight = newBig;
          });
          _saveSessionData();
        },
      ), 
      MarkerMapScreen(onMarkersChanged: _updateAvailableMarkers), // Вкладка 2
      const CarpClipsCalculator(), // Вкладка 3
      const Center(child: Text('Экран: Журнал прикормки (В разработке)', style: TextStyle(fontSize: 18, color: Color(0xFF2E3B1E)))), 
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomBottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: const Color(0xFFC5E1A5),
        unselectedItemColor: Colors.white60,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          _loadSessionData(); // Обновляем список точек при переключении вкладок
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Инфо'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Маркер'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Клипса'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Корм'),
        ],
      ),
    );
  }
}

// ===================================================================
// ЧАСТЬ 3А: МОДЕЛЬ МАРКЕРНЫХ ТОЧЕК И ИХ ЛОКАЛЬНАЯ ХАКИ-ПАМЯТЬ
// ===================================================================
class MarkerPoint {
  String name;
  double distance;
  double depth;
  String bottomType;

  MarkerPoint({
    required this.name,
    required this.distance,
    required this.depth,
    required this.bottomType,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'distance': distance,
        'depth': depth,
        'bottomType': bottomType,
      };

  factory MarkerPoint.fromJson(Map<String, dynamic> json) => MarkerPoint(
        name: json['name'] ?? '',
        distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
        depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
        bottomType: json['bottomType'] ?? '',
      );
}

class MarkerMapScreen extends StatefulWidget {
  final Function(List<String>) onMarkersChanged;
  const MarkerMapScreen({Key? key, required this.onMarkersChanged}) : super(key: key);

  @override
  _MarkerMapScreenState createState() => _MarkerMapScreenState();
}

class _MarkerMapScreenState extends State<MarkerMapScreen> {
  List<MarkerPoint> _points = [];

  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _depthController = TextEditingController();
  final _bottomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMarkerPoints();
  }

  Future<void> _loadMarkerPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pointsJson = prefs.getString('markerPoints');
    if (pointsJson != null) {
      final List<dynamic> decoded = jsonDecode(pointsJson);
      setState(() {
        _points = decoded.map((item) => MarkerPoint.fromJson(item)).toList();
      });
      _notifyParent();
    } else {
      setState(() {
        _points = [
          MarkerPoint(name: 'Дальняя бровка (ракушка)', distance: 94.0, depth: 3.5, bottomType: 'Твердое / Ракушка'),
          MarkerPoint(name: 'Ближнее плато (ил)', distance: 62.0, depth: 2.1, bottomType: 'Глубокий ил'),
        ];
      });
      _saveMarkerPoints();
    }
  }

  Future<void> _saveMarkerPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_points.map((p) => p.toJson()).toList());
    await prefs.setString('markerPoints', encoded);
    _notifyParent();
  }

  void _notifyParent() {
    List<String> names = _points.map((p) => p.name).toList();
    widget.onMarkersChanged(names);
  }

  void _addNewPointDialog() {
    _nameController.clear();
    _distanceController.clear();
    _depthController.clear();
    _bottomController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая маркерная точка', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Название / Ориентир')),
              TextField(controller: _distanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Дистанция (метры)')),
              TextField(controller: _depthController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Глубина (метры)')),
              TextField(controller: _bottomController, decoration: const InputDecoration(labelText: 'Структура дна (ракушка, ил...)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
            onPressed: () {
              if (_nameController.text.isNotEmpty && _distanceController.text.isNotEmpty) {
                setState(() {
                  _points.add(MarkerPoint(
                    name: _nameController.text,
                    distance: double.tryParse(_distanceController.text) ?? 0.0,
                    depth: double.tryParse(_depthController.text) ?? 0.0,
                    bottomType: _bottomController.text.isEmpty ? 'Не указано' : _bottomController.text,
                  ));
                });
                _saveMarkerPoints();
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPointDialog(MarkerPoint point, int index) {
    final editNameController = TextEditingController(text: point.name);
    final editDistanceController = TextEditingController(text: point.distance.toString());
    final editDepthController = TextEditingController(text: point.depth.toString());
    final editBottomController = TextEditingController(text: point.bottomType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать точку', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: editNameController, decoration: const InputDecoration(labelText: 'Название / Ориентир')),
              TextField(controller: editDistanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Дистанция (метры)')),
              TextField(controller: editDepthController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Глубина (метры)')),
              TextField(controller: editBottomController, decoration: const InputDecoration(labelText: 'Структура дна')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _points.removeAt(index);
              });
              _saveMarkerPoints();
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
            onPressed: () {
              setState(() {
                point.name = editNameController.text;
                point.distance = double.tryParse(editDistanceController.text) ?? point.distance;
                point.depth = double.tryParse(editDepthController.text) ?? point.depth;
                point.bottomType = editBottomController.text;
              });
              _saveMarkerPoints();
              Navigator.pop(context);
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
