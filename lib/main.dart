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
        scaffoldBackgroundColor: const Color(0xFFF4F6F0), 
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

  List<String> _lakesList = ['Озеро Trophy', 'Медвежка', 'Дикое озеро'];
  String _selectedLake = 'Озеро Trophy';
  String _sectorName = 'Сектор №4';
  String _sessionDuration = '48';
  
  int _catchesCount = 8;
  double _totalWeight = 78.400;
  String _bigFishWeight = '16.800';

  List<String> _markerNames = ['Дальняя бровка (ракушка)', 'Ближнее плато (ил)'];

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
        backgroundColor: const Color(0xFF2E3B1E),
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
            onPressed: () {
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
        duration: _sessionDuration,
        catches: _catchesCount,
        weight: _totalWeight,
        bigFish: _bigFishWeight,
        availableMarkers: _markerNames,
        onUpdateSession: (newLake, newSector, newDuration) {
          setState(() {
            _sectorName = newSector;
            _sessionDuration = newDuration;
          });
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
      const Center(child: Text('Экран: Журнал прикормки', style: TextStyle(fontSize: 18, color: Color(0xFF2E3B1E)))),
    ];
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF2E3B1E),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1B2611)),
              accountName: const Text('CarpOut Менеджер', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              accountEmail: const Text('Локальные сессии рыбалки', style: TextStyle(color: Colors.white60)),
              currentAccountPicture: const CircleAvatar(backgroundColor: Color(0xFF4A5D32), child: Icon(Icons.phishing, color: Colors.white, size: 36)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('СПИСОК ВОДОЕМОВ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFC5E1A5))),
                  IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFC5E1A5)), onPressed: _addNewLakeDialog),
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
                    data: ThemeData(unselectedWidgetColor: Colors.white70, hintColor: const Color(0xFFC5E1A5)),
                    child: ExpansionTile(
                      leading: Icon(Icons.water, color: isCurrent ? const Color(0xFFC5E1A5) : Colors.white70),
                      title: Text(lakeItem, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrent) const Icon(Icons.check_circle, color: Color(0xFFC5E1A5), size: 20),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              if (_lakesList.length > 1) {
                                setState(() {
                                  _lakesList.remove(lakeItem);
                                  if (isCurrent) _selectedLake = _lakesList.first;
                                });
                                _saveAllAppData();
                                _loadAllAppData();
                              }
                            },
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF4A5D32), borderRadius: BorderRadius.circular(12)),
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
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
                                onPressed: () {
                                  setState(() {
                                    _selectedLake = lakeItem;
                                    _sectorName = sectorCtrl.text;
                                    _sessionDuration = durationCtrl.text;
                                  });
                                  _saveAllAppData();
                                  _loadAllAppData();
                                  Navigator.pop(context);
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
// ЧАСТЬ 2А: РЕАЛИЗАЦИЯ ДАШБОРДА (ЛОГИКА И УМНАЯ ФОРМА УЛОВА "В ПОДСАКЕ!")
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
                const Text('Выберите вид рыбы:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedFish,
                  isExpanded: true,
                  items: <String>['Карп', 'Амур', 'Толстолобик'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) { setDialogState(() { selectedFish = newValue!; }); },
                ),
                const SizedBox(height: 12),
                const Text('Точка поимки:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedPoint,
                  isExpanded: true,
                  items: (availableMarkers.isNotEmpty ? availableMarkers : ['Не указана']).map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) { setDialogState(() { selectedPoint = newValue!; }); },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Вес рыбы (кг)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  if (inputWeight > currentBig) { newBigString = inputWeight.toStringAsFixed(3); }
                  onUpdateStats(newCatches, newTotalWeight, newBigString);
                  Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF4F6F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.menu, color: Color(0xFF2E3B1E)), onPressed: () => Scaffold.of(context).openDrawer()),
                const Text('CarpOut App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2E3B1E), Color(0xFF4A5D32)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getCurrentDate(), style: const TextStyle(color: Color(0xFFC5E1A5), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('ТЕКУЩАЯ СЕССИЯ - ДЛИТЕЛЬНОСТЬ $duration Ч.', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(lake, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(sector, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                _buildStatCard('BIG FISH 🔥', '$bigFish кг', Icons.emoji_events, Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => _showInTheNetDialog(context),
                icon: const Icon(Icons.phishing, color: Colors.white),
                label: const Text('В подсаке! 🎣', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 6), Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
        ],
      ),
    );
  }
}
// ===================================================================
// ЧАСТЬ 3А: ИНТЕРАКТИВНЫЙ СЕКТОРНЫЙ РАДАР С МАРКЕРАМИ ДНА CARPOUT
// ===================================================================
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
  String _selectedBottomType = '🐚 Ракушка'; // Дефолтный тип дна

  @override
  void initState() {
    super.initState();
    _loadMarkerPoints();
  }

  @override
  void didUpdateWidget(covariant MarkerMapScreen oldWidget) {
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
          MarkerPoint(name: 'Дальняя бровка', distance: 95.0, depth: 3.5, bottomType: '🐚 Ракушка'),
          MarkerPoint(name: 'Русловой свал', distance: 65.0, depth: 2.1, bottomType: '🍃 Ил'),
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

  // Быстрое добавление точки кликом по интерактивному радару
  void _addPointFromRadar(double tappedDistance) {
    _nameController.clear();
    _distanceController.text = tappedDistance.toStringAsFixed(1);
    _depthController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2E3B1E),
          title: const Text('Засечь точку на карте 🎯', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Ориентир / Название', labelStyle: TextStyle(color: Colors.white60)),
                ),
                TextField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Дистанция (метры)', labelStyle: TextStyle(color: Colors.white60)),
                ),
                TextField(
                  controller: _depthController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Глубина (метры)', labelStyle: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Маркер структуры дна:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF2E3B1E),
                  value: _selectedBottomType,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: <String>['🐚 Ракушка', '🍃 Ил', '🪨 Камни', '🪵 Коряга', '🏖️ Песок'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setDialogState(() {
                      _selectedBottomType = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
              onPressed: () {
                if (_nameController.text.isNotEmpty && _distanceController.text.isNotEmpty) {
                  setState(() {
                    _points.add(MarkerPoint(
                      name: _nameController.text,
                      distance: double.tryParse(_distanceController.text) ?? tappedDistance,
                      depth: double.tryParse(_depthController.text) ?? 0.0,
                      bottomType: _selectedBottomType,
                    ));
                  });
                  _saveMarkerPoints();
                  Navigator.pop(context);
                }
              },
              child: const Text('Вшить в сектор', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPointDialog(MarkerPoint point, int index) {
    final editNameCtrl = TextEditingController(text: point.name);
    final editDistCtrl = TextEditingController(text: point.distance.toString());
    final editDepthCtrl = TextEditingController(text: point.depth.toString());
    String editBottom = point.bottomType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Управление точкой', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editNameCtrl, decoration: const InputDecoration(labelText: 'Ориентир')),
            TextField(controller: editDistCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Дистанция (м)')),
            TextField(controller: editDepthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Глубина (м)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() { _points.removeAt(index); });
              _saveMarkerPoints();
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E)),
            onPressed: () {
              setState(() {
                point.name = editNameCtrl.text;
                point.distance = double.tryParse(editDistCtrl.text) ?? point.distance;
                point.depth = double.tryParse(editDepthCtrl.text) ?? point.depth;
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
  @override
  Widget build(BuildContext context) {
    _points.sort((a, b) => b.distance.compareTo(a.distance));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: Column(
        children: [
          // ИНТЕРАКТИВНАЯ КАРТА-РАДАР ПРЯМО НА ЭКРАНЕ С ЗУМОМ
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.only(top: 40, left: 12, right: 12, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(40),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: GestureDetector(
                    onTapUp: (details) {
                      double boxHeight = 400.0;
                      double clickY = details.localPosition.dy;
                      if (clickY > 0 && clickY < boxHeight) {
                        double calculatedDist = 55.0 + ((boxHeight - clickY) / boxHeight) * 105.0;
                        if (calculatedDist >= 55 && calculatedDist <= 160) {
                          _addPointFromRadar(calculatedDist);
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: CustomPaint(
                        painter: CarpOutRadarPainter(savedPoints: _points),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // ТЕКСТОВЫЙ СПИСОК МАРКЕРНЫХ КАРТОЧЕК С ФЛАЖКАМИ ДНА
          Expanded(
            flex: 4,
            child: _points.isEmpty
                ? const Center(child: Text('Нажмите на сетку радара, чтобы засечь точку.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _points.length,
                    itemBuilder: (context, index) {
                      final point = _points[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          dense: true,
                          onTap: () => _showEditPointDialog(point, index),
                          leading: const Icon(Icons.location_on, color: Color(0xFF2E3B1E)),
                          title: Text(point.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                          subtitle: Text('Дно: ${point.bottomType}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          trailing: Text('${point.distance.toStringAsFixed(1)} м / Гл: ${point.depth} м', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CarpOutRadarPainter extends CustomPainter {
  final List<MarkerPoint> savedPoints;
  CarpOutRadarPainter({required this.savedPoints});

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

    final textPaint = TextStyle(color: const Color(0xFF2E3B1E).withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold);
    const logoPaint = TextStyle(color: Color(0xFF2E3B1E), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2);

    double centerX = size.width / 2;
    double bottomY = size.height - 30;

    for (int angle = -40; angle <= 40; angle += 10) {
      double rad = (angle - 90) * 3.141592653589793 / 180;
      double radiusLength = size.height - 60;
      double endX = centerX + radiusLength * _cos(rad);
      double endY = bottomY + radiusLength * _sin(rad);
      canvas.drawLine(Offset(centerX, bottomY), Offset(endX, endY), (angle % 20 == 0) ? mainPaint : dashPaint);
    }

    for (int d = 60; d <= 150; d += 30) {
      double radius = (d - 50) * (size.height - 80) / 110;
      Rect rect = Rect.fromCircle(center: Offset(centerX, bottomY), radius: radius);
      canvas.drawArc(rect, 3.14159 + 0.5, 3.14159 - 1.0, false, mainPaint);

      final textPainter = TextPainter(text: TextSpan(text: '$dм', style: textPaint), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, bottomY - radius - 12));
    }

    final logoPainter = TextPainter(text: const TextSpan(text: 'CARPOUT', style: logoPaint), textDirection: TextDirection.ltr)..layout();
    logoPainter.paint(canvas, Offset(centerX - logoPainter.width / 2, bottomY - (size.height / 2)));
  }

  double _sin(double rad) {
    double x = rad; double t = x; double sum = x;
    for (int i = 1; i <= 5; i++) { t = -t * x * x / ((2 * i) * (2 * i + 1)); sum += t; }
    return sum;
  }

  double _cos(double rad) {
    double x = rad; double t = 1.0; double sum = 1.0;
    for (int i = 1; i <= 5; i++) { t = -t * x * x / ((2 * i - 1) * (2 * i)); sum += t; }
    return sum;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MarkerPoint {
  String name; double distance; double depth; String bottomType;
  MarkerPoint({required this.name, required this.distance, required this.depth, required this.bottomType});
  Map<String, dynamic> toJson() => {'name': name, 'distance': distance, 'depth': depth, 'bottomType': bottomType};
  factory MarkerPoint.fromJson(Map<String, dynamic> json) => MarkerPoint(
    name: json['name'] ?? '',
    distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
    bottomType: json['bottomType'] ?? '',
  );
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
      backgroundColor: const Color(0xFFF4F6F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Калькулятор дистанции', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
            const SizedBox(height: 16),
            const Text('База между колышками:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(children: [_buildDistanceChip(3.0, '3 м'), const SizedBox(width: 8), _buildDistanceChip(4.0, '4 м (Стандарт)'), const SizedBox(width: 8), _buildDistanceChip(5.0, '5 м')]),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Из метров в обороты', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Дистанция ловли (метры)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.straighten, color: Color(0xFF2E3B1E))),
                    onChanged: (_) { _turnsController.clear(); _metersResult = 0.0; _calculateFromMeters(); },
                  ),
                  if (_turnsResult > 0) ...[const SizedBox(height: 16), Center(child: Column(children: [Text(_turnsResult.toStringAsFixed(2), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))), const Text('оборотов на колышках', style: TextStyle(color: Colors.grey, fontSize: 12))]))]
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2E3B1E).withOpacity(0.15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. Из оборотов в метров (Обратный счет)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _turnsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Количество оборотов на колышках', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.refresh, color: Color(0xFF2E3B1E))),
                    onChanged: (_) { _distanceController.clear(); _turnsResult = 0.0; _calculateFromTurns(); },
                  ),
                  if (_metersResult > 0) ...[const SizedBox(height: 16), Center(child: Column(children: [Text('${_metersResult.toStringAsFixed(1)} м', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2E3B1E))), const Text('дистанция до точки ловли', style: TextStyle(color: Colors.grey, fontSize: 12))]))]
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
