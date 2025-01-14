import 'package:flutter/material.dart';

class DynamicFieldProvider with ChangeNotifier {
  final Map<String, List<TextEditingController>> _controllers = {};

  List<TextEditingController> getControllers(String fieldName) {
    return _controllers.putIfAbsent(fieldName, () => [TextEditingController()]);
  }

  void addField(String fieldName) {
    _controllers[fieldName]?.add(TextEditingController());
    notifyListeners();
  }

  void removeField(String fieldName, int index) {
    if (_controllers[fieldName] != null && _controllers[fieldName]!.length > index) {
      _controllers[fieldName]![index].dispose();
      _controllers[fieldName]!.removeAt(index);
      notifyListeners();
    }
  }

  void disposeControllers() {
    for (var fieldControllers in _controllers.values) {
      for (var controller in fieldControllers) {
        controller.dispose();
      }
    }
    _controllers.clear();
  }
}
