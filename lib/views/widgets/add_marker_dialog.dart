import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_marker.dart';

class AddMarkerDialog extends StatefulWidget {
  final LatLng position;
  final Function(UserMarker) onAdd;

  const AddMarkerDialog({
    super.key,
    required this.position,
    required this.onAdd,
  });

  @override
  State<AddMarkerDialog> createState() => _AddMarkerDialogState();
}

class _AddMarkerDialogState extends State<AddMarkerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _userNameController = TextEditingController();
  MarkerType _selectedType = MarkerType.note;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  IconData _getIconForType(MarkerType type) {
    switch (type) {
      case MarkerType.photo:
        return Icons.photo_camera;
      case MarkerType.note:
        return Icons.note;
      case MarkerType.warning:
        return Icons.warning;
      case MarkerType.event:
        return Icons.event;
      case MarkerType.place:
        return Icons.place;
    }
  }

  Color _getColorForType(MarkerType type) {
    switch (type) {
      case MarkerType.photo:
        return Colors.green;
      case MarkerType.note:
        return Colors.blue;
      case MarkerType.warning:
        return Colors.red;
      case MarkerType.event:
        return Colors.purple;
      case MarkerType.place:
        return Colors.orange;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final marker = UserMarker(
        id: '', // Will be set by Firestore
        position: widget.position,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        type: _selectedType,
        createdAt: DateTime.now(),
        createdBy: _userNameController.text.isEmpty
            ? 'Anonymous'
            : _userNameController.text,
      );
      widget.onAdd(marker);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Marker'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ${widget.position.latitude.toStringAsFixed(4)}, ${widget.position.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Anonymous',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Marker Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MarkerType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForType(type),
                          size: 18,
                          color: isSelected ? Colors.white : _getColorForType(type),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type.toString().split('.').last,
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                    selectedColor: _getColorForType(type),
                    backgroundColor: _getColorForType(type).withOpacity(0.1),
                  );
                }).toList(),
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
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_location),
          label: const Text('Add Marker'),
        ),
      ],
    );
  }
}
