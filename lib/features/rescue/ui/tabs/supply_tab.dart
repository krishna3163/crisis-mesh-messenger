import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/medical_supply.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';

class SupplyTab extends StatefulWidget {
  const SupplyTab({super.key});

  @override
  State<SupplyTab> createState() => _SupplyTabState();
}

class _SupplyTabState extends State<SupplyTab> {
  final _qtyController = TextEditingController();
  final _thresholdController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _showAdjustStockDialog(BuildContext context, MedicalSupply item) {
    _qtyController.text = item.quantity.toString();
    _thresholdController.text = item.lowStockThreshold.toString();

    final service = context.read<RescueMedicalService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _qtyController,
              decoration: InputDecoration(labelText: 'Current Stock (${item.unit})', border: const OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _thresholdController,
              decoration: const InputDecoration(labelText: 'Low Stock Alert Threshold', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQty = double.tryParse(_qtyController.text) ?? item.quantity;
              final newThreshold = double.tryParse(_thresholdController.text) ?? item.lowStockThreshold;

              final updated = item.copyWith(
                quantity: newQty,
                lowStockThreshold: newThreshold,
                timestamp: DateTime.now(),
              );

              Navigator.pop(context);
              await service.saveSupply(updated);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} stock level updated!')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _quickAdd(BuildContext context, MedicalSupply item, double delta) async {
    final service = context.read<RescueMedicalService>();
    final updated = item.copyWith(
      quantity: (item.quantity + delta).clamp(0.0, double.infinity),
      timestamp: DateTime.now(),
    );
    await service.saveSupply(updated);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'FIRST_AID':
        return Icons.healing;
      case 'MEDICINE':
        return Icons.medication;
      case 'BLOOD':
        return Icons.bloodtype;
      case 'OXYGEN':
        return Icons.air;
      default:
        return Icons.inventory;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'FIRST_AID':
        return Colors.green;
      case 'MEDICINE':
        return Colors.blue;
      case 'BLOOD':
        return Colors.red;
      case 'OXYGEN':
        return Colors.teal;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<RescueMedicalService>();
    final supplies = service.getSupplies();

    // Group supplies by category
    final Map<String, List<MedicalSupply>> grouped = {};
    for (final item in supplies) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final lowStockItems = supplies.where((s) => s.quantity <= s.lowStockThreshold).toList();

    return Scaffold(
      body: Column(
        children: [
          if (lowStockItems.isNotEmpty) ...[
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Low Stock Alert: ${lowStockItems.length} items are running low!',
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: supplies.isEmpty
                ? const Center(child: Text('No supply inventories registered.'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.keys.map((category) {
                      final items = grouped[category]!;
                      final color = _getCategoryColor(category);
                      final icon = _getCategoryIcon(category);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  category.replaceFirst('_', ' '),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          ...items.map((item) {
                            final isLow = item.quantity <= item.lowStockThreshold;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isLow ? BorderSide(color: Colors.red.shade300, width: 1.5) : BorderSide.none,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isLow ? Colors.red.shade50 : color.withOpacity(0.1),
                                  child: Icon(icon, color: isLow ? Colors.red : color),
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Low Alert Threshold: ${item.lowStockThreshold} ${item.unit}',
                                  style: TextStyle(color: isLow ? Colors.red.shade700 : Colors.grey, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () => _quickAdd(context, item, -1),
                                      tooltip: 'Subtract 1',
                                    ),
                                    Text(
                                      '${item.quantity.toInt()} ${item.unit}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLow ? Colors.red.shade700 : null,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () => _quickAdd(context, item, 1),
                                      tooltip: 'Add 1',
                                    ),
                                  ],
                                ),
                                onTap: () => _showAdjustStockDialog(context, item),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
