import 'package:flutter/material.dart';
import '../data/models/card_model.dart';

class HomeProvider extends ChangeNotifier {
  List<CardModel> _cards = [];
  bool _isLoading = false;

  List<CardModel> get cards => _cards;
  bool get isLoading => _isLoading;

  Future<void> loadCards() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Placeholder - cards will be loaded from API when implemented
      await Future.delayed(const Duration(milliseconds: 500));
      _cards = [];
    } catch (_) {
      _cards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
