import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/providers/database_provider.dart';

part 'labels_provider.g.dart';

@riverpod
Stream<List<Label>> labels(LabelsRef ref) {
  final dao = ref.watch(labelDaoProvider);
  return dao.watchAll();
}
