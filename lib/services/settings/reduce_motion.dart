import 'package:flutter/foundation.dart';

class ReduceMotion extends ChangeNotifier {
  bool _enabled = false;
  
  bool get enabled => _enabled;
  
  void setEnabled(bool v) {
    if (v == _enabled) return;
    _enabled = v;
    notifyListeners();
  }
}
