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
