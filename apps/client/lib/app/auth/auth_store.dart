import 'package:flutter/foundation.dart';

import 'auth_repository.dart';

enum AuthMode { login, register }

class AuthStore extends ChangeNotifier {
  AuthStore({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  AuthSession? _session;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthSession? get session => _session;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _session != null;
  bool get isRemoteEnabled => _repository.isRemoteEnabled;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _repository.fetchSession();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submit({
    required AuthMode mode,
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = switch (mode) {
        AuthMode.login => await _repository.login(
            email: email,
            password: password,
          ),
        AuthMode.register => await _repository.register(
            email: email,
            password: password,
          ),
      };
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.logout();
      _session = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }
}
