import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purenote/features/lock/providers/lock_state_provider.dart';

void main() {
  group('LockState', () {
    test('default state is unlocked', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());

      final state = container.read(lockStateProvider);
      expect(state, isFalse);
    });
  });
}
