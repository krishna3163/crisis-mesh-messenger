import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/market_listing.dart';
import 'package:crisis_mesh/core/services/community/community_service.dart';

class MarketTab extends StatefulWidget {
  const MarketTab({super.key});

  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  String _selectedFilter = 'ALL'; // 'ALL', 'OFFER', 'REQUEST'
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  String _type = 'OFFER';
  String _category = 'Food';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _showCreateListingDialog(CommunityService service) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Barter Listing'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Listing Type'),
                        items: const [
                          DropdownMenuItem(value: 'OFFER', child: Text('I Have (Offer)')),
                          DropdownMenuItem(value: 'REQUEST', child: Text('I Need (Request)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => _type = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(value: 'Water', child: Text('Water')),
                          DropdownMenuItem(value: 'Meds', child: Text('Meds/Medical')),
                          DropdownMenuItem(value: 'Fuel', child: Text('Fuel/Power')),
                          DropdownMenuItem(value: 'Gear', child: Text('Gear/Tools')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Item Name (e.g. AA Batteries)'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter item name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Description/Condition'),
                        maxLines: 2,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              decoration: const InputDecoration(labelText: 'Quantity'),
                              keyboardType: TextInputType.number,
                              validator: (v) => double.tryParse(v ?? '') == null ? 'Enter number' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(labelText: 'Unit (e.g. pack, L)'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter unit' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    
                    await service.addMarketListing(
                      _titleController.text.trim(),
                      _descController.text.trim(),
                      _type,
                      _category,
                      double.parse(_qtyController.text),
                      _unitController.text.trim(),
                    );

                    _titleController.clear();
                    _descController.clear();
                    _qtyController.clear();
                    _unitController.clear();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Listing shared over offline mesh market!')),
                      );
                    }
                  },
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    return type.toUpperCase() == 'OFFER' ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final communityService = context.watch<CommunityService>();
    final allListings = communityService.getListings();

    final filteredListings = allListings.where((l) {
      if (_selectedFilter == 'ALL') return true;
      return l.listingType.toUpperCase() == _selectedFilter;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Listings'),
                  selected: _selectedFilter == 'ALL',
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = 'ALL');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Offers'),
                  selected: _selectedFilter == 'OFFER',
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = 'OFFER');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Requests'),
                  selected: _selectedFilter == 'REQUEST',
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = 'REQUEST');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredListings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'No listings found on this channel.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      final item = filteredListings[index];
                      final typeColor = _getTypeColor(item.listingType);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.listingType,
                                      style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                  Text(
                                    item.category,
                                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Quantity: ${item.quantity} ${item.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'By: ${item.creatorName}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateListingDialog(communityService),
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
      ),
    );
  }
}
