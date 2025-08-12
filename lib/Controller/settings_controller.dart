import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameMode { classic, endless, timed }

enum Difficulty { easy, normal, hard }

class SettingsController extends ChangeNotifier {
  // defaults
  GameMode _mode = GameMode.classic;
  Difficulty _difficulty = Difficulty.normal;
  int _rounds = 5;

  static const _kMode = 'mode';
  static const _kDifficulty = 'difficulty';
  static const _kRounds = 'rounds';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  GameMode get mode => _mode;
  Difficulty get difficulty => _difficulty;
  int get rounds => _rounds;

  SettingsController() {
    _load();
  }

  /// Oyuncunun seçtiği oyun modu
  int get initialLives {
    switch (_difficulty) {
      case Difficulty.easy:
        return 8;
      case Difficulty.normal:
        return 6;
      case Difficulty.hard:
        return 4;
    }
  }

  /// Timed mod için tur süresi (saniye)
  int get roundSeconds {
    if (_mode != GameMode.timed) return 0;
    const base = 60;
    final minus = switch (_difficulty) {
      Difficulty.easy => 0,
      Difficulty.normal => 10,
      Difficulty.hard => 20,
    };
    return base - minus;
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final m = sp.getInt(_kMode);
    final d = sp.getInt(_kDifficulty);
    final r = sp.getInt(_kRounds);

    if (m != null && m >= 0 && m < GameMode.values.length) {
      _mode = GameMode.values[m];
    }
    if (d != null && d >= 0 && d < Difficulty.values.length) {
      _difficulty = Difficulty.values[d];
    }
    if (r != null && r >= 1) {
      _rounds = r;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kMode, _mode.index);
    await sp.setInt(_kDifficulty, _difficulty.index);
    await sp.setInt(_kRounds, _rounds);
  }

  void setMode(GameMode mode) {
    _mode = mode;
    _save();
    notifyListeners();
  }

  void setDifficulty(Difficulty d) {
    _difficulty = d;
    _save();
    notifyListeners();
  }

  void setRounds(int r) {
    _rounds = r;
    _save();
    notifyListeners();
  }

  Future<void> resetDefaults() async {
    _mode = GameMode.classic;
    _difficulty = Difficulty.normal;
    _rounds = 5;
    await _save();
    notifyListeners();
  }
}
