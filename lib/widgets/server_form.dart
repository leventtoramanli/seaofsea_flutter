import 'package:flutter/material.dart';

class ServerForm extends StatefulWidget {
  final Map<String, dynamic> schema;
  final Map<String, dynamic> initialData;
  final void Function(Map<String, dynamic> values) onSubmit;

  const ServerForm({
    super.key,
    required this.schema,
    required this.initialData,
    required this.onSubmit,
  });

  @override
  State<ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends State<ServerForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    for (final f in widget.schema['fields'] as List) {
      final key = f['key'] as String;
      final type = f['type'] as String;
      final init = widget.initialData[key];

      if (type == 'switch' || type == 'checkbox') {
        _values[key] = init ?? false;
      } else if (type == 'select') {
        _values[key] = init;
      } else {
        _controllers[key] = TextEditingController(text: init?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = (widget.schema['fields'] as List).cast<Map<String, dynamic>>();
    return Form(
      key: _formKey,
      child: Column(
        children: [
          for (final f in fields) _buildField(f),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                for (final e in _controllers.entries) {
                  _values[e.key] = e.value.text.trim();
                }
                widget.onSubmit(_values);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> f) {
    final key = f['key'] as String;
    final label = f['label'] as String? ?? key;
    final type = f['type'] as String? ?? 'text';
    final required = (f['required'] ?? false) as bool;

    String? validator(String? v) {
      if (required && (v == null || v.trim().isEmpty)) {
        return '$label required';
      }
      return null;
    }

    switch (type) {
      case 'switch':
        return SwitchListTile(
          title: Text(label),
          value: (_values[key] as bool?) ?? false,
          onChanged: (val) => setState(() => _values[key] = val),
        );
      case 'select':
        final options = (f['options'] as List).cast<String>();
        return DropdownButtonFormField<String>(
          value: (_values[key] as String?),
          decoration: InputDecoration(labelText: label),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => _values[key] = v,
          validator: required ? (v) => v == null ? '$label required' : null : null,
        );
      default:
        return TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: label),
          validator: validator,
          keyboardType: _keyboard(type),
        );
    }
  }

  TextInputType _keyboard(String type) {
    switch (type) {
      case 'phone': return TextInputType.phone;
      case 'url': return TextInputType.url;
      case 'email': return TextInputType.emailAddress;
      default: return TextInputType.text;
    }
  }
}
