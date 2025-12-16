import 'package:flutter/material.dart';

// Minimal single-file Flutter app: Athlete tracker with in-memory data and
// simple charts (CustomPainter). No extra dependencies and Android-ready.
// Features:
// - Home: list of athletes (add/delete) and a Bests bar chart (max record per athlete).
// - Detail: per-athlete records (add/delete) and a Progress line chart over time.
// - All state in memory; no persistence (keeps this demo minimal).
// Note: Keep this file as the only change. pubspec.yaml left as-is.

void main() {
  runApp(const AthleteApp());
}

class AthleteApp extends StatelessWidget {
  const AthleteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Athlete Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PinGate(),
    );
  }
}

// Simple in-memory PIN gate. On first use, requires setting a 4-digit PIN.
// On subsequent unlocks, requires entering the PIN. Also exposes a way to relock from Home.
class PinGate extends StatefulWidget {
  const PinGate({super.key});

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  String? _pin; // in-memory only
  bool _unlocked = false;

  void _onSetPin(String pin) {
    setState(() {
      _pin = pin;
      _unlocked = true;
    });
  }

  void _onUnlock() {
    setState(() => _unlocked = true);
  }

  void _onRelock() {
    setState(() => _unlocked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      if (_pin == null) {
        return PinLockScreen(
          mode: PinMode.setPin,
          onPinSet: _onSetPin,
        );
      } else {
        return PinLockScreen(
          mode: PinMode.unlock,
          expectedPin: _pin,
          onUnlocked: _onUnlock,
        );
      }
    }
    return HomeScreen(onRelock: _onRelock);
  }
}

enum PinMode { setPin, unlock }

class PinLockScreen extends StatefulWidget {
  final PinMode mode;
  final String? expectedPin; // required for unlock
  final void Function(String)? onPinSet; // used for setPin mode
  final VoidCallback? onUnlocked; // used for unlock mode

  const PinLockScreen({
    super.key,
    required this.mode,
    this.expectedPin,
    this.onPinSet,
    this.onUnlocked,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  void _handleSetPin() {
    final a = _pin1.text.trim();
    final b = _pin2.text.trim();
    if (a.length != 4 || int.tryParse(a) == null) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }
    if (a != b) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    widget.onPinSet?.call(a);
  }

  void _handleUnlock() {
    final a = _pin1.text.trim();
    if (a == widget.expectedPin) {
      widget.onUnlocked?.call();
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSet = widget.mode == PinMode.setPin;
    return Scaffold(
      appBar: AppBar(title: Text(isSet ? 'Set PIN' : 'Unlock')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSet) ...[
                    const Text('Create a 4-digit PIN to protect the app.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pin1,
                      decoration: const InputDecoration(labelText: 'Enter PIN (4 digits)'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                    ),
                    TextField(
                      controller: _pin2,
                      decoration: const InputDecoration(labelText: 'Confirm PIN'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                    ),
                    const SizedBox(height: 8),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _handleSetPin,
                      icon: const Icon(Icons.lock),
                      label: const Text('Set PIN'),
                    ),
                  ] else ...[
                    const Text('Enter your 4-digit PIN'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pin1,
                      decoration: const InputDecoration(labelText: 'PIN'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      onSubmitted: (_) => _handleUnlock(),
                    ),
                    const SizedBox(height: 8),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _handleUnlock,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Unlock'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

  const AthleteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Athlete Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Record {
  final DateTime date;
  final double value;
  Record(this.date, this.value);
}

class Athlete {
  final String name;
  final List<Record> records;
  Athlete({required this.name, List<Record>? records}) : records = records ?? [];

  double? get best => records.isEmpty
      ? null
      : records.map((r) => r.value).reduce((a, b) => a > b ? a : b);
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onRelock;
  const HomeScreen({super.key, this.onRelock});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Athlete> _athletes = [
    Athlete(name: 'Alex', records: [
      Record(DateTime.now().subtract(const Duration(days: 10)), 12.2),
      Record(DateTime.now().subtract(const Duration(days: 5)), 12.0),
      Record(DateTime.now(), 11.8),
    ]),
    Athlete(name: 'Blake', records: [
      Record(DateTime.now().subtract(const Duration(days: 7)), 9.5),
      Record(DateTime.now().subtract(const Duration(days: 2)), 10.2),
    ]),
  ];

  Future<void> _addAthleteDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add athlete'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _athletes.add(Athlete(name: name)));
    }
  }

  void _deleteAthlete(int index) {
    setState(() => _athletes.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Tracker'),
        actions: [
          IconButton(
            tooltip: 'Lock',
            icon: const Icon(Icons.lock_outline),
            onPressed: widget.onRelock,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAthleteDialog,
        label: const Text('Add athlete'),
        icon: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          // Bests chart card
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 180,
                  child: BestsBarChart(athletes: _athletes),
                ),
              ),
            ),
          ),
          const Divider(height: 0),
          // Athletes list
          Expanded(
            child: _athletes.isEmpty
                ? const Center(child: Text('No athletes. Tap "+" to add.'))
                : ListView.separated(
                    itemCount: _athletes.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final a = _athletes[index];
                      return Dismissible(
                        key: ValueKey('athlete_${a.name}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteAthlete(index),
                        child: ListTile(
                          title: Text(a.name),
                          subtitle: Text(
                            a.best == null ? 'No records yet' : 'Best: ${a.best!.toStringAsFixed(2)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AthleteDetailScreen(
                                  athlete: a,
                                  onChanged: () => setState(() {}),
                                ),
                              ),
                            );
                          },
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

class AthleteDetailScreen extends StatefulWidget {
  final Athlete athlete;
  final VoidCallback onChanged;
  const AthleteDetailScreen({super.key, required this.athlete, required this.onChanged});

  @override
  State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  Future<void> _addRecordDialog() async {
    final valueController = TextEditingController();
    DateTime date = DateTime.now();

    final result = await showDialog<(DateTime, double)?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocalState) {
          return AlertDialog(
            title: const Text('Add record'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Value (number)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Date: '),
                    Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setLocalState(() => date = picked);
                      },
                      child: const Text('Pick'),
                    )
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final v = double.tryParse(valueController.text.trim());
                  if (v != null) {
                    Navigator.pop(ctx, (date, v));
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );

    if (result != null) {
      setState(() => widget.athlete.records.add(Record(result.$1, result.$2)));
      widget.onChanged();
    }
  }

  void _deleteRecord(int index) {
    setState(() => widget.athlete.records.removeAt(index));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.athlete;
    final recordsSorted = [...a.records]..sort((x, y) => x.date.compareTo(y.date));

    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecordDialog,
        label: const Text('Add record'),
        icon: const Icon(Icons.add_chart),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 220,
                  child: ProgressLineChart(records: recordsSorted),
                ),
              ),
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: recordsSorted.isEmpty
                ? const Center(child: Text('No records yet. Tap "+" to add.'))
                : ListView.separated(
                    itemCount: recordsSorted.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final r = recordsSorted[index];
                      return Dismissible(
                        key: ValueKey('record_${r.date.millisecondsSinceEpoch}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteRecord(index),
                        child: ListTile(
                          title: Text(r.value.toStringAsFixed(2)),
                          subtitle: Text(
                            '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}',
                          ),
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

// ---------- Charts ----------

class BestsBarChart extends StatelessWidget {
  final List<Athlete> athletes;
  const BestsBarChart({super.key, required this.athletes});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BestsBarChartPainter(athletes: athletes),
      child: Container(),
    );
  }
}

class _BestsBarChartPainter extends CustomPainter {
  final List<Athlete> athletes;
  _BestsBarChartPainter({required this.athletes});

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 12.0;
    final axisPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.0;
    final barPaint = Paint()..color = Colors.blueAccent;

    final chartRect = Rect.fromLTWH(padding, padding, size.width - 2 * padding, size.height - 2 * padding);

    // Axes
    canvas.drawLine(Offset(chartRect.left, chartRect.bottom), Offset(chartRect.right, chartRect.bottom), axisPaint);
    canvas.drawLine(Offset(chartRect.left, chartRect.bottom), Offset(chartRect.left, chartRect.top), axisPaint);

    final bests = athletes.map((a) => a.best ?? 0).toList();
    final labels = athletes.map((a) => a.name).toList();
    final maxVal = (bests.isEmpty ? 0 : bests.reduce((a, b) => a > b ? a : b));
    final yMax = maxVal == 0 ? 1.0 : maxVal * 1.1;

    final count = bests.length;
    if (count == 0) {
      _drawCenteredText(canvas, size, 'No data');
      return;
    }

    final barWidth = chartRect.width / (count * 1.8);
    for (int i = 0; i < count; i++) {
      final xCenter = chartRect.left + (i + 0.5) * (chartRect.width / count);
      final barHeight = (bests[i] / yMax) * chartRect.height;
      final barRect = Rect.fromCenter(
        center: Offset(xCenter, chartRect.bottom - barHeight / 2),
        width: barWidth,
        height: barHeight,
      );
      canvas.drawRect(barRect, barPaint);

      _drawSmallLabel(canvas, Offset(xCenter, chartRect.bottom + 10), labels[i], alignCenter: true);
    }

    // Y max label
    _drawSmallLabel(canvas, Offset(chartRect.left - 6, chartRect.top), yMax.toStringAsFixed(1), alignRight: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProgressLineChart extends StatelessWidget {
  final List<Record> records;
  const ProgressLineChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProgressLineChartPainter(records: records),
      child: Container(),
    );
  }
}

class _ProgressLineChartPainter extends CustomPainter {
  final List<Record> records;
  _ProgressLineChartPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 12.0;
    final axisPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.0;
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = Colors.green;

    final chartRect = Rect.fromLTWH(padding, padding, size.width - 2 * padding, size.height - 2 * padding);

    // Axes
    canvas.drawLine(Offset(chartRect.left, chartRect.bottom), Offset(chartRect.right, chartRect.bottom), axisPaint);
    canvas.drawLine(Offset(chartRect.left, chartRect.bottom), Offset(chartRect.left, chartRect.top), axisPaint);

    if (records.isEmpty) {
      _drawCenteredText(canvas, size, 'No data');
      return;
    }

    final dates = records.map((r) => r.date.millisecondsSinceEpoch.toDouble()).toList();
    final values = records.map((r) => r.value).toList();

    final minX = dates.reduce((a, b) => a < b ? a : b);
    final maxX = dates.reduce((a, b) => a > b ? a : b);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);

    final xSpan = (maxX - minX).abs() < 1e-6 ? 1.0 : (maxX - minX);
    final ySpan = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY);

    Path path = Path();
    for (int i = 0; i < records.length; i++) {
      final x = chartRect.left + ((dates[i] - minX) / xSpan) * chartRect.width;
      final y = chartRect.bottom - ((values[i] - minY) / ySpan) * chartRect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Points
    for (int i = 0; i < records.length; i++) {
      final x = chartRect.left + ((dates[i] - minX) / xSpan) * chartRect.width;
      final y = chartRect.bottom - ((values[i] - minY) / ySpan) * chartRect.height;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    // Labels
    _drawSmallLabel(canvas, Offset(chartRect.left - 6, chartRect.top), maxY.toStringAsFixed(1), alignRight: true);
    _drawSmallLabel(canvas, Offset(chartRect.left - 6, chartRect.bottom), minY.toStringAsFixed(1), alignRight: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ----- Text helpers for painters -----
void _drawCenteredText(Canvas canvas, Size size, String text) {
  final tp = TextPainter(
    text: TextSpan(style: const TextStyle(color: Colors.black54, fontSize: 12), text: text),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
}

void _drawSmallLabel(Canvas canvas, Offset pos, String text, {bool alignRight = false, bool alignCenter = false}) {
  final tp = TextPainter(
    text: TextSpan(style: const TextStyle(color: Colors.black54, fontSize: 10), text: text),
    textDirection: TextDirection.ltr,
  )..layout();

  Offset offset = pos;
  if (alignRight) {
    offset = Offset(pos.dx - tp.width, pos.dy - tp.height / 2);
  } else if (alignCenter) {
    offset = Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2);
  }
  tp.paint(canvas, offset);
}
