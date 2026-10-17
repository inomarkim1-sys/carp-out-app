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
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
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

  // Общие активные данные сессии для сохранения в память телефона
  String _lakeName = 'Озеро Trophy';
  String _sectorName = 'Сектор №4';
  int _catchesCount = 8;
  double _totalWeight = 78.400;
  String _bigFishWeight = '16.800';

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lakeName = prefs.getString('lakeName') ?? 'Озеро Trophy';
      _sectorName = prefs.getString('sectorName') ?? 'Сектор №4';
      _catchesCount = prefs.getInt('catchesCount') ?? 8;
      _totalWeight = prefs.getDouble('totalWeight') ?? 78.400;
      _bigFishWeight = prefs.getString('bigFishWeight') ?? '16.800';
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      CarpOutDashboard(
        lake: _lakeName,
        sector: _sectorName,
        catches: _catchesCount,
        weight: _totalWeight,
        bigFish: _bigFishWeight,
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
      const MarkerMapScreen(), // Вкладка 2: Маркерная карта
      const Center(child: Text('Экран: В подсаке! (В разработке)', style: TextStyle(fontSize: 18, color: Colors.green))), // Вкладка 3: «В подсаке!»
      const Center(child: Text('Экран: Журнал прикормки (В разработке)', style: TextStyle(fontSize: 18, color: Colors.green))), // Вкладка 4
      const CarpClipsCalculator(), // Вкладка 5: Сюда встанет наш живой Калькулятор клипс!
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
        selectedItemColor: Colors.lightGreenAccent.shade400,
        unselectedItemColor: Colors.white60,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Инфо'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Маркер'),
          BottomNavigationBarItem(icon: Icon(Icons.phishing), label: 'В подсаке!'), 
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Корм'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Клипса'), 
        ],
      ),
    );
  }
}

// ===================================================================
// ЧАСТЬ 2: РЕАЛИЗАЦИЯ ДАШБОРДА (ЭКРАН ИНФО)
// ===================================================================
class CarpOutDashboard extends StatelessWidget {
  final String lake;
  final String sector;
  final int catches;
  final double weight;
  final String bigFish;
  final Function(String, String) onUpdateSession;
  final Function(int, double, String) onUpdateStats;

  const CarpOutDashboard({
    Key? key,
    required this.lake,
    required this.sector,
    required this.catches,
    required this.weight,
    required this.bigFish,
    required this.onUpdateSession,
    required this.onUpdateStats,
  }) : super(key: key);

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
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
                gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ТЕКУЩАЯ СЕССИЯ', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  icon: const Icon(Icons.tune, size: 16, color: Colors.green),
                  label: const Text('Изменить', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
