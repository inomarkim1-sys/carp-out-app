import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const CarpOutApp());
}

class CarpOutApp extends StatefulWidget {
  const CarpOutApp({Key? key}) : super(key: key);
  @override
  State<CarpOutApp> createState() => _CarpOutAppAppState();
}

class _CarpOutAppAppState extends State<CarpOutApp> {
  String _currentTheme = 'military'; // military, oliva, lady
  double _textScaleFactor = 1.0; // 1.0 - Обычный, 1.2 - Средний, 1.4 - Большой

  @override
  void initState() { super.initState(); _loadGlobalSettings(); }

  Future<void> _loadGlobalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('currentTheme') ?? 'military';
      _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color baseThemeColor; Color surfaceColor; Color accentColor;

    if (_currentTheme == 'oliva') {
      baseThemeColor = const Color(0xFF6B8E23);
      surfaceColor = const Color(0xFF2E3B1E);
      accentColor = const Color(0xFFE8ECD0);
    } else if (_currentTheme == 'lady') {
      baseThemeColor = const Color(0xFFF3E5F5); // Нежно-розоватый хаки
      surfaceColor = const Color(0xFF8E24AA); // Глубокий пурпур
      accentColor = const Color(0xFFE040FB); // Неоново-розовый акцент
    } else {
      baseThemeColor = const Color(0xFF2E3B1E); // Военный тёмный
      surfaceColor = const Color(0xFF1B2611);
      accentColor = const Color(0xFFD4D9A1);
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: _textScaleFactor),
      child: MaterialApp(
        title: 'CarpOut',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: baseThemeColor,
          scaffoldBackgroundColor: baseThemeColor,
          dialogTheme: DialogThemeData(
            backgroundColor: surfaceColor,
            titleTextStyle: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold),
            contentTextStyle: TextStyle(color: _currentTheme == 'lady' ? Colors.black87 : Colors.white),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: surfaceColor,
            iconTheme: IconThemeData(color: accentColor),
            titleTextStyle: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: baseThemeColor,
            secondary: const Color(0xFF8B0000),
            surface: surfaceColor,
          ),
        ),
        home: MainNavigationScreen(
          currentTheme: _currentTheme, 
          scale: _textScaleFactor,
          onSettingsChanged: (theme, scale) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('currentTheme', theme);
            await prefs.setDouble('textScaleFactor', scale);
            setState(() { _currentTheme = theme; _textScaleFactor = scale; });
          },
        ),
      ),
    );
  }
}

class CarpOutAppIconPainter extends CustomPainter {
  final Color accent;
  CarpOutAppIconPainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1B2611)..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = accent..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final fishPaint = Paint()..color = accent..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(size.width * 0.22));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    double w = size.width; double h = size.height;
    final path = Path();
    path.moveTo(w * 0.28, h * 0.58);
    path.quadraticBezierTo(w * 0.38, h * 0.43, w * 0.55, h * 0.46);
    path.quadraticBezierTo(w * 0.68, h * 0.51, w * 0.73, h * 0.58);
    path.lineTo(w * 0.83, h * 0.48); path.lineTo(w * 0.80, h * 0.58); path.lineTo(w * 0.83, h * 0.68);
    path.lineTo(w * 0.73, h * 0.58);
    path.quadraticBezierTo(w * 0.63, h * 0.70, w * 0.45, h * 0.68);
    path.quadraticBezierTo(w * 0.33, h * 0.64, w * 0.28, h * 0.58);
    canvas.drawPath(path, fishPaint);

    final textPainter = TextPainter(text: TextSpan(text: 'CARPOUT', style: TextStyle(color: accent, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.5)), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(w / 2 - textPainter.width / 2, h * 0.22));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CarpWeatherLog {
  String id; double pressure; String trend; String time;
  CarpWeatherLog({required this.id, required this.pressure, required this.trend, required this.time});
  Map<String, dynamic> toJson() => {'id': id, 'pressure': pressure, 'trend': trend, 'time': time};
  factory CarpWeatherLog.fromJson(Map<String, dynamic> json) => CarpWeatherLog(id: json['id'] ?? '', pressure: (json['pressure'] as num).toDouble(), trend: json['trend'] ?? '➡️ Стабильно', time: json['time'] ?? '');
}
class MainNavigationScreen extends StatefulWidget {
  final String currentTheme; final double scale; final Function(String, double) onSettingsChanged;
  const MainNavigationScreen({Key? key, required this.currentTheme, required this.scale, required this.onSettingsChanged}) : super(key: key);
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<String> _lakesList = ['гранный'];
  String _selectedLake = 'гранный';
  String _sectorName = 'Сектор №1';
  String _sessionDuration = '24';
  int _catchesCount = 0; double _totalWeight = 0.0; String _bigFishWeight = '0.000';
  List<String> _markerNames = [];
  String _anglerName = 'Карпятник';
  Map<String, int> _fishSpeciesStats = {'Карп': 0, 'Амур': 0, 'Карась': 0, 'Толстолоб': 0, 'Лещ': 0, 'Сом': 0};
  
  final ValueNotifier<int> _rodResetSignal = ValueNotifier<int>(0);

  @override
  void initState() { super.initState(); _loadAllAppData(); }

  Future<void> _loadAllAppData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _anglerName = prefs.getString('anglerName') ?? 'Карпятник';
      _selectedLake = prefs.getString('currentLake') ?? 'гранный';
      _sectorName = prefs.getString('sector_$_selectedLake') ?? 'Сектор №1';
      _sessionDuration = prefs.getString('duration_$_selectedLake') ?? '24';
      _catchesCount = prefs.getInt('catches_$_selectedLake') ?? 0;
      _totalWeight = prefs.getDouble('weight_$_selectedLake') ?? 0.0;
      _bigFishWeight = prefs.getString('big_$_selectedLake') ?? '0.000';
      
      final String? speciesJson = prefs.getString('species_stats_$_selectedLake');
      if (speciesJson != null) {
        _fishSpeciesStats = Map<String, int>.from(jsonDecode(speciesJson));
      } else {
        _fishSpeciesStats = {'Карп': 0, 'Амур': 0, 'Карась': 0, 'Толстолоб': 0, 'Лещ': 0, 'Сом': 0};
      }

      final String? lakesJson = prefs.getString('lakesList');
      if (lakesJson != null) { _lakesList = List<String>.from(jsonDecode(lakesJson)); }
      final String? pointsJson = prefs.getString('markers_$_selectedLake');
      if (pointsJson != null) { _markerNames = (jsonDecode(pointsJson) as List).map((item) => item['name'] as String).toList(); }
    });
  }

  Future<void> _saveAllAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('anglerName', _anglerName);
    await prefs.setString('currentLake', _selectedLake);
    await prefs.setString('lakesList', jsonEncode(_lakesList));
    await prefs.setString('sector_$_selectedLake', _sectorName);
    await prefs.setString('duration_$_selectedLake', _sessionDuration);
    await prefs.setInt('catches_$_selectedLake', _catchesCount);
    await prefs.setDouble('weight_$_selectedLake', _totalWeight);
    await prefs.setString('big_$_selectedLake', _bigFishWeight);
    await prefs.setString('species_stats_$_selectedLake', jsonEncode(_fishSpeciesStats));
  }

  void _updateMarkersList(List<String> newMarkers) { setState(() { _markerNames = newMarkers; }); }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _anglerName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Позывной / Имя'),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () async { if (controller.text.isNotEmpty) { Navigator.pop(context); setState(() { _anglerName = controller.text; }); await _saveAllAppData(); } },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addNewLakeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить новый водоем'),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () async { if (controller.text.isNotEmpty && !_lakesList.contains(controller.text)) { Navigator.pop(context); setState(() { _lakesList.add(controller.text); _selectedLake = controller.text; _sectorName = 'Сектор №1'; _sessionDuration = '24'; _catchesCount = 0; _totalWeight = 0.0; _bigFishWeight = '0.000'; _markerNames = []; _fishSpeciesStats = {'Карп': 0, 'Амур': 0, 'Карась': 0, 'Толстолоб': 0, 'Лещ': 0, 'Сом': 0}; }); await _saveAllAppData(); await _loadAllAppData(); } },
            child: const Text('Создать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _showInterfaceSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDimState) {
          return AlertDialog(
            title: const Text('⚙️ Настройки интерфейса'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Тема оформления:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: widget.currentTheme,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'military', child: Text('🪖 Тёмный Милитари')),
                    DropdownMenuItem(value: 'oliva', child: Text('🌿 Светлая Олива')),
                    DropdownMenuItem(value: 'lady', child: Text('🌸 Нежная Рыбачка')),
                  ],
                  onChanged: (v) { if (v != null) { widget.onSettingsChanged(v, widget.scale); Navigator.pop(context); _showInterfaceSettings(); } },
                ),
                const SizedBox(height: 16),
                const Text('Размер текста:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButton<double>(
                  dropdownColor: const Color(0xFF1B2611),
                  value: widget.scale,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 1.0, child: Text('Обычный шрифт')),
                    DropdownMenuItem(value: 1.2, child: Text('Средний шрифт')),
                    DropdownMenuItem(value: 1.4, child: Text('Большой шрифт')),
                  ],
                  onChanged: (v) { if (v != null) { widget.onSettingsChanged(widget.currentTheme, v); Navigator.pop(context); _showInterfaceSettings(); } },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color drawerBg = widget.currentTheme == 'lady' ? const Color(0xFFE1BEE7) : const Color(0xFF556B2F);
    Color txtColor = widget.currentTheme == 'lady' ? Colors.black87 : Colors.white;
    Color accentColor = widget.currentTheme == 'military' ? const Color(0xFFD4D9A1) : (widget.currentTheme == 'lady' ? const Color(0xFF8E24AA) : const Color(0xFFE8ECD0));

    final List<Widget> _screens = [
      CarpOutDashboard(
        currentTheme: widget.currentTheme, lake: _selectedLake, sector: _sectorName, duration: _sessionDuration, catches: _catchesCount, weight: _totalWeight, bigFish: _bigFishWeight, speciesStats: _fishSpeciesStats, availableMarkers: _markerNames,
        onUpdateSession: (l, s, d) async { setState(() { _sectorName = s; _sessionDuration = d; }); await _saveAllAppData(); },
        onUpdateStats: (c, w, b, updatedSpecies, resetRodNum) async {
          setState(() { _catchesCount = c; _totalWeight = w; _bigFishWeight = b; _fishSpeciesStats = updatedSpecies; });
          await _saveAllAppData();
          if (resetRodNum > 0) { _rodResetSignal.value = resetRodNum; _rodResetSignal.value = 0; }
        }
      ),
      MarkerMapScreenNew(lakeKey: _selectedLake, onMarkersChanged: _updateMarkersList, currentTheme: widget.currentTheme),
      CarpWeatherScreen(lakeKey: _selectedLake, currentTheme: widget.currentTheme),
      CarpFeedScreen(lakeKey: _selectedLake, availableMarkers: _markerNames, currentTheme: widget.currentTheme, rodResetSignal: _rodResetSignal),
      FishSocialScreen(lakeKey: _selectedLake, currentTheme: widget.currentTheme),
    ];

    return Scaffold(
      drawer: Drawer(
        backgroundColor: drawerBg,
        child: Column(children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1B2611)),
            accountName: InkWell(
              onTap: _showEditNameDialog,
              child: Row(children: [Text('Привет, $_anglerName! 👋', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 15)), const SizedBox(width: 6), Icon(Icons.edit, color: accentColor, size: 14)]),
            ),
            accountEmail: const Text('Удачной сессии и жирных паровозов!', style: TextStyle(color: Colors.white70, fontSize: 11)),
            currentAccountPicture: CustomPaint(painter: CarpOutAppIconPainter(accentColor))
          ),
          ListTile(
            leading: Icon(Icons.palette, color: accentColor),
            title: Text('⚙️ Настройки интерфейса', style: TextStyle(color: txtColor, fontWeight: FontWeight.bold)),
            onTap: () { Navigator.pop(context); _showInterfaceSettings(); },
          ),
          const Divider(color: Colors.white24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('СПИСОК ВОДОЕМОВ:', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)), IconButton(icon: Icon(Icons.add_circle, color: accentColor), onPressed: _addNewLakeDialog)])),
          Expanded(child: ListView.builder(itemCount: _lakesList.length, itemBuilder: (context, index) {
            final lakeItem = _lakesList[index]; bool isCurrent = lakeItem == _selectedLake;
            final sectorCtrl = TextEditingController(text: isCurrent ? _sectorName : 'Сектор №1'); final durationCtrl = TextEditingController(text: isCurrent ? _sessionDuration : '24');
            return Theme(data: ThemeData(unselectedWidgetColor: Colors.white70), child: ExpansionTile(
              leading: Icon(Icons.water, color: isCurrent ? accentColor : Colors.white70), title: Text(lakeItem, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (isCurrent) Icon(Icons.check_circle, color: accentColor, size: 20), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () async { if (_lakesList.length > 1) { Navigator.pop(context); setState(() { _lakesList.remove(lakeItem); if (isCurrent) _selectedLake = _lakesList.first; }); await _saveAllAppData(); await _loadAllAppData(); } })]),
              children: [Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(12)), child: Column(children: [TextField(controller: sectorCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Сектор ловли', labelStyle: TextStyle(color: Colors.white60))), TextField(controller: durationCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Длительность сессии (ч)', labelStyle: TextStyle(color: Colors.white60))), const SizedBox(height: 8), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () async { Navigator.pop(context); setState(() { _selectedLake = lakeItem; _sectorName = sectorCtrl.text; _sessionDuration = durationCtrl.text; }); await _saveAllAppData(); await _loadAllAppData(); }, child: const Text('Выбрать и применить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))].map((w) => Padding(padding: const EdgeInsets.only(bottom: 4), child: w)).toList()))],
            ));
          }))
        ]),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF1B2611), selectedItemColor: accentColor, unselectedItemColor: Colors.white54, onTap: (idx) { setState(() { _currentIndex = idx; }); }, items: const [BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Инфо'), BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Маркер'), BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Барометр'), BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Корм'), BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Трофеи')]),
    );
  }
}
class CarpOutDashboard extends StatelessWidget {
  final String currentTheme; final String lake; final String sector; final String duration; final int catches; final double weight; final String bigFish; final Map<String, int> speciesStats; final List<String> availableMarkers; final Function(String, String, String) onUpdateSession; final Function(int, double, String, Map<String, int>, int) onUpdateStats;
  const CarpOutDashboard({Key? key, required this.currentTheme, required this.lake, required this.sector, required this.duration, required this.catches, required this.weight, required this.bigFish, required this.speciesStats, required this.availableMarkers, required this.onUpdateSession, required this.onUpdateStats}) : super(key: key);

  String _getCurrentDate() { final now = DateTime.now(); final months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря']; return '${now.day} ${months[now.month - 1]} ${now.year} г.'; }

  void _showSpeciesSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Сводка улова по видам'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...speciesStats.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${e.key}:', style: const TextStyle(color: Colors.white70)), Text('${e.value} шт.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            )).toList(),
            const Divider(color: Colors.white24, height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Всего хвостов:', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)), Text('$catches шт.', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))]),
          ],
        ),
        actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () => Navigator.pop(context), child: const Text('Понятно', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]
      ),
    );
  }

  void _showInTheNetDialog(BuildContext context) {
    final weightController = TextEditingController();
    String selectedSpecies = 'Карп';
    int selectedRod = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Рыба в подсаке! 🎣'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: weightController, style: const TextStyle(color: Colors.white), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Вес рыбы (кг)', labelStyle: TextStyle(color: Colors.white60))),
                  const SizedBox(height: 12),
                  const Text('Какая рыба:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xFF1B2611), value: selectedSpecies, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: <String>['Карп', 'Амур', 'Карась', 'Толстолоб', 'Лещ', 'Сом'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) { setDialogState(() { selectedSpecies = v!; }); },
                  ),
                  const SizedBox(height: 12),
                  const Text('На какое удилище поймано:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  DropdownButton<int>(
                    dropdownColor: const Color(0xFF1B2611), value: selectedRod, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: const [DropdownMenuItem(value: 1, child: Text('Рабочее удилище №1')), DropdownMenuItem(value: 2, child: Text('Рабочее удилище №2')), DropdownMenuItem(value: 3, child: Text('Рабочее удилище №3')), DropdownMenuItem(value: 4, child: Text('Рабочее удилище №4'))],
                    onChanged: (v) { setDialogState(() { selectedRod = v!; }); },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white70))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
                onPressed: () {
                  double inputWeight = double.tryParse(weightController.text) ?? 0.0;
                  if (inputWeight > 0) {
                    Navigator.pop(context);
                    int newCatches = catches + 1;
                    double newTotalWeight = weight + inputWeight;
                    double currentBig = double.tryParse(bigFish) ?? 0.0;
                    String newBigString = bigFish;
                    if (inputWeight > currentBig) { newBigString = inputWeight.toStringAsFixed(3); }
                    
                    Map<String, int> updatedMap = Map<String, int>.from(speciesStats);
                    updatedMap[selectedSpecies] = (updatedMap[selectedSpecies] ?? 0) + 1;

                    onUpdateStats(newCatches, newTotalWeight, newBigString, updatedMap, selectedRod);
                  }
                },
                child: const Text('В журнал!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    double averageWeight = catches > 0 ? weight / catches : 0.0;
    Color accentColor = currentTheme == 'military' ? const Color(0xFFD4D9A1) : (currentTheme == 'lady' ? const Color(0xFF8E24AA) : const Color(0xFFE8ECD0));
    Color cardBg = currentTheme == 'lady' ? Colors.white : const Color(0xFF1B2611);
    Color txtColor = currentTheme == 'lady' ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: currentTheme == 'lady' ? const Color(0xFFF3E5F5) : Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 25), Row(children: [IconButton(icon: Icon(Icons.menu, color: accentColor), onPressed: () => Scaffold.of(context).openDrawer()), Text('CarpOut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor))]),
        const SizedBox(height: 10),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_getCurrentDate(), style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 6), const Text('ТЕКУЩАЯ СЕССИЯ', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(lake, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text(sector, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500))])),
        const SizedBox(height: 24),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3, children: [
          GestureDetector(onTap: () => _showSpeciesSummary(context), child: _buildStatCard('Всего хвостов', '$catches шт.', Icons.phishing, const Color(0xFF4A5D32), cardBg, txtColor, accentColor)),
          _buildStatCard('Общий вес', '${weight.toStringAsFixed(3)} кг', Icons.scale, const Color(0xFF4A5D32), cardBg, txtColor, accentColor),
          _buildStatCard('Средний вес', '${averageWeight.toStringAsFixed(3)} кг', Icons.analytics, const Color(0xFF4A5D32), cardBg, txtColor, accentColor),
          _buildStatCard('BIG FISH 🔥', '$bigFish кг', Icons.emoji_events, const Color(0xFFFF5252), cardBg, txtColor, accentColor)
        ]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: BorderSide(color: accentColor, width: 1.2)), onPressed: () => _showInTheNetDialog(context), icon: Icon(Icons.phishing, color: accentColor), label: Text('В подсаке! 🎣', style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold))))
      ])),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bg, Color txt, Color accent) { return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3), width: 1.2)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Row(children: [Icon(icon, color: iconColor, size: 18), const SizedBox(width: 6), Text(title, style: TextStyle(color: txt.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold))]), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent))])); }
}
class MarkerPoint {
  String name; double distance; double depth; String bottomType; double angle; String assignedRod;
  MarkerPoint({required this.name, required this.distance, required this.depth, required this.bottomType, required this.angle, required this.assignedRod});
  Map<String, dynamic> toJson() => {'name': name, 'distance': distance, 'depth': depth, 'bottomType': bottomType, 'angle': angle, 'assignedRod': assignedRod};
  factory MarkerPoint.fromJson(Map<String, dynamic> json) => MarkerPoint(name: json['name'] ?? '', distance: (json['distance'] as num).toDouble(), depth: (json['depth'] as num).toDouble(), bottomType: json['bottomType'] ?? '', angle: (json['angle'] as num).toDouble(), assignedRod: json['assignedRod'] ?? 'Маркер / Свободная');
}

class CarpAnomaly {
  String id; String type; double distance; double angle;
  CarpAnomaly({required this.id, required this.type, required this.distance, required this.angle});
  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'distance': distance, 'angle': angle};
  factory CarpAnomaly.fromJson(Map<String, dynamic> json) => CarpAnomaly(id: json['id'] ?? '', type: json['type'] ?? '🪵 Коряга', distance: (json['distance'] as num).toDouble(), angle: (json['angle'] as num).toDouble());
}

class MarkerMapScreenNew extends StatefulWidget {
  final String lakeKey; final Function(List<String>) onMarkersChanged; final String currentTheme;
  const MarkerMapScreenNew({Key? key, required this.lakeKey, required this.onMarkersChanged, required this.currentTheme}) : super(key: key);
  @override
  _MarkerMapScreenNewState createState() => _MarkerMapScreenNewState();
}

class _MarkerMapScreenNewState extends State<MarkerMapScreenNew> {
  List<MarkerPoint> _points = [];
  List<CarpAnomaly> _anomalies = [];
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _depthController = TextEditingController();
  String _selectedBottomType = '🐚 Ракушка';
  String _selectedRod = 'Рабочее №1';
  
  String _activeToolMode = 'point'; // point - точки, bush/log/reed/stone - аномалии
  double _dragDistance = 0.0; double _dragAngle = 0.0; bool _isDragging = false;

  @override
  void initState() { super.initState(); _loadMarkerData(); }
  @override
  void didUpdateWidget(covariant MarkerMapScreenNew oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.lakeKey != widget.lakeKey) { _loadMarkerData(); } }

  Future<void> _loadMarkerData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pointsJson = prefs.getString('markers_${widget.lakeKey}');
    final String? anomaliesJson = prefs.getString('anomalies_${widget.lakeKey}');
    
    setState(() {
      if (pointsJson != null) { _points = (jsonDecode(pointsJson) as List).map((item) => MarkerPoint.fromJson(item)).toList(); } else { _points = []; }
      if (anomaliesJson != null) { _anomalies = (jsonDecode(anomaliesJson) as List).map((item) => CarpAnomaly.fromJson(item)).toList(); } else { _anomalies = []; }
    });
    _notifyParent();
  }

  Future<void> _saveMarkerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('markers_${widget.lakeKey}', jsonEncode(_points.map((p) => p.toJson()).toList()));
    await prefs.setString('anomalies_${widget.lakeKey}', jsonEncode(_anomalies.map((a) => a.toJson()).toList()));
    _notifyParent();
  }

  void _notifyParent() {
    List<String> names = _points.map((p) => '${p.name} (${p.distance.toStringAsFixed(1)}м) [${p.assignedRod}]').toList();
    widget.onMarkersChanged(names);
  }

  void _handleRadarTap(double calcDistance, double calcAngle) {
    if (_activeToolMode == 'point') {
      _nameController.clear(); _distanceController.text = calcDistance.toStringAsFixed(1); _depthController.clear();
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B2611), title: const Text('🎯 Засечь точку ловли'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Название / Ориентир', labelStyle: TextStyle(color: Colors.white60))),
              TextField(controller: _distanceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Дистанция (метры)', labelStyle: TextStyle(color: Colors.white60))),
              TextField(controller: _depthController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Глубина (метры)', labelStyle: TextStyle(color: Colors.white60))),
              const SizedBox(height: 12),
              DropdownButton<String>(
                dropdownColor: const Color(0xFF1B2611), value: _selectedRod, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                items: <String>['Рабочее №1', 'Рабочее №2', 'Рабочее №3', 'Рабочее №4', 'Маркер / Свободная'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { setDialogState(() { _selectedRod = v!; }); },
              ),
              DropdownButton<String>(
                dropdownColor: const Color(0xFF1B2611), value: _selectedBottomType, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                items: <String>['🐚 Ракушка', '🍃 Ил', '🪨 Камни', '🪵 Коряга', '🏖️ Песок'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { setDialogState(() { _selectedBottomType = v!; }); },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white70))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { if (_nameController.text.isNotEmpty) { Navigator.pop(context); setState(() { _points.add(MarkerPoint(name: _nameController.text, distance: double.tryParse(_distanceController.text) ?? calcDistance, depth: double.tryParse(_depthController.text) ?? 0.0, bottomType: _selectedBottomType, angle: calcAngle, assignedRod: _selectedRod)); }); _saveMarkerData(); } }, child: const Text('В журнал', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        )),
      );
    } else {
      String anomalyMarker = '🪵 Коряга';
      if (_activeToolMode == 'bush') anomalyMarker = '🌲 Куст';
      if (_activeToolMode == 'reed') anomalyMarker = '🌿 Камыш';
      if (_activeToolMode == 'stone') anomalyMarker = '🪨 Камни';
      
      setState(() { _anomalies.add(CarpAnomaly(id: DateTime.now().millisecondsSinceEpoch.toString(), type: anomalyMarker, distance: calcDistance, angle: calcAngle)); });
      _saveMarkerData();
    }
  }
  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.currentTheme == 'military' ? const Color(0xFFD4D9A1) : (widget.currentTheme == 'lady' ? const Color(0xFF8E24AA) : const Color(0xFFE8ECD0));
    return Scaffold(
      backgroundColor: widget.currentTheme == 'lady' ? const Color(0xFFF3E5F5) : Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(builder: (context, constraints) {
        double w = constraints.maxWidth; double h = constraints.maxHeight;
        double centerX = w / 2; double bottomY = h - 60; double maxRadiusPixels = h - 150;
        return Stack(children: [
          GestureDetector(
            onPanStart: (details) {
              double dx = details.localPosition.dx - centerX; double dy = bottomY - details.localPosition.dy;
              if (dy.abs() < 60) { setState(() { _isDragging = true; _dragDistance = 55.0; _dragAngle = dx / (maxRadiusPixels * 1.5); }); }
            },
            onPanUpdate: (details) {
              if (_isDragging) {
                double dx = details.localPosition.dx - centerX; double dy = bottomY - details.localPosition.dy;
                double factor = dy / maxRadiusPixels; if (factor < 0) factor = 0; if (factor > 1) factor = 1;
                setState(() { _dragDistance = 55.0 + (105.0 * factor); _dragAngle = dx / (maxRadiusPixels * 1.5); });
              }
            },
            onPanEnd: (details) { if (_isDragging) { setState(() { _isDragging = false; }); _handleRadarTap(_dragDistance, _dragAngle); } },
            onTapUp: (details) {
              double dx = details.localPosition.dx - centerX; double dy = bottomY - details.localPosition.dy;
              if (dy > 10) {
                double factor = dy / maxRadiusPixels; if (factor < 0) factor = 0; if (factor > 1) factor = 1;
                double calcD = 55.0 + (105.0 * factor); double calcA = dx / (maxRadiusPixels * 1.5);
                _handleRadarTap(calcD, calcA);
              }
            },
            child: Container(width: w, height: h, color: Colors.transparent, child: CustomPaint(painter: CarpOutRadarPainter3D(savedPoints: _points, savedAnomalies: _anomalies, currentDragDist: _dragDistance, currentDragAngle: _dragAngle, isDragging: _isDragging, centerX: centerX, bottomY: bottomY, maxRadius: maxRadiusPixels, accent: accentColor))),
          ),
          Positioned(
            top: 40, left: 16, right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ChoiceChip(label: const Text('🎯 Точки ловли', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), selected: _activeToolMode == 'point', onSelected: (b) => setState(() { if (b) _activeToolMode = 'point'; })), const SizedBox(width: 6),
                ChoiceChip(label: const Text('🪵 Коряга', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), selected: _activeToolMode == 'log', onSelected: (b) => setState(() { if (b) _activeToolMode = 'log'; })), const SizedBox(width: 6),
                ChoiceChip(label: const Text('🌲 Куст', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), selected: _activeToolMode == 'bush', onSelected: (b) => setState(() { if (b) _activeToolMode = 'bush'; })), const SizedBox(width: 6),
                ChoiceChip(label: const Text('🌿 Камыш', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), selected: _activeToolMode == 'reed', onSelected: (b) => setState(() { if (b) _activeToolMode = 'reed'; })), const SizedBox(width: 6),
                ChoiceChip(label: const Text('🪨 Камни', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), selected: _activeToolMode == 'stone', onSelected: (b) => setState(() { if (b) _activeToolMode = 'stone'; })),
              ]),
            ),
          ),
          Positioned(
            bottom: 16, left: 16,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1B2611), shape: RoundedRectangleBorder(side: BorderSide(color: accentColor, width: 1.2), borderRadius: BorderRadius.circular(16)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1B2611), content: CarpClipsCalculator(currentTheme: widget.currentTheme)),
                );
              },
              icon: Icon(Icons.calculate, color: accentColor), label: const Text('Клипса', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 16, right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1B2611), shape: RoundedRectangleBorder(side: BorderSide(color: accentColor, width: 1.2), borderRadius: BorderRadius.circular(16)),
              onPressed: () {
                showModalBottomSheet(
                  context: context, backgroundColor: Theme.of(context).primaryColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Column(children: [
                    const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))), const SizedBox(height: 16),
                    const Text('ЖУРНАЛ СЕКТОРНЫХ ОБЪЕКТОВ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 12),
                    Expanded(child: (_points.isEmpty && _anomalies.isEmpty) ? const Center(child: Text('Карта пуста', style: TextStyle(color: Colors.white38))) : ListView(children: [
                      ..._points.map((p) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), color: const Color(0xFF1B2611), child: ListTile(leading: const Icon(Icons.location_on, color: Colors.redAccent), title: Text('${p.name} [${p.assignedRod}]', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)), subtitle: Text('Дно: ${p.bottomType} | ${p.distance.toStringAsFixed(1)}м', style: const TextStyle(color: Colors.white70, fontSize: 11)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.white38, size: 18), onPressed: () { setSheetState(() { _points.remove(p); }); _saveMarkerData(); })))),
                      ..._anomalies.map((a) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), color: const Color(0xFF1B2611), child: ListTile(leading: const Icon(Icons.star, color: Colors.orangeAccent), title: Text(a.type, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)), subtitle: Text('Аномалия на дист: ${a.distance.toStringAsFixed(1)}м', style: const TextStyle(color: Colors.white70, fontSize: 11)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.white38, size: 18), onPressed: () { setSheetState(() { _anomalies.remove(a); }); _saveMarkerData(); })))),
                    ])),
                  ])),
                );
              },
              icon: const Icon(Icons.layers, color: Colors.white), label: const Text('Журнал', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]);
      }),
    );
  }
}

class CarpClipsCalculator extends StatefulWidget {
  final String currentTheme; const CarpClipsCalculator({Key? key, required this.currentTheme}) : super(key: key);
  @override
  _CarpClipsCalculatorState createState() => _CarpClipsCalculatorState();
}

class _CarpClipsCalculatorState extends State<CarpClipsCalculator> {
  final _markerCtrl = TextEditingController(); final _workCtrl = TextEditingController(); double _result = 0.0;
  void _calc() { double m = double.tryParse(_markerCtrl.text) ?? 0.0; double w = double.tryParse(_workCtrl.text) ?? 0.0; if (m > 0 && w > 0) { setState(() { _result = (w * m) / 4.0; }); } }
  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.currentTheme == 'military' ? const Color(0xFFD4D9A1) : (widget.currentTheme == 'lady' ? const Color(0xFF8E24AA) : const Color(0xFFE8ECD0));
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('📏 СЧЕТЧИК ОБОРОТОВ КОЛЫШКОВ', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 16),
        TextField(controller: _markerCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Дистанция по маркеру (м)', labelStyle: TextStyle(color: Colors.white60))),
        TextField(controller: _workCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Дистанция рабочей палки (м)', labelStyle: TextStyle(color: Colors.white60))),
        const SizedBox(height: 16), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3B1E), side: BorderSide(color: accentColor)), onPressed: _calc, child: Text('Рассчитать клипсу', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
        if (_result > 0) ...[const SizedBox(height: 16), Text('Обороты на колышках: ${_result.toStringAsFixed(2)}', style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold))]
      ]),
    );
  }
}
class CarpOutRadarPainter3D extends CustomPainter {
  final List<MarkerPoint> savedPoints; final List<CarpAnomaly> savedAnomalies; final double currentDragDist; final double currentDragAngle; final bool isDragging; final double centerX; final double bottomY; final double maxRadius; final Color accent;
  CarpOutRadarPainter3D({required this.savedPoints, required this.savedAnomalies, required this.currentDragDist, required this.currentDragAngle, required this.isDragging, required this.centerX, required this.bottomY, required this.maxRadius, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()..color = accent.withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final dashPaint = Paint()..color = accent.withOpacity(0.25)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFFFF5252)..style = PaintingStyle.fill;
    final anomalyPaint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.fill;
    final livePaint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.fill;
    final textPaint = TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold);
    final markerLabelPaint = TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: const Color(0xFF1B2611).withOpacity(0.85));

    for (int angle = -60; angle <= 60; angle += 15) {
      double pct = angle / 60.0;
      double endX = centerX + (maxRadius * pct * 1.1);
      double targetY = bottomY - maxRadius;
      canvas.drawLine(Offset(centerX, bottomY), Offset(endX, targetY), (angle % 30 == 0) ? mainPaint : dashPaint);
    }

    final List<int> distances = [45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210];
    for (int d in distances) {
      double radius = (d - 55) * maxRadius / 105;
      double currentY = bottomY - radius;
      double perspectiveWidth = radius * 1.3 * (1.0 - (radius / maxRadius) * 0.15);
      double startX = centerX - perspectiveWidth;
      double endX = centerX + perspectiveWidth;
      
      final path = Path()..moveTo(startX, currentY)..quadraticBezierTo(centerX, currentY + (radius * 0.05), endX, currentY);
      canvas.drawPath(path, mainPaint);
      
      final textPainter = TextPainter(text: TextSpan(text: '${d}м', style: textPaint), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, currentY - 14));
    }

    for (var point in savedPoints) {
      double r = (point.distance - 55) * maxRadius / 105;
      double perspectiveWidth = r * 1.3 * (1.0 - (r / maxRadius) * 0.15);
      double pX = centerX + (perspectiveWidth * point.angle); double pY = bottomY - r;
      
      if (pY >= bottomY - maxRadius - 40 && pY <= bottomY + 20) {
        canvas.drawCircle(Offset(pX, pY), 5, pointPaint);
        canvas.drawCircle(Offset(pX, pY), 10, mainPaint..strokeWidth = 1.2);
        String labelText = '${point.name} (${point.distance.toStringAsFixed(1)}м)\n[${point.assignedRod}] ${point.bottomType}';
        final labelPainter = TextPainter(text: TextSpan(text: labelText, style: markerLabelPaint), textDirection: TextDirection.ltr)..layout();
        labelPainter.paint(canvas, Offset(pX + 12, pY - 12));
      }
    }

    for (var anomaly in savedAnomalies) {
      double r = (anomaly.distance - 55) * maxRadius / 105;
      double perspectiveWidth = r * 1.3 * (1.0 - (r / maxRadius) * 0.15);
      double aX = centerX + (perspectiveWidth * anomaly.angle); double aY = bottomY - r;
      
      if (aY >= bottomY - maxRadius - 40 && aY <= bottomY + 20) {
        canvas.drawCircle(Offset(aX, aY), 4, anomalyPaint);
        final anomalyPainter = TextPainter(text: TextSpan(text: anomaly.type, style: const TextStyle(fontSize: 14)), textDirection: TextDirection.ltr)..layout();
        anomalyPainter.paint(canvas, Offset(aX - anomalyPainter.width / 2, aY - anomalyPainter.height / 2));
      }
    }

    if (isDragging) {
      double r = (currentDragDist - 55) * maxRadius / 105;
      double perspectiveWidth = r * 1.3 * (1.0 - (r / maxRadius) * 0.15);
      double pX = centerX + (perspectiveWidth * currentDragAngle); double pY = bottomY - r;
      canvas.drawCircle(Offset(pX, pY), 7, livePaint);
      canvas.drawLine(Offset(centerX, bottomY), Offset(pX, pY), livePaint..strokeWidth = 1.2);
      final liveLabel = TextPainter(text: TextSpan(text: 'ЗАБРОС: ${currentDragDist.toStringAsFixed(1)} м', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11, backgroundColor: Colors.orangeAccent)), textDirection: TextDirection.ltr)..layout();
      liveLabel.paint(canvas, Offset(pX - liveLabel.width / 2, pY - 24));
    }

    final logoPainter = TextPainter(text: TextSpan(text: 'CARPOUT', style: TextStyle(color: accent.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)), textDirection: TextDirection.ltr)..layout();
    logoPainter.paint(canvas, Offset(24, bottomY + 20));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class CarpFeedScreen extends StatefulWidget {
  final String lakeKey; final List<String> availableMarkers; final String currentTheme; final ValueNotifier<int> rodResetSignal;
  const CarpFeedScreen({Key? key, required this.lakeKey, required this.availableMarkers, required this.currentTheme, required this.rodResetSignal}) : super(key: key);
  @override
  _CarpFeedScreenState createState() => _CarpFeedScreenState();
}

class _CarpFeedScreenState extends State<CarpFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CarpMixLog> _mixes = [];
  List<PvaStickLog> _sticks = [];

  // ТЗ Выполнено: Корректная инициализация 4 независимых удилищ дефолтными значениями (40 мин)
  final List<int> _timerSecondsList =;
  final List<int> _currentCountdownList =;
  final List<bool> _isTimerRunningList = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFeedData();
    widget.rodResetSignal.addListener(_handleRodResetFromDashboard);
  }

  @override
  void dispose() {
    widget.rodResetSignal.removeListener(_handleRodResetFromDashboard);
    _tabController.dispose();
    super.dispose();
  }

  void _handleRodResetFromDashboard() {
    int targetRod = widget.rodResetSignal.value;
    if (targetRod >= 1 && targetRod <= 4) {
      int idx = targetRod - 1;
      setState(() {
        _isTimerRunningList[idx] = false;
        _currentCountdownList[idx] = 0;
      });
      _saveFeedData();
    }
  }

  Future<void> _loadFeedData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mixesJson = prefs.getString('mixes_${widget.lakeKey}');
    final String? sticksJson = prefs.getString('sticks_${widget.lakeKey}');
    setState(() {
      if (mixesJson != null) { _mixes = (jsonDecode(mixesJson) as List).map((item) => CarpMixLog.fromJson(item)).toList(); } else { _mixes = []; }
      if (sticksJson != null) { _sticks = (jsonDecode(sticksJson) as List).map((item) => PvaStickLog.fromJson(item)).toList(); } else { _sticks = []; }
      
      for (int i = 0; i < 4; i++) {
        _timerSecondsList[i] = prefs.getInt('timer_secs_${widget.lakeKey}_$i') ?? 2400;
        _currentCountdownList[i] = prefs.getInt('curr_countdown_${widget.lakeKey}_$i') ?? 0;
        _isTimerRunningList[i] = prefs.getBool('timer_running_${widget.lakeKey}_$i') ?? false;
        if (_isTimerRunningList[i]) { _startSingleCountdownLoop(i); }
      }
    });
  }

  Future<void> _saveFeedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mixes_${widget.lakeKey}', jsonEncode(_mixes.map((m) => m.toJson()).toList()));
    await prefs.setString('sticks_${widget.lakeKey}', jsonEncode(_sticks.map((s) => s.toJson()).toList()));
    
    for (int i = 0; i < 4; i++) {
      await prefs.setInt('timer_secs_${widget.lakeKey}_$i', _timerSecondsList[i]);
      await prefs.setInt('curr_countdown_${widget.lakeKey}_$i', _currentCountdownList[i]);
      await prefs.setBool('timer_running_${widget.lakeKey}_$i', _isTimerRunningList[i]);
    }
  }
  void _addMixDialog() {
    String liquid = 'CSL + Кукурузный ликер'; String boilieType = 'Вареные Бойлы 20мм';
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF1B2611), title: const Text('Залить спод-микс 🌽🍯'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: liquid, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), items: <String>['CSL + Кукурузный ликер', 'Аминокомплекс Complex-T', '🚫 Без ликвида (сухой)', 'Сладкий бустер Меласса'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { liquid = v!; }); }),
            DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: boilieType, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), items: <String>['Вареные Бойлы 20мм', 'Пылящие бойлы 24мм', 'Конопля + Зерновые', 'Пеллетс Халибут 14мм'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { boilieType = v!; }); }),
            TextField(controller: notesController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Количество спомбов / Инфо', labelStyle: TextStyle(color: Colors.white60))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white70))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { Navigator.pop(context); setState(() { _mixes.add(CarpMixLog(id: DateTime.now().millisecondsSinceEpoch.toString(), liquid: liquid, boilieType: boilieType, notes: notesController.text.isNotEmpty ? notesController.text : 'Спомб отправлен')); }); _saveFeedData(); }, child: const Text('В сектор!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      )),
    );
  }

  void _addStickDialog() {
    String pvaType = 'Сетка ПВА-стик'; String hookBait = 'Pop-up 10мм (Плавающий)';
    String selectedMarker = widget.availableMarkers.isNotEmpty ? widget.availableMarkers.first : 'Свободный заброс в сектор';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2611), title: const Text('Заброс поискового удилища 🎯'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Align(alignment: Alignment.centerLeft, child: Text('На какую маркерную точку бросаем:', style: TextStyle(color: Colors.white60, fontSize: 11))),
              DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: selectedMarker, isExpanded: true, style: const TextStyle(color: Color(0xFFE8ECD0), fontWeight: FontWeight.bold), items: (widget.availableMarkers.isNotEmpty ? widget.availableMarkers : ['Свободный заброс в сектор']).map((s) => DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) { setDialogState(() { selectedMarker = v!; }); }),
              const SizedBox(height: 8),
              DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: pvaType, isExpanded: true, style: const TextStyle(color: Colors.white), items: <String>['Сетка ПВА-стик', 'ПВА-пакет (с пеллетсом)', '🚫 Без ПВА (одиночная)'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { pvaType = v!; }); }),
              DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: hookBait, isExpanded: true, style: const TextStyle(color: Colors.white), items: <String>['Pop-up 10мм (Плавающий)', 'Wafters (Сбалансированный)', 'Искусственная кукуруза', 'Двойной тонущий 20мм'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { hookBait = v!; }); }),
            ]),
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white70))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { final now = DateTime.now(); Navigator.pop(context); String detectedRod = 'Поиск'; if (selectedMarker.contains('[') && selectedMarker.contains(']')) { detectedRod = selectedMarker.substring(selectedMarker.indexOf('[') + 1, selectedMarker.indexOf(']')); } setState(() { _sticks.add(PvaStickLog(id: now.millisecondsSinceEpoch.toString(), pvaType: pvaType, hookBait: hookBait, rodType: detectedRod, time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}')); }); _saveFeedData(); }, child: const Text('В точку!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.currentTheme == 'military' ? const Color(0xFFD4D9A1) : (widget.currentTheme == 'lady' ? const Color(0xFF8E24AA) : const Color(0xFFE8ECD0));
    Color scaffoldBg = widget.currentTheme == 'lady' ? const Color(0xFFF3E5F5) : const Color(0xFF6B8E23);
    Color cardBg = widget.currentTheme == 'lady' ? Colors.white : const Color(0xFF1B2611);
    Color txtColor = widget.currentTheme == 'lady' ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2611),
        title: Text('Тактика Питания & Timing', style: TextStyle(color: accentColor, fontSize: 15, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white54,
          indicatorColor: accentColor,
          tabs: const [Tab(icon: Icon(Icons.restaurant, size: 18), text: 'Миксы'), Tab(icon: Icon(Icons.gpp_good, size: 18), text: 'Стики'), Tab(icon: Icon(Icons.timer, size: 18), text: 'Таймеры')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('История кормления сектора:', style: TextStyle(color: widget.currentTheme == 'lady' ? Colors.black87 : const Color(0xFFE8ECD0), fontWeight: FontWeight.bold, fontSize: 13)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611), side: BorderSide(color: accentColor)), onPressed: _addMixDialog, icon: Icon(Icons.add, color: accentColor, size: 16), label: Text('Корм', style: TextStyle(color: accentColor, fontSize: 12)))]),
            const SizedBox(height: 10),
            Expanded(child: _mixes.isEmpty ? const Center(child: Text('Сводка пуста.', style: TextStyle(color: Colors.white38))) : ListView.builder(itemCount: _mixes.length, itemBuilder: (context, idx) { final m = _mixes[_mixes.length - 1 - idx]; return Card(color: cardBg, margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.opacity, color: Color(0xFFC5E1A5)), title: Text(m.liquid, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text('База: ${m.boilieType}\nИнфо: ${m.notes}', style: TextStyle(color: txtColor.withOpacity(0.7), fontSize: 12)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () { setState(() { _mixes.remove(m); }); _saveFeedData(); }))); })),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Active насадки:', style: TextStyle(color: widget.currentTheme == 'lady' ? Colors.black87 : const Color(0xFFE8ECD0), fontWeight: FontWeight.bold, fontSize: 13)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611), side: BorderSide(color: accentColor)), onPressed: _addStickDialog, icon: Icon(Icons.gps_fixed, color: accentColor, size: 16), label: Text('Заброс', style: TextStyle(color: accentColor, fontSize: 12)))]),
            const SizedBox(height: 10),
            Expanded(child: _sticks.isEmpty ? const Center(child: Text('Нет забросов', style: TextStyle(color: Colors.white38))) : ListView.builder(itemCount: _sticks.length, itemBuilder: (context, idx) { final s = _sticks[_sticks.length - 1 - idx]; return Card(color: cardBg, margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.track_changes, color: Color(0xFFFF5252)), title: Text('${s.rodType} [${s.time}]', style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text('ПВА: ${s.pvaType}\nПрезентация: ${s.hookBait}', style: TextStyle(color: txtColor.withOpacity(0.7), fontSize: 12)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () { setState(() { _sticks.remove(s); }); _saveFeedData(); }))); })),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.builder(
            itemCount: 4,
            itemBuilder: (context, i) {
              bool isRunning = _isTimerRunningList[i];
              int totalSecs = _timerSecondsList[i];
              int currLeft = _currentCountdownList[i];
              int displaySecs = isRunning ? currLeft : totalSecs;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: isRunning ? accentColor.withOpacity(0.5) : Colors.white12)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Удилище №${i + 1}', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '${(displaySecs ~/ 60)}:${(displaySecs % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isRunning ? const Color(0xFFFF5252) : txtColor),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      _buildSinglePreset(i, 2400, '40м'), const SizedBox(width: 4),
                      _buildSinglePreset(i, 3600, '1ч'), const SizedBox(width: 4),
                      _buildSinglePreset(i, 7200, '2ч'),
                    ]),
                    Row(children: [
                      SizedBox(width: 75, height: 32, child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isRunning ? Colors.orange.shade900 : const Color(0xFF4A5D32), padding: EdgeInsets.zero),
                        onPressed: () {
                          if (isRunning) {
                            setState(() { _isTimerRunningList[i] = false; });
                          } else {
                            setState(() {
                              _isTimerRunningList[i] = true;
                              if (_currentCountdownList[i] == 0) { _currentCountdownList[i] = _timerSecondsList[i]; }
                            });
                            _startSingleCountdownLoop(i);
                          }
                          _saveFeedData();
                        },
                        child: Text(isRunning ? 'Пауза' : 'Старт', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      )),
                      const SizedBox(width: 6),
                      SizedBox(width: 75, height: 32, child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), padding: EdgeInsets.zero),
                        onPressed: () {
                          setState(() { _isTimerRunningList[i] = false; _currentCountdownList[i] = 0; });
                          _saveFeedData();
                        },
                        child: const Text('Сброс', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      )),
                    ]),
                  ]),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildSinglePreset(int rodIdx, int secs, String label) {
    bool isSelected = _timerSecondsList[rodIdx] == secs;
    return InkWell(
      onTap: () {
        if (!_isTimerRunningList[rodIdx]) {
          setState(() { _timerSecondsList[rodIdx] = secs; });
          _saveFeedData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: isSelected ? accentColor : const Color(0xFF2E3B1E), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black87 : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _startSingleCountdownLoop(int idx) async {
    while (_isTimerRunningList[idx] && _currentCountdownList[idx] > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isTimerRunningList[idx]) return;
      setState(() {
        _currentCountdownList[idx]--;
        if (_currentCountdownList[idx] <= 0) {
          _isTimerRunningList[idx] = false;
          _showSingleTimerAlert(idx);
        }
      });
    }
  }

  void _showSingleTimerAlert(int idx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFF5252),
        title: Text('ПЕРЕЗАБРОС УДИЛИЩА №${idx + 1}! ⏱️🔥', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Пора обновить насадку и проверить точку ловли!', style: TextStyle(color: Colors.white)),
        actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611)), onPressed: () { Navigator.pop(context); }, child: const Text('Принято', style: TextStyle(color: Colors.white)))],
      ),
    );
  }
}
class FishTrophy {
  String id; String weight; String dateStr; String imagePath; String notes;
  FishTrophy({required this.id, required this.weight, required this.dateStr, required this.imagePath, required this.notes});
  Map<String, dynamic> toJson() => {'id': id, 'weight': weight, 'dateStr': dateStr, 'imagePath': imagePath, 'notes': notes};
  factory FishTrophy.fromJson(Map<String, dynamic> json) => FishTrophy(id: json['id'] ?? '', weight: json['weight'] ?? '', dateStr: json['dateStr'] ?? '', imagePath: json['imagePath'] ?? '', notes: json['notes'] ?? '');
}

class FishSocialScreen extends StatefulWidget {
  final String lakeKey; final String currentTheme;
  const FishSocialScreen({Key? key, required this.lakeKey, required this.currentTheme}) : super(key: key);
  @override
  _FishSocialScreenState createState() => _FishSocialScreenState();
}

class _FishSocialScreenState extends State<FishSocialScreen> {
  List<FishTrophy> _trophies = [];
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedImageFile = '';
  DateTime _selectedCatchDateTime = DateTime.now();

  @override
  void initState() { super.initState(); _loadTrophies(); }
  @override
  void didUpdateWidget(covariant FishSocialScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.lakeKey != widget.lakeKey) { _loadTrophies(); } }

  Future<void> _loadTrophies() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('trophies_${widget.lakeKey}');
    setState(() { if (jsonStr != null) { _trophies = (jsonDecode(jsonStr) as List).map((item) => FishTrophy.fromJson(item)).toList(); } else { _trophies = []; } });
  }

  Future<void> _saveTrophies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trophies_${widget.lakeKey}', jsonEncode(_trophies.map((t) => t.toJson()).toList()));
  }

  Future<void> _pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: src, imageQuality: 75);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final filename = 'trophy_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path).copy('${appDir.path}/$filename');
      setState(() { _selectedImageFile = savedFile.path; });
    }
  }

  // Интерактивный тактический календарик выбора даты и времени улова
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context, initialDate: _selectedCatchDateTime,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF4A5D32), surface: Color(0xFF1B2611))), child: child!),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_selectedCatchDateTime),
        builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF4A5D32), surface: Color(0xFF1B2611))), child: child!),
    );
      if (pickedTime != null) {
        setState(() {
          _selectedCatchDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }
  void _addTrophyDialog() {
    _weightCtrl.clear(); _notesCtrl.clear(); _selectedImageFile = ''; _selectedCatchDateTime = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        Color btnColor = const Color(0xFF4A5D32);
        String formattedDate = '${_selectedCatchDateTime.day}.${_selectedCatchDateTime.month}.${_selectedCatchDateTime.year} ${_selectedCatchDateTime.hour}:${_selectedCatchDateTime.minute.toString().padLeft(2, '0')}';
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2611), title: const Text('Зафиксировать трофей 🏆'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _weightCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вес трофея (кг)', labelStyle: TextStyle(color: Colors.white60))),
              TextField(controller: _notesCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Насадка / Комментарий', labelStyle: TextStyle(color: Colors.white60))),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async { await _selectDateTime(context); setDialogState(() {}); },
                child: Container(
                  padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Время: $formattedDate', style: const TextStyle(color: Colors.white70, fontSize: 12)), const Icon(Icons.calendar_today, color: Colors.white60, size: 14)]),
                ),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: btnColor),
                  onPressed: () async { await _pickImage(ImageSource.camera); setDialogState(() {}); },
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  label: const Text('Камера', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: btnColor),
                  onPressed: () async { await _pickImage(ImageSource.gallery); setDialogState(() {}); },
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 16),
                  label: const Text('Галерея', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
              if (_selectedImageFile.isNotEmpty) ...[const SizedBox(height: 12), Container(height: 100, width: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(_selectedImageFile)), fit: BoxFit.cover)))]
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white70))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () {
              if (_weightCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                String customDateStr = '${_selectedCatchDateTime.day}.${_selectedCatchDateTime.month}.${_selectedCatchDateTime.year} в ${_selectedCatchDateTime.hour}:${_selectedCatchDateTime.minute.toString().padLeft(2, '0')}';
                setState(() { _trophies.add(FishTrophy(id: DateTime.now().millisecondsSinceEpoch.toString(), weight: _weightCtrl.text, dateStr: customDateStr, imagePath: _selectedImageFile, notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : 'Без описания')); });
                _saveTrophies();
              }
            }, child: const Text('Сохранить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.currentTheme == 'military' ? const Color(0xFFD4D9A1) : (widget.currentTheme == 'lady' ? const Color(0xFF8E24AA) : const Color(0xFFE8ECD0));
    Color scaffoldBg = widget.currentTheme == 'lady' ? const Color(0xFFF3E5F5) : const Color(0xFF6B8E23);
    Color cardBg = widget.currentTheme == 'lady' ? Colors.white : const Color(0xFF1B2611);
    Color txtColor = widget.currentTheme == 'lady' ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(backgroundColor: const Color(0xFF1B2611), title: Text('Галерея рекордов и трофеев', style: TextStyle(color: accentColor, fontSize: 15, fontWeight: FontWeight.bold)), actions: [IconButton(icon: Icon(Icons.add_a_photo, color: accentColor), onPressed: _addTrophyDialog)]),
      body: _trophies.isEmpty ? const Center(child: Text('Пока нет трофейных записей.', style: TextStyle(color: Colors.white38))) : GridView.builder(
        padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8),
        itemCount: _trophies.length, itemBuilder: (context, idx) {
          final t = _trophies[_trophies.length - 1 - idx];
          return Container(
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withOpacity(0.3), width: 1.2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: t.imagePath.isNotEmpty && File(t.imagePath).existsSync() ? Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), image: DecorationImage(image: FileImage(File(t.imagePath)), fit: BoxFit.cover))) : Container(color: const Color(0xFF1B2611).withOpacity(0.2), child: Center(child: Icon(Icons.image_not_supported, color: accentColor.withOpacity(0.5))))),
              Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${t.weight} кг 🔥', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14)), IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16), onPressed: () { setState(() { _trophies.remove(t); }); _saveTrophies(); })]),
                const SizedBox(height: 2), Text(t.dateStr, style: TextStyle(color: txtColor.withOpacity(0.6), fontSize: 10)),
                const SizedBox(height: 4), Text(t.notes, style: TextStyle(color: txtColor, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          );
        },
      ),
    );
  }
}
class CarpWeatherScreen extends StatefulWidget {
  final String lakeKey; final String currentTheme;
  const CarpWeatherScreen({Key? key, required this.lakeKey, required this.currentTheme}) : super(key: key);
  @override
  _CarpWeatherScreenState createState() => _CarpWeatherScreenState();
}

class _CarpWeatherScreenState extends State<CarpWeatherScreen> {
  List<CarpWeatherLog> _weatherLogs = [];
  final _pressureController = TextEditingController(text: '745');

  @override
  void initState() { super.initState(); _loadWeatherData(); }
  @override
  void didUpdateWidget(covariant CarpWeatherScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.lakeKey != widget.lakeKey) { _loadWeatherData(); } }

  Future<void> _loadWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('weather_${widget.lakeKey}');
    setState(() { if (jsonStr != null) { _weatherLogs = (jsonDecode(jsonStr) as List).map((item) => CarpWeatherLog.fromJson(item)).toList(); } else { _weatherLogs = []; } });
  }

  Future<void> _saveWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_${widget.lakeKey}', jsonEncode(_weatherLogs.map((w) => w.toJson()).toList()));
  }

  void _addPressureLog() {
    double newP = double.tryParse(_pressureController.text) ?? 745.0;
    final now = DateTime.now();
    String timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    String trend = '➡️ Стабильно';
    if (_weatherLogs.isNotEmpty) {
      double lastP = _weatherLogs.last.pressure;
      if (newP > lastP) trend = '📈 Растет';
      if (newP < lastP) trend = '📉 Падает';
    }
    setState(() { _weatherLogs.add(CarpWeatherLog(id: now.millisecondsSinceEpoch.toString(), pressure: newP, trend: trend, time: timeStr)); if (_weatherLogs.length > 10) { _weatherLogs.removeAt(0); } });
    _saveWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.currentTheme == 'military' ? const Color(0xFFD4D9A1) : (widget.currentTheme == 'lady' ? const Color(0xFF8E24AA) : const Color(0xFFE8ECD0));
    Color cardBg = widget.currentTheme == 'lady' ? Colors.white : const Color(0xFF1B2611);
    Color txtColor = widget.currentTheme == 'lady' ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: widget.currentTheme == 'lady' ? const Color(0xFFF3E5F5) : const Color(0xFF2E3B1E),
      appBar: AppBar(backgroundColor: const Color(0xFF1B2611), title: Text('Тактический Барометр сессии', style: TextStyle(color: accentColor, fontSize: 15, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📊 ТРЕНД АТМОСФЕРНОГО ДАВЛЕНИЯ', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            height: 160, width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withOpacity(0.3))),
            child: CustomPaint(painter: CarpPressureChartPainter(_weatherLogs, accentColor)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: TextField(controller: _pressureController, style: TextStyle(color: txtColor), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Давление (мм рт. ст.)', labelStyle: TextStyle(color: txtColor.withOpacity(0.6))))),
              const SizedBox(width: 16),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)), onPressed: _addPressureLog, child: const Text('Замерить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
            ]),
          ),
          const SizedBox(height: 16),
          Text('История изменений:', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          _weatherLogs.isEmpty 
              ? const Text('Замеров пока нет. Сделайте первый шаг на берегу!', style: TextStyle(color: Colors.white38, fontSize: 12))
              : ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: _weatherLogs.length, itemBuilder: (context, idx) {
                    final log = _weatherLogs[_weatherLogs.length - 1 - idx];
                    return Card(
                      color: cardBg, margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.speed, color: Colors.blueAccent),
                        title: Text('${log.pressure.toStringAsFixed(0)} мм рт. ст.', style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Время фиксации: ${log.time}', style: TextStyle(color: txtColor.withOpacity(0.6), fontSize: 12)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(log.trend, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16), onPressed: () { setState(() { _weatherLogs.remove(log); }); _saveWeatherData(); })
                        ]),
                      ),
                    );
                  },
                )
        ]),
      ),
    );
  }
}
class CarpPressureChartPainter extends CustomPainter {
  final List<CarpWeatherLog> logs; final Color accent;
  CarpPressureChartPainter(this.logs, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = accent.withOpacity(0.15)..strokeWidth = 1.0;
    final linePaint = Paint()..color = accent..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFFFF5252)..style = PaintingStyle.fill;
    
    // Рисуем сетку барометра
    double steps = 4;
    for (int i = 0; i <= steps; i++) {
      double y = (size.height / steps) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (logs.length < 2) {
      final tp = TextPainter(text: TextSpan(text: 'Нужно минимум 2 замера для графика', style: TextStyle(color: accent.withOpacity(0.5), fontSize: 11)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }

    // Ищем минимум и максимум для масштабирования
    double minP = logs.map((e) => e.pressure).reduce((a, b) => a < b ? a : b);
    double maxP = logs.map((e) => e.pressure).reduce((a, b) => a > b ? a : b);
    if (maxP == minP) { minP -= 5; maxP += 5; }
    double range = maxP - minP;

    final path = Path();
    double dx = size.width / (logs.length - 1);

    for (int i = 0; i < logs.length; i++) {
      double x = dx * i;
      double normalizedY = (logs[i].pressure - minP) / range;
      double y = size.height - (normalizedY * (size.height - 20) + 10);

      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }

    canvas.drawPath(path, linePaint);

    // Расставляем точки замеров и подписи мм рт.ст.
    for (int i = 0; i < logs.length; i++) {
      double x = dx * i;
      double normalizedY = (logs[i].pressure - minP) / range;
      double y = size.height - (normalizedY * (size.height - 20) + 10);

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      
      final label = TextPainter(text: TextSpan(text: '${logs[i].pressure.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      label.paint(canvas, Offset(x - label.width / 2, y - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
