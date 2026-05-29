import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purenote/core/services/auth_service.dart';
import 'package:purenote/core/providers/settings_provider.dart';

part 'lock_state_provider.g.dart';

@Riverpod(keepAlive: true)
class LockState extends _$LockState {
  final _auth = AuthService();

  @override
  bool build() => false;

  Future<void> checkAndLock() async {
    final isPinSet = await _auth.isPinSet();
    if (!isPinSet) return;

    final settings = ref.read(settingsNotifierProvider);
    final autoLock = settings.autoLockSeconds;
    if (autoLock <= 0) return;

    state = true;
  }

  void unlock() {
    state = false;
  }

  void lock() {
    state = true;
  }
}
