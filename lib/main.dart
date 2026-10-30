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
        primaryColor: const Color(0xFF6B8E23), // Ещё более светлая полевая олива для солнца
        scaffoldBackgroundColor: const Color(0xFF6B8E23), // Освежённый фоновый тон
        dialogTheme: const DialogThemeData(
          backgroundColor: const Color(0xFF2E3B1E), // Контрастный плотный хаки для окон
          titleTextStyle: TextStyle(color: Color(0xFFE8ECD0), fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E3B1E), 
          iconTheme: IconThemeData(color: Color(0xFFE8ECD0)),
          titleTextStyle: TextStyle(color: Color(0xFFE8ECD0), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF6B8E23),
          secondary: const Color(0xFF8B0000), // Тактический тёмно-красный акцент
          surface: const Color(0xFF2E3B1E),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class CarpOutAppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF2E3B1E)..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = const Color(0xFFE8ECD0)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final fishPaint = Paint()..color = const Color(0xFFE8ECD0)..style = PaintingStyle.fill;

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

    final textPainter = TextPainter(text: const TextSpan(text: 'CARPOUT', style: TextStyle(color: Color(0xFFE8ECD0), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.5)), textDirection: TextDirection.ltr)..layout();
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
  List<String> _lakesList = ['гранный'];
  String _selectedLake = 'гранный';
  String _sectorName = 'Сектор №1';
  String _sessionDuration = '24';
  int _catchesCount = 0; double _totalWeight = 0.0; String _bigFishWeight = '0.000';
  List<String> _markerNames = [];
  String _anglerName = 'Карпятник'; // Переменная для кастомного имени в шторке

class CarpOutDashboard extends StatelessWidget {
  final String lake; final String sector; final String duration; final int catches; final double weight; final String bigFish; final List<String> availableMarkers; final Function(String, String, String) onUpdateSession; final Function(int, double, String) onUpdateStats;
  const CarpOutDashboard({Key? key, required this.lake, required this.sector, required this.duration, required this.catches, required this.weight, required this.bigFish, required this.availableMarkers, required this.onUpdateSession, required this.onUpdateStats}) : super(key: key);

  String _getCurrentDate() { final now = DateTime.now(); final months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря']; return '${now.day} ${months[now.month - 1]} ${now.year} г.'; }

  void _showCatchesDialog(BuildContext context) {
    final controller = TextEditingController(text: catches.toString());
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1B2611), title: const Text('Изменить количество хвостов'), content: TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { int? val = int.tryParse(controller.text); if (val != null) { Navigator.pop(context); onUpdateStats(val, weight, bigFish); } }, child: const Text('Сохранить'))]));
  }

  void _showWeightDialog(BuildContext context) {
    final controller = TextEditingController(text: weight.toString());
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1B2611), title: const Text('Изменить общий вес улова'), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { double? val = double.tryParse(controller.text); if (val != null) { Navigator.pop(context); onUpdateStats(catches, val, bigFish); } }, child: const Text('Сохранить'))]));
  }

  void _showBigFishDialog(BuildContext context) {
    final controller = TextEditingController(text: bigFish);
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1B2611), title: const Text('Обновить трофей BIG FISH'), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { if (controller.text.isNotEmpty) { Navigator.pop(context); onUpdateStats(catches, weight, controller.text); } }, child: const Text('Сохранить'))]));
  }

  void _showInTheNetDialog(BuildContext context) {
    final weightController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1B2611), title: const Text('Рыба в подсаке! 🎣'), content: TextField(controller: weightController, style: const TextStyle(color: Colors.white), keyboardType: const TextInputType.numberWithOptions(decimal: true)), actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { double inputWeight = double.tryParse(weightController.text) ?? 0.0; if (inputWeight > 0) { Navigator.pop(context); int newCatches = catches + 1; double newTotalWeight = weight + inputWeight; double currentBig = double.tryParse(bigFish) ?? 0.0; String newBigString = bigFish; if (inputWeight > currentBig) { newBigString = inputWeight.toStringAsFixed(3); } onUpdateStats(newCatches, newTotalWeight, newBigString); } }, child: const Text('В журнал!'))]));
  }
  @override
  Widget build(BuildContext context) {
    double averageWeight = catches > 0 ? weight / catches : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFF2E3B1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            Row(children: [IconButton(icon: const Icon(Icons.menu, color: Color(0xFFD4D9A1)), onPressed: () => Scaffold.of(context).openDrawer()), const Text('CarpOut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4D9A1)))]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD4D9A1).withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_getCurrentDate(), style: const TextStyle(color: Color(0xFFD4D9A1), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('ТЕКУЩАЯ СЕССИЯ - ДЛИТЕЛЬНОСТЬ $duration Ч.', style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(lake, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(sector, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
              children: [
                GestureDetector(onTap: () => _showCatchesDialog(context), child: _buildStatCard('Всего хвостов', '$catches шт.', Icons.phishing, const Color(0xFF4A5D32))),
                GestureDetector(onTap: () => _showWeightDialog(context), child: _buildStatCard('Общий вес', '${weight.toStringAsFixed(3)} кг', Icons.scale, const Color(0xFF4A5D32))),
                GestureDetector(onTap: () => _showCatchesDialog(context), child: _buildStatCard('Средний вес', '${averageWeight.toStringAsFixed(3)} кг', Icons.analytics, const Color(0xFF4A5D32))),
                GestureDetector(onTap: () => _showBigFishDialog(context), child: _buildStatCard('BIG FISH 🔥', '$bigFish кг', Icons.emoji_events, const Color(0xFFFF5252))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2611), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: Color(0xFFD4D9A1), width: 1.2)),
                onPressed: () => _showInTheNetDialog(context),
                icon: const Icon(Icons.phishing, color: Color(0xFFD4D9A1)),
                label: const Text('В подсаке! 🎣', style: TextStyle(color: Color(0xFFD4D9A1), fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD4D9A1).withOpacity(0.3), width: 1.2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [Icon(icon, color: iconColor, size: 18), const SizedBox(width: 6), Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4D9A1))),
      ]),
    );
  }
}

class MarkerPoint {
  String name; double distance; double depth; String bottomType; double angle;
  String assignedRod; // Добавили удилище в структуру памяти

  MarkerPoint({required this.name, required this.distance, required this.depth, required this.bottomType, required this.angle, required this.assignedRod});
  Map<String, dynamic> toJson() => {'name': name, 'distance': distance, 'depth': depth, 'bottomType': bottomType, 'angle': angle, 'assignedRod': assignedRod};
  factory MarkerPoint.fromJson(Map<String, dynamic> json) => MarkerPoint(name: json['name'] ?? '', distance: (json['distance'] as num).toDouble(), depth: (json['depth'] as num).toDouble(), bottomType: json['bottomType'] ?? '', angle: (json['angle'] as num).toDouble(), assignedRod: json['assignedRod'] ?? 'Маркер / Свободная');
}

class MarkerMapScreenNew extends StatefulWidget {
  final String lakeKey; final Function(List<String>) onMarkersChanged;
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
  String _selectedRod = 'Рабочее №1'; // Удилище для привязки

  double _dragDistance = 0.0;
  double _dragAngle = 0.0;
  bool _isDragging = false;


  @override
  void initState() { super.initState(); _loadMarkerPoints(); }

  @override
  void didUpdateWidget(covariant MarkerMapScreenNew oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.lakeKey != widget.lakeKey) { _loadMarkerPoints(); } }

  Future<void> _loadMarkerPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pointsJson = prefs.getString('markers_${widget.lakeKey}');
    if (pointsJson != null) {
      final List<dynamic> decoded = jsonDecode(pointsJson);
      setState(() { _points = decoded.map((item) => MarkerPoint.fromJson(item)).toList(); });
      _notifyParent();
    } else { setState(() { _points = []; }); _notifyParent(); }
  }

  Future<void> _saveMarkerPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_points.map((p) => p.toJson()).toList());
    await prefs.setString('markers_${widget.lakeKey}', encoded);
    _notifyParent();
  }

    void _notifyParent() {
    List<String> names = _points.map((p) => '${p.name} (${p.distance.toStringAsFixed(1)}м) [${p.assignedRod}]').toList();
    widget.onMarkersChanged(names);
  }

   void _addPointFromRadar(double tappedDistance, double tappedAngle) {
    _nameController.clear(); _distanceController.text = tappedDistance.toStringAsFixed(1); _depthController.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B2611),
          title: const Text('🎯 Засечь точку ловли', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Название / Ориентир', labelStyle: TextStyle(color: Colors.white60))),
              TextField(controller: _distanceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Дистанция (метры)', labelStyle: TextStyle(color: Colors.white60))),
              TextField(controller: _depthController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Глубина (метры)', labelStyle: TextStyle(color: Colors.white60))),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('Привязать к рабочему удилищу:', style: TextStyle(color: Colors.white60, fontSize: 11))),
              DropdownButton<String>(
                dropdownColor: const Color(0xFF1B2611), value: _selectedRod, isExpanded: true, style: const TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold),
                items: <String>['Рабочее №1', 'Рабочее №2', 'Рабочее №3', 'Рабочее №4', 'Маркер / Свободная'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { setDialogState(() { _selectedRod = v!; }); },
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('Структура дна в точке:', style: TextStyle(color: Colors.white60, fontSize: 11))),
              DropdownButton<String>(
                dropdownColor: const Color(0xFF1B2611), value: _selectedBottomType, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                items: <String>['🐚 Ракушка', '🍃 Ил', '🪨 Камни', '🪵 Коряга', '🏖️ Песок'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { setDialogState(() { _selectedBottomType = v!; }); },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() { _points.add(MarkerPoint(name: _nameController.text, distance: double.tryParse(_distanceController.text) ?? tappedDistance, depth: double.tryParse(_depthController.text) ?? 0.0, bottomType: _selectedBottomType, angle: tappedAngle, assignedRod: _selectedRod)); });
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
      body: LayoutBuilder(builder: (context, constraints) {
        double w = constraints.maxWidth; double h = constraints.maxHeight;
        double centerX = w / 2; double bottomY = h - 70; // Прижали основание лучей к логотипу CARPOUT
        double maxRadiusPixels = h - 140;

        return Stack(children: [
          GestureDetector(
            onPanStart: (details) {
              double dx = details.localPosition.dx - centerX; double dy = bottomY - details.localPosition.dy;
              if (dy.abs() < 50) { setState(() { _isDragging = true; _dragDistance = 55.0; _dragAngle = dx / maxRadiusPixels; }); }
            },
            onPanUpdate: (details) {
              if (_isDragging) {
                double dx = details.localPosition.dx - centerX; double dy = bottomY - details.localPosition.dy;
                double factor = dy / maxRadiusPixels; if (factor < 0) factor = 0; if (factor > 1) factor = 1;
                setState(() { _dragDistance = 55.0 + (105.0 * factor); _dragAngle = dx / maxRadiusPixels; });
              }
            },
            onPanEnd: (details) {
              if (_isDragging) { setState(() { _isDragging = false; }); _addPointFromRadar(_dragDistance, _dragAngle); }
            },
            child: Container(width: w, height: h, color: Colors.transparent, child: CustomPaint(painter: CarpOutRadarPainter3D(savedPoints: _points, currentDragDist: _dragDistance, currentDragAngle: _dragAngle, isDragging: _isDragging, centerX: centerX, bottomY: bottomY, maxRadius: maxRadiusPixels))),
          ),
          Positioned(
            bottom: 20, right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1B2611),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFD4D9A1), width: 1.2), borderRadius: BorderRadius.circular(16)),
              onPressed: () {
                showModalBottomSheet(
                  context: context, backgroundColor: const Color(0xFF2E3B1E), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Column(children: [
                    const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))), const SizedBox(height: 16),
                    const Text('ЖУРНАЛ МАРКЕРНЫХ ТОЧЕК', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 12),
                    Expanded(child: _points.isEmpty ? const Center(child: Text('Нет сохраненных точек', style: TextStyle(color: Colors.white38))) : ListView.builder(itemCount: _points.length, itemBuilder: (context, index) {
                      final point = _points[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), color: const Color(0xFF1B2611), shape: RoundedRectangleBorder(side: BorderSide(color: const Color(0xFFD4D9A1).withOpacity(0.3))),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFFFF5252)), title: Text('${point.name} [${point.assignedRod}]', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('Дно: ${point.bottomType} | Гл: ${point.depth}м', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('${point.distance.toStringAsFixed(1)} м', style: const TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () { Navigator.pop(context); setState(() { _points.removeAt(index); }); _saveMarkerPoints(); }),
                          ]),
                        ),
                      );
                    })),
                  ])),
                );
              },
              icon: const Icon(Icons.analytics, color: Color(0xFFD4D9A1)), label: const Text('Журнал точек', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold)),
            ),
          ),
        ]);
      }),
    );
  }
}

// ===================================================================
// ЧАСТЬ 2Б: МАТЕМАТИЧЕСКИЙ ОТРИСОВЩИК ЛУЧЕЙ, ДУГ ДАЛЬНОСТИ И 3D-МИШЕНЕЙ
// ===================================================================
class CarpOutRadarPainter3D extends CustomPainter {
  final List<MarkerPoint> savedPoints; final double currentDragDist; final double currentDragAngle; final bool isDragging; final double centerX; final double bottomY; final double maxRadius;
  CarpOutRadarPainter3D({required this.savedPoints, required this.currentDragDist, required this.currentDragAngle, required this.isDragging, required this.centerX, required this.bottomY, required this.maxRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()..color = const Color(0xFFD4D9A1)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final dashPaint = Paint()..color = const Color(0xFF4A5D32).withOpacity(0.6)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFFFF5252)..style = PaintingStyle.fill;
    final livePaint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.fill;

    final textPaint = TextStyle(color: const Color(0xFFD4D9A1).withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold);
    final markerLabelPaint = TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: const Color(0xFF1B2611).withOpacity(0.85));

    for (int angle = -40; angle <= 40; angle += 10) {
      double pct = angle / 40.0;
      double endX = centerX + (maxRadius * pct * 0.85); double endY = bottomY - maxRadius;
      canvas.drawLine(Offset(centerX, bottomY), Offset(endX, endY), (angle % 20 == 0) ? mainPaint : dashPaint);
    }

    // МАССИВ ДУГ ДАЛЬНОСТИ ПОЛНОСТЬЮ ИСПРАВЛЕН И ЗАФИКСИРОВАН
    final List<int> distances = [60, 75, 90, 105, 120, 135, 150];
    for (int d in distances) {
      double radius = (d - 55) * maxRadius / 105;
      double startX = centerX - (radius * 0.65); double endX = centerX + (radius * 0.65); double targetY = bottomY - radius;
      
      final path = Path()..moveTo(startX, targetY)..quadraticBezierTo(centerX, targetY + (radius * 0.08), endX, targetY);
      canvas.drawPath(path, mainPaint);
      
      final textPainter = TextPainter(text: TextSpan(text: '${d}м', style: textPaint), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, targetY - 14));
    }

    for (var point in savedPoints) {
      double r = (point.distance - 55) * maxRadius / 105;
      double pX = centerX + (r * point.angle * 0.85); double pY = bottomY - r;

      canvas.drawCircle(Offset(pX, pY), 5, pointPaint);
      canvas.drawCircle(Offset(pX, pY), 10, mainPaint..strokeWidth = 1.2);
      
      String labelText = '${point.name} (${point.distance.toStringAsFixed(1)}м)\n[${point.assignedRod}] ${point.bottomType}';
      final labelPainter = TextPainter(text: TextSpan(text: labelText, style: markerLabelPaint), textDirection: TextDirection.ltr)..layout();
      labelPainter.paint(canvas, Offset(pX + 12, pY - 12));
    }

    if (isDragging) {
      double r = (currentDragDist - 55) * maxRadius / 105;
      double pX = centerX + (r * currentDragAngle * 0.85); double pY = bottomY - r;

      canvas.drawCircle(Offset(pX, pY), 7, livePaint);
      canvas.drawLine(Offset(centerX, bottomY), Offset(pX, pY), livePaint..strokeWidth = 1.0);

      final liveLabel = TextPainter(text: TextSpan(text: 'ЗАБРОС: ${currentDragDist.toStringAsFixed(1)} м', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11, backgroundColor: Colors.orangeAccent)), textDirection: TextDirection.ltr)..layout();
      liveLabel.paint(canvas, Offset(pX - liveLabel.width / 2, pY - 24));
    }

    final logoPainter = TextPainter(text: const TextSpan(text: 'CARPOUT', style: TextStyle(color: Color(0xFFD4D9A1), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)), textDirection: TextDirection.ltr)..layout();
    logoPainter.paint(canvas, Offset(centerX - logoPainter.width / 2, bottomY + 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CarpClipsCalculator extends StatefulWidget {
  const CarpClipsCalculator({Key? key}) : super(key: key);
  @override
  _CarpClipsCalculatorState createState() => _CarpClipsCalculatorState();
}

class _CarpClipsCalculatorState extends State<CarpClipsCalculator> {
  final _distanceController = TextEditingController();
  final _turnsController = TextEditingController();
  double _distanceBetweenSticks = 4.0;
  double _turnsResult = 0.0;
  double _metersResult = 0.0;

  void _calculateFromMeters() {
    double distance = double.tryParse(_distanceController.text) ?? 0.0;
    if (distance > 0 && _distanceBetweenSticks > 0) {
      setState(() { _turnsResult = distance / _distanceBetweenSticks; });
    } else { setState(() { _turnsResult = 0.0; }); }
  }

  void _calculateFromTurns() {
    double turns = double.tryParse(_turnsController.text) ?? 0.0;
    if (turns > 0 && _distanceBetweenSticks > 0) {
      setState(() { _metersResult = turns * _distanceBetweenSticks; });
    } else { setState(() { _metersResult = 0.0; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E3B1E),
      appBar: AppBar(backgroundColor: const Color(0xFF1B2611), title: const Text('Калькулятор Колышков', style: TextStyle(color: Color(0xFFD4D9A1), fontSize: 16, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Шаг 1: Дистанция между колышками', style: TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [_buildDistanceChip(3.0, '3 м'), const SizedBox(width: 8), _buildDistanceChip(4.0, '4 м (Стандарт)'), const SizedBox(width: 8), _buildDistanceChip(5.0, '5 м')]),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('Перевод метров в Обороты колышков', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                TextField(controller: _distanceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Дистанция ловли (метры)', labelStyle: TextStyle(color: Colors.white60)), onChanged: (v) => _calculateFromMeters()),
                const SizedBox(height: 12),
                Text('ТРЕБУЕТСЯ ОБОРОТОВ: ${_turnsResult.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4D9A1), fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1B2611), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('Перевод Оборотов в Метры на леске', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                TextField(controller: _turnsController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Количество оборотов на колышках', labelStyle: TextStyle(color: Colors.white60)), onChanged: (v) => _calculateFromTurns()),
                const SizedBox(height: 12),
                Text('ИСТИННАЯ ДИСТАНЦИЯ: ${_metersResult.toStringAsFixed(1)} м', style: const TextStyle(color: Color(0xFFD4D9A1), fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceChip(double value, String label) {
    bool isSelected = _distanceBetweenSticks == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
      selected: isSelected, selectedColor: const Color(0xFFD4D9A1), backgroundColor: const Color(0xFF1B2611),
      onSelected: (bool selected) { if (selected) { setState(() { _distanceBetweenSticks = value; if (_distanceController.text.isNotEmpty) _calculateFromMeters(); if (_turnsController.text.isNotEmpty) _calculateFromTurns(); }); } },
    );
  }
}
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
  final String lakeKey; final List<String> availableMarkers; // Передаем список маркерных точек для автоподстановки
  const CarpFeedScreen({Key? key, required this.lakeKey, required this.availableMarkers}) : super(key: key);
  @override
  _CarpFeedScreenState createState() => _CarpFeedScreenState();
}

class _CarpFeedScreenState extends State<CarpFeedScreen> with TickerProviderStateMixin {
  List<BaitMix> _mixes = []; List<PvaStickLog> _sticks = []; late TabController _tabController;
  int _timerSeconds = 2400; int _currentCountdown = 0; bool _isTimerRunning = false;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); _loadFeedData(); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

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
    String liquid = '🍓 Клубничный Ликвид'; String boilieType = 'Вареные бойлы'; String boilieSize = 'Крушеные бойлы'; final notesCtrl = TextEditingController();
    String selectedMarker = widget.availableMarkers.isNotEmpty ? widget.availableMarkers.first : 'Свободный закорм сектора';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF1B2611), title: const Text('Записать Сподовый Микс 🪣'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Выбрать точку на маркере:', style: TextStyle(color: Colors.white60, fontSize: 11))),
            DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: selectedMarker, isExpanded: true, style: const TextStyle(color: Color(0xFFD4D9A1), fontWeight: FontWeight.bold), items: (widget.availableMarkers.isNotEmpty ? widget.availableMarkers : ['Свободный закорм сектора']).map((s) => DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) { setDialogState(() { selectedMarker = v!; }); }),
            const SizedBox(height: 8),
            DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: liquid, isExpanded: true, style: const TextStyle(color: Colors.white), items: <String>['🍓 Клубничный Ликвид', '🍍 Ананасовый Амино', '🧄 Чесночный CSL', '🦀 Криль Натурал', '🚫 Без ликвида'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { liquid = v!; }); }),
            DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: boilieType, isExpanded: true, style: const TextStyle(color: Colors.white), items: <String>['Вареные бойлы', 'Растворимые бойлы', 'Пеллетс жирный', 'Зерновой микс'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { boilieType = v!; }); }),
            DropdownButton<String>(dropdownColor: const Color(0xFF1B2611), value: boilieSize, isExpanded: true, style: const TextStyle(color: Colors.white), items: <String>['Целые бойлы', 'Резаные (половинки)', 'Крушеные бойлы', 'Микс фракций'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { boilieSize = v!; }); }),
            TextField(controller: notesCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Заметка (кол-во спомбов)', labelStyle: TextStyle(color: Colors.white60))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { Navigator.pop(context); setState(() { _mixes.add(BaitMix(id: DateTime.now().millisecondsSinceEpoch.toString(), liquid: liquid, boilieType: boilieType, boilieSize: boilieSize, notes: '${notesCtrl.text.isEmpty ? 'Плановое кормление' : notesCtrl.text} -> Точка: $selectedMarker')); }); _saveFeedData(); }, child: const Text('Всыпать')),
        ],
      )),
    );
  }
  void _addStickDialog() {
    String pvaType = 'Сетка ПВА-стик'; String hookBait = 'Pop-up 10мм (Плавающий)';
    String selectedMarker = widget.availableMarkers.isNotEmpty ? widget.availableMarkers.first : 'Свободный заброс в сектор';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF3B4A22), title: const Text('Заброс поискового удилища 🎯'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft, child: Text('На какую маркерную точку бросаем:', style: TextStyle(color: Colors.white60, fontSize: 11))),
            DropdownButton<String>(dropdownColor: const Color(0xFF3B4A22), value: selectedMarker, isExpanded: true, style: const TextStyle(color: Color(0xFFE8ECD0), fontWeight: FontWeight.bold), items: (widget.availableMarkers.isNotEmpty ? widget.availableMarkers : ['Свободный заброс в сектор']).map((s) => DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) { setDialogState(() { selectedMarker = v!; }); }),
            const SizedBox(height: 8),
            DropdownButton<String>(dropdownColor: const Color(0xFF3B4A22), value: pvaType, isExpanded: true, style: const TextStyle(color: Colors.white), items: <String>['Сетка ПВА-стик', 'ПВА-пакет (с пеллетсом)', '🚫 Без ПВА (одиночная)'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { pvaType = v!; }); }),
            DropdownButton<String>(dropdownColor: const Color(0xFF3B4A22), value: hookBait, isExpanded: true, style: const TextStyle(color: Colors.white), items: <String>['Pop-up 10мм (Плавающий)', 'Wafters (Сбалансированный)', 'Искусственная кукуруза', 'Двойной тонущий 20мм'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setDialogState(() { hookBait = v!; }); }),
          ]),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена', style: TextStyle(color: Colors.white60))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { final now = DateTime.now(); Navigator.pop(context); String detectedRod = 'Поиск'; if (selectedMarker.contains('[') && selectedMarker.contains(']')) { detectedRod = selectedMarker.substring(selectedMarker.indexOf('[') + 1, selectedMarker.indexOf(']')); } setState(() { _sticks.add(PvaStickLog(id: now.millisecondsSinceEpoch.toString(), pvaType: pvaType, hookBait: hookBait, rodType: detectedRod, time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}')); }); _saveFeedData(); }, child: const Text('В точку!')),
        ],
      )),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF556B2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B4A22), title: const Text('Тактика Питания & Timing', style: TextStyle(color: Color(0xFFE8ECD0), fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(controller: _tabController, labelColor: const Color(0xFFE8ECD0), unselectedLabelColor: Colors.white54, indicatorColor: const Color(0xFFE8ECD0), tabs: const [Tab(icon: Icon(Icons.restaurant), text: 'Миксы'), Tab(icon: Icon(Icons.gpp_good), text: 'Стики'), Tab(icon: Icon(Icons.timer), text: 'Таймер')]),
      ),
      body: TabBarView(controller: _tabController, children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('История кормления сектора:', style: TextStyle(color: Color(0xFFE8ECD0), fontWeight: FontWeight.bold, fontSize: 13)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B4A22), side: const BorderSide(color: Color(0xFFE8ECD0))), onPressed: _addMixDialog, icon: const Icon(Icons.add, color: Color(0xFFE8ECD0), size: 16), label: const Text('Корм', style: TextStyle(color: Color(0xFFE8ECD0), fontSize: 12)))]),
            const SizedBox(height: 10),
            Expanded(child: _mixes.isEmpty ? const Center(child: Text('Сводка пуста.', style: TextStyle(color: Colors.white38))) : ListView.builder(itemCount: _mixes.length, itemBuilder: (context, idx) { final m = _mixes[_mixes.length - 1 - idx]; return Card(color: const Color(0xFF3B4A22), margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.opacity, color: Color(0xFFC5E1A5)), title: Text(m.liquid, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text('База: ${m.boilieType}\nИнфо: ${m.notes}', style: const TextStyle(color: Colors.white70, fontSize: 12)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () { setState(() { _mixes.remove(m); }); _saveFeedData(); }))); })),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Active насадки:', style: TextStyle(color: Color(0xFFE8ECD0), fontWeight: FontWeight.bold, fontSize: 13)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B4A22), side: const BorderSide(color: Color(0xFFE8ECD0))), onPressed: _addStickDialog, icon: const Icon(Icons.gps_fixed, color: Color(0xFFE8ECD0), size: 16), label: const Text('Заброс', style: TextStyle(color: Color(0xFFE8ECD0), fontSize: 12)))]),
            const SizedBox(height: 10),
            Expanded(child: _sticks.isEmpty ? const Center(child: Text('Нет забросов', style: TextStyle(color: Colors.white38))) : ListView.builder(itemCount: _sticks.length, itemBuilder: (context, idx) { final s = _sticks[_sticks.length - 1 - idx]; return Card(color: const Color(0xFF3B4A22), margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.track_changes, color: Color(0xFFFF5252)), title: Text('${s.rodType} [${s.time}]', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text('ПВА: ${s.pvaType}\nПрезентация: ${s.hookBait}', style: const TextStyle(color: Colors.white70, fontSize: 12)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () { setState(() { _sticks.remove(s); }); _saveFeedData(); }))); })),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('ТАЙМЕР ОБНОВЛЕНИЯ ТОЧЕК', style: TextStyle(color: Color(0xFFE8ECD0), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              width: 190, height: 190, decoration: BoxDecoration(color: const Color(0xFF3B4A22), shape: BoxShape.circle, border: Border.all(color: _isTimerRunning ? const Color(0xFFE8ECD0) : Colors.white24, width: 4)),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isTimerRunning ? '${(_currentCountdown ~/ 60)}:${(_currentCountdown % 60).toString().padLeft(2, '0')}' : '${(_timerSeconds ~/ 60)}:00', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _isTimerRunning ? const Color(0xFFE8ECD0) : Colors.white)), const SizedBox(height: 4), Text(_isTimerRunning ? 'ИДЕТ ОТСЧЕТ' : 'ОЖИДАНИЕ', style: TextStyle(color: _isTimerRunning ? const Color(0xFFC5E1A5) : Colors.white38, fontSize: 10))])),
            ),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildTimerPresetAction(2400, '40 мин'), const SizedBox(width: 8), _buildTimerPresetAction(3600, '1 час'), const SizedBox(width: 8), _buildTimerPresetAction(7200, '2 часа')]),
            const SizedBox(height: 35),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 130, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _isTimerRunning ? Colors.orange.shade900 : const Color(0xFF4A5D32)), onPressed: () { if (_isTimerRunning) { setState(() { _isTimerRunning = false; }); } else { setState(() { _isTimerRunning = true; _currentCountdown = _timerSeconds; }); _startCountdownLoop(); } }, child: Text(_isTimerRunning ? 'Пауза' : 'Старт', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              SizedBox(width: 130, height: 48, child: OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)), onPressed: () { setState(() { _isTimerRunning = false; _currentCountdown = 0; }); }, child: const Text('Сброс', style: TextStyle(color: Colors.white70)))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTimerPresetAction(int secs, String label) { bool isSelected = _timerSeconds == secs; return ChoiceChip(label: Text(label, style: TextStyle(color: isSelected ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)), selected: isSelected, selectedColor: const Color(0xFFE8ECD0), backgroundColor: const Color(0xFF3B4A22), onSelected: (b) { if (b) { setState(() { _timerSeconds = secs; if (_isTimerRunning) _currentCountdown = secs; }); } }); }
  void _startCountdownLoop() async { while (_isTimerRunning && _currentCountdown > 0) { await Future.delayed(const Duration(seconds: 1)); if (!mounted || !_isTimerRunning) return; setState(() { _currentCountdown--; if (_currentCountdown <= 0) { _isTimerRunning = false; _showTimerAlert(); } }); } }
  void _showTimerAlert() { showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFFFF5252), title: const Text('ВРЕМЯ ПЕРЕЗАБРОСА! ⏱️🔥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), content: const Text('Пора обновить оснастку!', style: TextStyle(color: Colors.white)), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B4A22)), onPressed: () { Navigator.pop(context); }, child: const Text('Принято', style: TextStyle(color: Colors.white)))])).then((_) { if (Navigator.canPop(context)) Navigator.pop(context); }); }
}
class FishTrophy {
  String id; String weight; String date; String bait; String note; String? imagePath;
  FishTrophy({required this.id, required this.weight, required this.date, required this.bait, required this.note, this.imagePath});
  Map<String, dynamic> toJson() => {'id': id, 'weight': weight, 'date': date, 'bait': bait, 'note': note, 'imagePath': imagePath};
  factory FishTrophy.fromJson(Map<String, dynamic> json) => FishTrophy(id: json['id'] ?? '', weight: json['weight'] ?? '0.000', date: json['date'] ?? '', bait: json['bait'] ?? '', note: json['note'] ?? '', imagePath: json['imagePath']);
}

class FishSocialScreen extends StatefulWidget {
  final String lakeKey;
  const FishSocialScreen({Key? key, required this.lakeKey}) : super(key: key);
  @override
  _FishSocialScreenState createState() => _FishSocialScreenState();
}

class _FishSocialScreenState extends State<FishSocialScreen> {
  List<FishTrophy> _trophies = []; final _weightController = TextEditingController(); final _baitController = TextEditingController(); final _noteController = TextEditingController(); String? _selectedImagePath; final ImagePicker _picker = ImagePicker();

  @override
  void initState() { super.initState(); _loadTrophies(); }
  @override
  void didUpdateWidget(covariant FishSocialScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.lakeKey != widget.lakeKey) { _loadTrophies(); } }

  Future<void> _loadTrophies() async {
    final prefs = await SharedPreferences.getInstance(); final String? trophiesJson = prefs.getString('trophies_${widget.lakeKey}');
    setState(() { if (trophiesJson != null) { final List<dynamic> decoded = jsonDecode(trophiesJson); _trophies = decoded.map((item) => FishTrophy.fromJson(item)).toList(); } else { _trophies = []; } _sortTrophies(); });
  }

  Future<void> _saveTrophies() async { final prefs = await SharedPreferences.getInstance(); final String encoded = jsonEncode(_trophies.map((t) => t.toJson()).toList()); await prefs.setString('trophies_${widget.lakeKey}', encoded); }
  void _sortTrophies() { _trophies.sort((a, b) => b.id.compareTo(a.id)); }

  Future<void> _pickImage(ImageSource source, Function setDialogState) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      final Directory appDir = await getApplicationDocumentsDirectory(); final String fileName = 'trophy_${DateTime.now().millisecondsSinceEpoch}.png'; final File savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setDialogState(() { _selectedImagePath = savedImage.path; });
    }
  }

  void _addTrophyDialog() {
    _weightController.clear(); _baitController.clear(); _noteController.clear(); _selectedImagePath = null;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF3B4A22), title: const Text('🏆 Зафиксировать Трофей'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Вес рыбы (кг)', labelStyle: TextStyle(color: Colors.white60))),
            TextField(controller: _baitController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Насадка / Презентация', labelStyle: TextStyle(color: Colors.white60))),
            TextField(controller: _noteController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Заметка', labelStyle: TextStyle(color: Colors.white60))),
            const SizedBox(height: 16),
            _selectedImagePath != null ? Container(height: 100, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(_selectedImagePath!)), fit: BoxFit.cover))) : const Text('Фото не выбрано', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () => _pickImage(ImageSource.camera, setDialogState), icon: const Icon(Icons.camera_alt, size: 16), label: const Text('Камера', style: TextStyle(fontSize: 11))),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () => _pickImage(ImageSource.gallery, setDialogState), icon: const Icon(Icons.photo_library, size: 16), label: const Text('Галерея', style: TextStyle(fontSize: 11))),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)),
            onPressed: () async { if (_weightController.text.isNotEmpty) { Navigator.pop(context); final now = DateTime.now(); setState(() { _trophies.add(FishTrophy(id: now.millisecondsSinceEpoch.toString(), weight: _weightController.text, date: '${now.day}.${now.month}.${now.year}', bait: _baitController.text.isEmpty ? 'Не указана' : _baitController.text, note: _noteController.text.isEmpty ? 'Без заметок' : _noteController.text, imagePath: _selectedImagePath)); _sortTrophies(); }); await _saveTrophies(); } },
            child: const Text('В журнал'),
          ),
        ],
      )),
    );
  }

  void _viewAndEditDetails(FishTrophy trophy, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3B4A22), title: Text('Трофей ${trophy.weight} кг'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          trophy.imagePath != null ? Container(height: 180, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(File(trophy.imagePath!)), fit: BoxFit.cover))) : Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.photo, color: Colors.white24, size: 40)),
          const SizedBox(height: 16), Text('📅 Дата: ${trophy.date}'), const SizedBox(height: 8), Text('🎣 Насадка: ${trophy.bait}'), const SizedBox(height: 8), Text('📝 Заметка: ${trophy.note}'),
        ]),
        actions: [
          TextButton(style: TextButton.styleFrom(foregroundColor: Colors.redAccent), onPressed: () async { Navigator.pop(context); setState(() { _trophies.removeAt(index); }); await _saveTrophies(); }, child: const Text('Удалить')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5D32)), onPressed: () { Navigator.pop(context); }, child: const Text('Закрыть')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF556B2F),
      appBar: AppBar(backgroundColor: const Color(0xFF3B4A22), title: const Text('Журнал Ваших Трофеев 🏆'), actions: [IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addTrophyDialog)]),
      body: _trophies.isEmpty
          ? const Center(child: Text('Лента пуста.', style: TextStyle(color: Colors.white38)))
          : GridView.builder(
              padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82), itemCount: _trophies.length,
              itemBuilder: (context, index) {
                final trophy = _trophies[index];
                return GestureDetector(
                  onTap: () => _viewAndEditDetails(trophy, index),
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF3B4A22), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8ECD0).withOpacity(0.2))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: trophy.imagePath != null ? Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(11)), image: DecorationImage(image: FileImage(File(trophy.imagePath!)), fit: BoxFit.cover))) : Container(width: double.infinity, decoration: const BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.vertical(top: Radius.circular(11))), child: const Icon(Icons.phishing, color: Colors.white24, size: 32))),
                      Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${trophy.weight} кг', style: const TextStyle(color: Color(0xFFE8ECD0), fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(trophy.bait, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 2), Text(trophy.date.split(' ').first, style: const TextStyle(color: Colors.white38, fontSize: 10))])),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
