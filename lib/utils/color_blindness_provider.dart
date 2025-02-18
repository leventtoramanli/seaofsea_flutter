import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorBlindnessProvider with ChangeNotifier {
  bool _isEffectOn = false;
  double _blurLevel = 0.0;
  String _currentEffect = protanopia;

  static const String protanopia = 'Protanopia';
  static const String deuteranopia = 'Deuteranopia';
  static const String tritanopia = 'Tritanopia';
  static const String achromatopsia = 'Achromatopsia';
  static const String blur = 'Blur';

  ColorBlindnessProvider() {
    _loadSettingsFromPreferences();
  }

  bool get isEffectOn => _isEffectOn;
  double get blurLevel => _blurLevel;
  String get currentEffect => _currentEffect;

  /// Tritanopia renk filtresi
  static const ColorFilter _protanopiaFilter = ColorFilter.matrix([
    0.56667,
    0.43333,
    0.0,
    0.0,
    0.0,
    0.55833,
    0.44167,
    0.0,
    0.0,
    0.0,
    0.0,
    0.24167,
    0.75833,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
  ]);

  static const ColorFilter _deuteranopiaFilter = ColorFilter.matrix([
    0.625,
    0.375,
    0.0,
    0.0,
    0.0,
    0.7,
    0.3,
    0.0,
    0.0,
    0.0,
    0.0,
    0.3,
    0.7,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
  ]);

  static const ColorFilter _tritanopiaFilter = ColorFilter.matrix([
    0.95,
    0.05,
    0.0,
    0.0,
    0.0,
    0.0,
    0.43,
    0.56,
    0.0,
    0.0,
    0.0,
    0.47,
    0.53,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
  ]);

  static const ColorFilter _achromatopsiaFilter = ColorFilter.matrix([
    0.299,
    0.587,
    0.114,
    0.0,
    0.0,
    0.299,
    0.587,
    0.114,
    0.0,
    0.0,
    0.299,
    0.587,
    0.114,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
  ]);

  static const ColorFilter _noFilter =
      ColorFilter.mode(Colors.transparent, BlendMode.dst);

  /// Aktif Renk Filtresi
  ColorFilter get currentFilter {
    if (!_isEffectOn) return _noFilter;

    switch (_currentEffect) {
      case protanopia:
        return _protanopiaFilter;
      case deuteranopia:
        return _deuteranopiaFilter;
      case tritanopia:
        return _tritanopiaFilter;
      case achromatopsia:
        return _achromatopsiaFilter;
      default:
        return _noFilter;
    }
  }

  /// Efekti aç/kapat
  Future<void> toggleEffect() async {
    _isEffectOn = !_isEffectOn;
    await _saveSettingsToPreferences();
    notifyListeners();
  }

  /// Efekti değiştir
  Future<void> setEffect(String effect) async {
    _currentEffect = effect;
    await _saveSettingsToPreferences();
    notifyListeners();
  }

  /// Blur seviyesini ayarla
  Future<void> setBlurLevel(double level) async {
    _blurLevel = level;
    _currentEffect = blur;
    await _saveSettingsToPreferences();
    notifyListeners();
  }

  /// Ayarları SharedPreferences'dan yükle
  Future<void> _loadSettingsFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isEffectOn = prefs.getBool('isEffectOn') ?? false;
    _blurLevel = prefs.getDouble('blurLevel') ?? 0.0;
    _currentEffect = prefs.getString('currentEffect') ?? protanopia;
    notifyListeners();
  }

  /// Ayarları SharedPreferences'a kaydet
  Future<void> _saveSettingsToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEffectOn', _isEffectOn);
    await prefs.setDouble('blurLevel', _blurLevel);
    await prefs.setString('currentEffect', _currentEffect);
  }
}
