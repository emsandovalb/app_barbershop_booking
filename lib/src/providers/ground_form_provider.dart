import 'package:flutter/foundation.dart';

class GroundFormProvider extends ChangeNotifier {
  final Map<String, dynamic> data = {};

  void setAll(Map<String, dynamic> values) {
    data
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  void merge(Map<String, dynamic> values) {
    data.addAll(values);
    notifyListeners();
  }

  void clear() {
    data.clear();
    notifyListeners();
  }
}

