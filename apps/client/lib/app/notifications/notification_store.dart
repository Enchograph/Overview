import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore({required NotificationService service})
      : _service = service;

  final NotificationService _service;

  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  NotificationPermissionStatus get permissionStatus => _permissionStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.initialize();
      _permissionStatus = await _service.getPermissionStatus();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.initialize();
      _permissionStatus = await _service.requestPermission();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendTestNotification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.initialize();
      await _service.showTestNotification();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
