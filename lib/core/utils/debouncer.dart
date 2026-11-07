import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs the last [run] call after [delay] of silence. Use for search fields.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
