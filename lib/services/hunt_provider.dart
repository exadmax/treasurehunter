import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'hunt_service.dart';

/// Provides the currently active hunt to child widgets via reactive stream.
class HuntProvider extends ChangeNotifier {
  final HuntService _service;

  Hunt? _hunt;
  StreamSubscription<Hunt?>? _subscription;

  Hunt? get hunt => _hunt;
  String? get huntId => _hunt?.id;

  HuntProvider(this._service) {
    _subscription = _service.watchActiveHunt().listen((hunt) {
      _hunt = hunt;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
