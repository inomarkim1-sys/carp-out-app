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
      bottomNavigationBar: BottomNavigationBar(
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
// ЧАСТЬ 2А: ДАШБОРД С ИНТЕРФЕЙСОМ ФИКСАЦИИ ВИДОВ РЫБ И ТОЧЕК
// ===================================================================
class CarpOutDashboard extends StatelessWidget {
  final String lake;
  final String sector;
  final int catches;
  final double weight;
  final String bigFish;
  final List<String> availableMarkers;
  final Function(String, String) onUpdateSession;
  final Function(int, double, String) onUpdateStats;

  const CarpOutDashboard({
    Key? key,
    required this.lake,
    required this.sector,
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

  void _showEditSessionDialog(BuildContext context) {
    final lakeController = TextEditingController(text: lake);
    final sectorController = TextEditingController(text: sector);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать сессию', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: lakeController, decoration: const InputDecoration(labelText: 'Название водоема')),
            TextField(controller: sectorController, decoration: const InputDecoration(labelText: 'Номер сектора')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
            onPressed: () {
              onUpdateSession(lakeController.text, sectorController.text);
              Navigator.pop(context);
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInTheNetDialog(BuildContext context) {
    final weightController = TextEditingController();
    String selectedFish = 'Карп';
    String selectedPoint = availableMarkers.isNotEmpty ? availableMarkers.first : 'Не указана';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Рыба в подсаке! 🎣', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Выберите вид рыбы:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: selectedFish,
                  isExpanded: true,
                  items: <String>['Карп', 'Амур', 'Толстолобик'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setDialogState(() {
                      selectedFish = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Точка поимки:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: selectedPoint,
                  isExpanded: true,
                  items: (availableMarkers.isNotEmpty ? availableMarkers : ['Не указана']).map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setDialogState(() {
                      selectedPoint = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Вес рыбы (кг)',
                    hintText: 'Например, 12.350',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.scale, color: Color(0xFF2E3B1E)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
              onPressed: () {
                double inputWeight = double.tryParse(weightController.text) ?? 0.0;
                if (inputWeight > 0) {
                  int newCatches = catches + 1;
                  double newTotalWeight = weight + inputWeight;
                  
                  double currentBig = double.tryParse(bigFish) ?? 0.0;
                  String newBigString = bigFish;
                  if (inputWeight > currentBig) {
                    newBigString = inputWeight.toStringAsFixed(3);
                  }

                  onUpdateStats(newCatches, newTotalWeight, newBigString);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$selectedFish ($selectedPoint) весом ${inputWeight.toStringAsFixed(3)} кг добавлен!'),
                      backgroundColor: const Color(0xFF4A5D32),
                    ),
                  );
                }
              },
              child: const Text('В журнал!', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStatsDialog(BuildContext context) {
    final catchesController = TextEditingController(text: catches.toString());
    final weightController = TextEditingController(text: weight.toString());
    final bigController = TextEditingController(text: bigFish);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить аналитику улова', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: catchesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Всего хвостов (шт)')),
            TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Общий вес улова (кг)')),
            TextField(controller: bigController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вес BIG FISH (кг)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
            onPressed: () {
              int c = int.tryParse(catchesController.text) ?? catches;
              double w = double.tryParse(weightController.text) ?? weight;
              onUpdateStats(c, w, bigController.text);
              Navigator.pop(context);
            },
            child: const Text('Обновить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    double averageWeight = catches > 0 ? weight / catches : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E3B1E), Color(0xFF4A5D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getCurrentDate(), style: const TextStyle(color: Color(0xFFC5E1A5), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ТЕКУЩАЯ СЕССИЯ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                        onPressed: () => _showEditSessionDialog(context),
                      ),
                    ],
                  ),
                  Text(lake, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(sector, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.timer, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text('Длительность: 48 часов', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Аналитика улова:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showEditStatsDialog(context),
                  icon: const Icon(Icons.tune, size: 16, color: Color(0xFF4A5D32)),
                  label: const Text('Изменить', style: TextStyle(color: Color(0xFF4A5D32), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard('Всего хвостов', '$catches шт.', Icons.phishing, Colors.blue),
                _buildStatCard('Общий вес', '${weight.toStringAsFixed(3)} кг', Icons.scale, Colors.orange),
                _buildStatCard('Средний вес', '${averageWeight.toStringAsFixed(3)} кг', Icons.analytics, Colors.purple),
                _buildStatCard('BIG FISH 🔥', '$bigFish кг', Icons.emoji_events, Colors.red, isLongText: true),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3B1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                onPressed: () => _showInTheNetDialog(context),
                icon: const Icon(Icons.phishing, color: Colors.white, size: 24),
                label: const Text('В подсаке! 🎣', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isLongText = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: isLongText ? 13 : 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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

    void _showSectorMapDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Автономная сетка CarpOut', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF2E3B1E),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: Colors.grey.shade50,
          body: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(50),
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: Container(
                width: 400,
                height: 600,
                padding: const EdgeInsets.all(16),
                child: CustomPaint(
                  painter: CarpOutRadarPainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _points.sort((a, b) => b.distance.compareTo(a.distance));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Журнал промеров', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: _showSectorMapDialog,
                      icon: const Icon(Icons.grid_on, size: 14, color: Colors.blue),
                      label: const Text('Карта сектора', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3B1E), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _addNewPointDialog,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Точка', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _points.isEmpty
                  ? const Center(child: Text('Нет сохраненных точек. Нажмите "+ Точка", чтобы добавить.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _points.length,
                      itemBuilder: (context, index) {
                        final point = _points[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.grey)),
                          child: ListTile(
                            onTap: () => _showEditPointDialog(point, index),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                              child: const Icon(Icons.location_on, color: Color(0xFF2E3B1E)),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(point.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                const Icon(Icons.edit, size: 14, color: Colors.grey),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('Дно: ${point.bottomType}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${point.distance} м', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                                Text('Гл: ${point.depth} м', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
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
  }
}

class CarpOutRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final textPaint = TextStyle(color: Colors.grey.shade700, fontSize: 9);

    double centerX = size.width / 2;
    double bottomY = size.height - 20;

    for (int angle = -50; angle <= 50; angle += 5) {
      double rad = (angle - 90) * 3.141592653589793 / 180;
      double endX = centerX + (size.height - 40) * 0.9 * (angle % 10 == 0 ? 1 : 0.95); // симуляция косинуса
      double endY = bottomY - (size.height - 40) * 0.9 * (angle % 10 == 0 ? 1 : 0.95); // симуляция синуса
      canvas.drawLine(Offset(centerX, bottomY), Offset(centerX + (angle * 2), bottomY - (size.height - 60)), (angle % 10 == 0) ? linePaint : dashPaint);
    }

    for (int d = 55; d <= 160; d += 15) {
      double radius = (d - 50) * (size.height - 80) / 110;
      Rect rect = Rect.fromCircle(center: Offset(centerX, bottomY), radius: radius);
      canvas.drawArc(rect, 3.14159, 3.14159, false, (d % 30 == 0) ? linePaint : dashPaint);

      final textPainter = TextPainter(text: TextSpan(text: '$d', style: textPaint), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, bottomY - radius - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===================================================================
// ЧАСТЬ 4: ПОЛНОСТЬЮ ИНТЕРАКТИВНЫЙ МОДУЛЬ КАЛЬКУЛЯТОРА КЛИПСЫ (ХАКИ)
// ===================================================================
class CarpClipsCalculator extends StatefulWidget {
  const CarpClipsCalculator({Key? key}) : super(key: key);

  @override
  _CarpClipsCalculatorState createState() => _CarpClipsCalculatorState();
}

class _CarpClipsCalculatorState extends State<CarpClipsCalculator> {
  final TextEditingController _distanceController = TextEditingController();
  double _distanceBetweenSticks = 4.0; // Стандартная дистанция между колышками (4 метра)
  double _turnsResult = 0.0;

  void _calculateClips() {
    double distance = double.tryParse(_distanceController.text) ?? 0.0;
    if (distance > 0 && _distanceBetweenSticks > 0) {
      setState(() {
        _turnsResult = distance / _distanceBetweenSticks;
      });
    } else {
      setState(() {
        _turnsResult = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Перенос дистанции',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Введите параметры маркерного замера для расчета точного числа колышков.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Дистанция ловли (метры)',
                hintText: 'Например, 87',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.straighten, color: Color(0xFF2E3B1E)),
              ),
              onChanged: (_) => _calculateClips(),
            ),
            const SizedBox(height: 24),
            const Text(
              'База между колышками:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildDistanceChip(3.0, '3 м'),
                const SizedBox(width: 8),
                _buildDistanceChip(4.0, '4 м (Стандарт)'),
                const SizedBox(width: 8),
                _buildDistanceChip(5.0, '5 м'),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E3B1E), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'РЕЗУЛЬТАТ ДЛЯ КЛИПСОВАНИЯ:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _turnsResult.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'оборотов на колышках',
                    style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
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
      selected: isSelected,
      selectedColor: const Color(0xFF2E3B1E),
      backgroundColor: Colors.grey.shade100,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _distanceBetweenSticks = value;
            _calculateClips();
          });
        }
      },
    );
  }
}
