import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/messaging/group_service.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedPeerIds = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPeerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 group member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final groupService = context.read<GroupService>();

    try {
      final groupId = await groupService.createGroup(
        _nameController.text.trim(),
        _selectedPeerIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to the new group chat and remove CreateGroupScreen from the backstack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              groupId: groupId,
              groupName: _nameController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meshService = context.watch<MeshNetworkService>();
    final peers = meshService.peers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group Chat'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Members (${_selectedPeerIds.length} selected)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: peers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No nearby devices found. Make sure nearby devices have the app open and discoverable.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: peers.length,
                      itemBuilder: (context, index) {
                        final peer = peers[index];
                        final isSelected = _selectedPeerIds.contains(peer.id);
                        return CheckboxListTile(
                          title: Text(peer.name),
                          subtitle: Text(peer.status.name),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedPeerIds.add(peer.id);
                              } else {
                                _selectedPeerIds.remove(peer.id);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            child: Text(peer.name[0].toUpperCase()),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
