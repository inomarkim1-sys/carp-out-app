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
        // Настраиваем брутальные карповые оттенки Хаки для элементов
        primaryColor: const Color(0xFF2E3B1E),
        scaffoldBackgroundColor: const Color(0xFFF4F6F0), // Общий фон приложения теперь цвета Хаки/Оливы!
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

  // Список водоемов для бокового меню менеджера сессий
  List<String> _lakesList = ['Озеро Trophy', 'Медвежка', 'Дикое озеро'];
  String _selectedLake = 'Озеро Trophy';
  String _sectorName = 'Сектор №4';
  
  // Статистика уловов
  int _catchesCount = 8;
  double _totalWeight = 78.400;
  String _bigFishWeight = '16.800';

  // Список маркерных точек для выпадающих списков
  List<String> _markerNames = ['Дальняя бровка (ракушка)', 'Ближнее плато (ил)'];

  @override
  void initState() {
    super.initState();
    _loadAllAppData(); // Полная надежная загрузка из памяти при старте
  }

  // МЕТОД ЖЕСТКОГО И НАДЕЖНОГО СОХРАНЕНИЯ ВСЕЙ СЕССИИ
  Future<void> _loadAllAppData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLake = prefs.getString('currentLake') ?? 'Озеро Trophy';
      _sectorName = prefs.getString('sector_$_selectedLake') ?? 'Сектор №4';
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
    await prefs.setInt('catches_$_selectedLake', _catchesCount);
    await prefs.setDouble('weight_$_selectedLake', _totalWeight);
    await prefs.setString('big_$_selectedLake', _bigFishWeight);
  }

  void _updateMarkersList(List<String> newMarkers) {
    setState(() {
      _markerNames = newMarkers;
    });
  }

  // Добавление нового водоема через боковое меню шторки
  void _addNewLakeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить новый водоем', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Название озера/реки')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
            onPressed: () {
              if (controller.text.isNotEmpty && !_lakesList.contains(controller.text)) {
                setState(() {
                  _lakesList.add(controller.text);
                  _selectedLake = controller.text;
                  // Сбрасываем под новый водоем
                  _sectorName = 'Сектор №1';
                  _catchesCount = 0;
                  _totalWeight = 0.0;
                  _bigFishWeight = '0.000';
                  _markerNames = [];
                });
                _saveAllAppData();
                _loadAllAppData();
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
        catches: _catchesCount,
        weight: _totalWeight,
        bigFish: _bigFishWeight,
        availableMarkers: _markerNames,
        onUpdateSession: (newLake, newSector) {
          setState(() { _sectorName = newSector; });
          _saveAllAppData();
        },
        onUpdateStats: (newCatches, newWeight, newBig) {
          setState(() {
            _catchesCount = newCatches;
            _totalWeight = newWeight;
            _bigFishWeight = newBig;
          });
          _saveAllAppData();
        },
      ), 
      MarkerMapScreen(lakeKey: _selectedLake, onMarkersChanged: _updateMarkersList), 
      const CarpClipsCalculator(), 
      const Center(child: Text('Экран: Журнал прикормки (В разработке)', style: TextStyle(fontSize: 18, color: Color(0xFF2E3B1E)))), 
    ];

    return Scaffold(
      // НАШЕ БОКОВОЕ МЕНЮ (МЕНЕДЖЕР ВОДОЕМОВ)
      drawer: Drawer(
        backgroundColor: const Color(0xFFF4F6F0),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2E3B1E)),
              accountName: const Text('CarpOut Менеджер', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: const Text('Локальные сессии рыбалки', style: TextStyle(color: Colors.white60)),
              currentAccountPicture: CircleAvatar(backgroundColor: const Color(0xFF4A5D32), child: const Icon(Icons.phishing, color: Colors.white, size: 36)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('СПИСОК ВОДОЕМОВ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF4A5D32)), onPressed: _addNewLakeDialog),
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
                  return ListTile(
                    leading: Icon(Icons.water, color: isCurrent ? const Color(0xFF2E3B1E) : Colors.grey),
                    title: Text(lakeItem, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? const Color(0xFF2E3B1E) : Colors.black87)),
                    trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () {
                      setState(() { _selectedLake = lakeItem; });
                      _loadAllAppData();
                      Navigator.pop(context); // закрыть шторку меню
                    },
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
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: const Color(0xFFC5E1A5),
        unselectedItemColor: Colors.white60,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          _loadAllAppData();
          setState(() { _currentIndex = index; });
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
// ЧАСТЬ 2А: ДАШБОРД ХАКИ С МОДУЛЕМ "В ПОДСАКЕ!" И СВЯЗЬЮ С ТОЧКАМИ
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
    final sectorController = TextEditingController(text: sector);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать сессию', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sectorController, decoration: const InputDecoration(labelText: 'Номер сектора')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
            onPressed: () {
              onUpdateSession(lake, sectorController.text);
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
                  items: <String>['Карп', 'Амур', 'Tolstolobik'].map((String value) {
                    // Переименовываем отображение во Flutter для красоты интерфейса
                    String display = value == 'Tolstolobik' ? 'Толстолобик' : value;
                    return DropdownMenuItem<String>(value: value, child: Text(display));
                  }).toList(),
                  onChanged: (newValue) {
                    setDialogState(() { selectedFish = newValue!; });
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
                    setDialogState(() { selectedPoint = newValue!; });
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
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
                  
                  String displayFish = selectedFish == 'Tolstolobik' ? 'Толстолобик' : selectedFish;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$displayFish ($selectedPoint) весом ${inputWeight.toStringAsFixed(3)} кг добавлен!'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
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
      backgroundColor: const Color(0xFFF4F6F0), // Принудительный мягкий фон Хаки
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF2E3B1E), size: 28),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                const Text('CarpOut App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
              ],
            ),
            const SizedBox(height: 10),
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
                const Text('Аналитика улова:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
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
        color: Colors.white, // Контрастные карточки
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15)),
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
          Text(value, style: TextStyle(fontSize: isLongText ? 13 : 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E3B1E))),
        ],
      ),
    );
  }
}

// ===================================================================
// ЧАСТЬ 3А: МОДЕЛЬ МАРКЕРНЫХ ТОЧЕК И ИХ ЛОКАЛЬНАЯ ХАКИ-ПАМЯТЬ С ПРИВЯЗКОЙ К ОЗЕРАМ
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
  final String lakeKey;
  final Function(List<String>) onMarkersChanged;
  const MarkerMapScreen({Key? key, required this.lakeKey, required this.onMarkersChanged}) : super(key: key);

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

  @override
  void didUpdateWidget(covariant MarkerMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lakeKey != widget.lakeKey) {
      _loadMarkerPoints(); // Перезагружаем точки, если в боковом меню сменили водоем!
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
    await prefs.setString('markers_${widget.lakeKey}', encoded);
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
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
            title: const Text('Карта сектора CarpOut', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF2E3B1E),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: const Color(0xFFF4F6F0), // Фон хаки внутри карты
          body: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(50),
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Container(
                width: 380,
                height: 580,
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
      backgroundColor: const Color(0xFFF4F6F0), // Общий нежный фон Хаки
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
                    const Text('Журнал промеров', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
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
                          color: Colors.white, // Контрастные белые карточки точек
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
                                Expanded(child: Text(point.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E3B1E)))),
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

// КРАСИВЫЙ БРЕНДИРОВАННЫЙ ОТРИСОВЩИК ЛУЧЕВОЙ СЕТКИ СЕКТОРА
class CarpOutRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = const Color(0xFF2E3B1E) // Фирменные линии тёмного хаки
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFF4A5D32).withOpacity(0.4) // Мягкие вспомогательные лучи
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final textPaint = TextStyle(color: const Color(0xFF2E3B1E).withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold);
    
    // Стиль для нашего логотипа на карте
    const logoPaint = TextStyle(color: Color(0xFF2E3B1E), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2);

    double centerX = size.width / 2;
    double bottomY = size.height - 30;

    // 1. Отрисовка лучей (каждые 10 градусов основные, каждые 5 - пунктир)
    for (int angle = -50; angle <= 50; angle += 5) {
      double rad = (angle - 90) * 3.141592653589793 / 180;
      double radiusLength = size.height - 80;
      double endX = centerX + radiusLength * _cos(rad);
      double endY = bottomY + radiusLength * _sin(rad);
      canvas.drawLine(Offset(centerX, bottomY), Offset(endX, endY), (angle % 10 == 0) ? mainPaint : dashPaint);
    }

    // 2. Отрисовка дуг дистанций (от 55м до 160м)
    for (int d = 55; d <= 160; d += 15) {
      double radius = (d - 50) * (size.height - 100) / 110;
      Rect rect = Rect.fromCircle(center: Offset(centerX, bottomY), radius: radius);
      canvas.drawArc(rect, 3.14159 + 0.6, 3.14159 - 1.2, false, (d % 30 == 0) ? mainPaint : dashPaint);

      // Цифры дальности над каждой дугой
      final textPainter = TextPainter(text: TextSpan(text: '$d', style: textPaint), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, bottomY - radius - 12));
    }

    // 3. НАНЕСЕНИЕ НАШЕЙ НАДПИСИ CARPOUT ПО ЦЕНТРУ РАДАРА
   final logoPainter = TextPainter(text: TextSpan(text: 'CARPOUT', style: logoPaint), textDirection: TextDirection.ltr)..layout();
    logoPainter.paint(canvas, Offset(centerX - logoPainter.width / 2, bottomY - (size.height / 2)));
  }

  // Вспомогательные тригонометрические симуляции для CustomPainter во Flutter
  double _sin(double rad) {
    double x = rad;
    double t = x;
    double sum = x;
    for (int i = 1; i <= 5; i++) {
      t = -t * x * x / ((2 * i) * (2 * i + 1));
      sum += t;
    }
    return sum;
  }

  double _cos(double rad) {
    double x = rad;
    double t = 1.0;
    double sum = 1.0;
    for (int i = 1; i <= 5; i++) {
      t = -t * x * x / ((2 * i - 1) * (2 * i));
      sum += t;
    }
    return sum;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===================================================================
// ЧАСТЬ 4: ДВУХСТОРОННИЙ ИНТЕРАКТИВНЫЙ КАЛЬКУЛЯТОР КЛИПСЫ (ХАКИ)
// ===================================================================
class CarpClipsCalculator extends StatefulWidget {
  const CarpClipsCalculator({Key? key}) : super(key: key);

  @override
  _CarpClipsCalculatorState createState() => _CarpClipsCalculatorState();
}

class _CarpClipsCalculatorState extends State<CarpClipsCalculator> {
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _turnsController = TextEditingController();
  double _distanceBetweenSticks = 4.0; // Базовое расстояние между колышками

  double _turnsResult = 0.0;
  double _metersResult = 0.0;

  void _calculateFromMeters() {
    double distance = double.tryParse(_distanceController.text) ?? 0.0;
    if (distance > 0 && _distanceBetweenSticks > 0) {
      setState(() {
        _turnsResult = distance / _distanceBetweenSticks;
      });
    } else {
      setState(() { _turnsResult = 0.0; });
    }
  }

  void _calculateFromTurns() {
    double turns = double.tryParse(_turnsController.text) ?? 0.0;
    if (turns > 0 && _distanceBetweenSticks > 0) {
      setState(() {
        _metersResult = turns * _distanceBetweenSticks;
      });
    } else {
      setState(() { _metersResult = 0.0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0), // Мягкий фон Хаки
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Калькулятор дистанции',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E)),
            ),
            const SizedBox(height: 16),
            
            // ВЫБОР БАЗЫ КОЛЫШКОВ
            const Text(
              'База между колышками:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDistanceChip(3.0, '3 м'),
                const SizedBox(width: 8),
                _buildDistanceChip(4.0, '4 м (Стандарт)'),
                const SizedBox(width: 8),
                _buildDistanceChip(5.0, '5 м'),
              ],
            ),
            const SizedBox(height: 24),

            // БЛОК ПРЯМОГО РАСЧЕТА: МЕТРЫ -> ОБОРОТЫ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Из метров в обороты', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Дистанция ловли (метры)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.straighten, color: Color(0xFF2E3B1E)),
                    ),
                    onChanged: (_) {
                      _turnsController.clear();
                      _metersResult = 0.0;
                      _calculateFromMeters();
                    },
                  ),
                  if (_turnsResult > 0) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(_turnsResult.toStringAsFixed(2), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                          const Text('оборотов на колышках', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // БЛОК ОБРАТНОГО РАСЧЕТА: ОБОРОТЫ -> МЕТРЫ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Из оборотов в метры (Обратный счет)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _turnsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Количество оборотов на колышках',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.refresh, color: Color(0xFF2E3B1E)),
                    ),
                    onChanged: (_) {
                      _distanceController.clear();
                      _turnsResult = 0.0;
                      _calculateFromTurns();
                    },
                  ),
                  if (_metersResult > 0) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text('${_metersResult.toStringAsFixed(1)} м', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                          const Text('дистанция до точки ловли', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
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
      backgroundColor: Colors.white,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _distanceBetweenSticks = value;
            if (_distanceController.text.isNotEmpty) _calculateFromMeters();
            if (_turnsController.text.isNotEmpty) _calculateFromTurns();
          });
        }
      },
    );
  }
}
