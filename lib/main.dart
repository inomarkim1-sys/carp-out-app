import 'package:flutter/material.dart';

void main() {
  runApp(const CarpOutApp());
}

class CarpOutApp extends StatelessWidget {
  const CarpOutApp({Key? super.key}) : super(key: super);

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
  const MainNavigationScreen({Key? super.key}) : super(key: super);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Список экранов приложения CarpOut
  final List<Widget> _screens = [
    const CarpOutDashboard(), // Главная статистика сессии
    const Center(child: Text('Экран: Маркерная карта (В разработке)', style: TextStyle(fontSize: 18, color: Colors.darkGreen))), 
    const Center(child: Text('Экран: Калькулятор клипс (В разработке)', style: TextStyle(fontSize: 18, color: Colors.darkGreen))), 
    const Center(child: Text('Экран: Журнал прикормки (В разработке)', style: TextStyle(fontSize: 18, color: Colors.darkGreen))),   
    const Center(child: Text('Экран: Новая поимка (В разработке)', style: TextStyle(fontSize: 18, color: Colors.darkGreen))),    
  ];

  @override
  Widget build(BuildContext context) {
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
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Инфо'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Маркер'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Клипса'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Корм'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Поимка'),
        ],
      ),
    );
  }
}

class CarpOutDashboard extends StatelessWidget {
  const CarpOutDashboard({Key? super.key}) : super(key: super);

  @override
  Widget build(BuildContext context) {
    const int totalCatches = 8;
    const double totalWeight = 78.400;
    const double averageWeight = totalWeight / totalCatches;
    const String bigFish = "16.800 кг (Зеркальный)";

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarpOut — Мониторинг Сессии', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: Cross CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ТЕКУЩАЯ СЕССИЯ', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Озеро Трофейное • Сектор №4', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
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
            const Text('Аналитика улова:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Всего хвостов', '$totalCatches шт.', Icons.phishing, Colors.blue),
                _buildStatCard('Общий вес', '${totalWeight.toStringAsFixed(3)} кг', Icons.scale, Colors.orange),
                _buildStatCard('Средний вес', '${averageWeight.toStringAsFixed(3)} кг', Icons.analytics, Colors.purple),
                _buildStatCard('BIG FISH 🔥', bigFish, Icons.emoji_events, Colors.red, isLongText: true),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: isLongText ? 14 : 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
