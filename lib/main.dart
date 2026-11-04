import 'package:flutter/material.dart';

void main() => runApp(const CalorieTrackerApp());

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        scaffoldBackgroundColor: const Color(0xFFF4F7F4),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Simple model for a food entry.
class FoodItem {
  final String name;
  final int calories;
  FoodItem({required this.name, required this.calories});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int dailyGoal = 2000;

  // Local in-memory list (resets when the app restarts).
  final List<FoodItem> _foods = [];

  int get _total => _foods.fold(0, (sum, f) => sum + f.calories);
  int get _remaining => dailyGoal - _total;

  String get _todayText {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _showAddFoodDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();

    final result = await showDialog<FoodItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Food'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  prefixIcon: Icon(Icons.restaurant),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a food name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  prefixIcon: Icon(Icons.local_fire_department),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter the calorie amount';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  ctx,
                  FoodItem(
                    name: nameCtrl.text.trim(),
                    calories: int.parse(calCtrl.text.trim()),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _foods.add(result));
    }
  }

  void _deleteFood(int index) {
    final removed = _foods[index];
    setState(() => _foods.removeAt(index));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${removed.name} removed')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon/app_icon.png',
                  width: 32, height: 32),
            ),
            const SizedBox(width: 10),
            const Text('Calorie Tracker',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date + total summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(_todayText,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        const Text('Calories Consumed Today',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          '$_total kcal',
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_total / dailyGoal).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            color: _remaining < 0
                                ? Colors.red
                                : scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Three info cards
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Row(
              children: [
                _InfoCard(
                  title: 'Total',
                  value: '$_total',
                  icon: Icons.restaurant_menu,
                  color: Colors.orange,
                ),
                _InfoCard(
                  title: 'Daily Goal',
                  value: '$dailyGoal',
                  icon: Icons.flag,
                  color: Colors.blue,
                ),
                _InfoCard(
                  title: _remaining < 0 ? 'Over By' : 'Remaining',
                  value: '${_remaining.abs()}',
                  icon: Icons.hourglass_bottom,
                  color: _remaining < 0 ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),

          // Section title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Food List (${_foods.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),

          // Food list
          Expanded(
            child: _foods.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_meals,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No food added yet.\nTap "Add Food" to start!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: _foods.length,
                    itemBuilder: (context, index) {
                      final food = _foods[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(Icons.fastfood,
                                color: Colors.orange),
                          ),
                          title: Text(food.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text('${food.calories} kcal'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            tooltip: 'Delete',
                            onPressed: () => _deleteFood(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const Text('kcal',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
