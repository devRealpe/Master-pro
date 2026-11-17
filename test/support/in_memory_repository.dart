import 'dart:async';

import 'package:master_pro/core/data/entity_repository.dart';

/// Almacén en memoria para las pruebas. Se comporta como la caché local de
/// Firestore: un cambio se ve en [watchAll] en cuanto se escribe.
class InMemoryRepository<T> implements EntityRepository<T> {
  InMemoryRepository({required this.idOf, List<T> initial = const []})
    : _items = [...initial];

  final String Function(T entity) idOf;
  final List<T> _items;
  final _changes = StreamController<List<T>>.broadcast();
  int _nextId = 1;

  /// Estado actual, para comprobar lo que quedó guardado.
  List<T> get items => List.unmodifiable(_items);

  void _emit() => _changes.add(items);

  @override
  String newId() => 'id-${_nextId++}';

  @override
  Stream<List<T>> watchAll() async* {
    yield items;
    yield* _changes.stream;
  }

  @override
  Future<void> create(T entity) async {
    _items.add(entity);
    _emit();
  }

  @override
  Future<void> update(T before, T after) async {
    final index = _items.indexWhere((item) => idOf(item) == idOf(after));
    if (index == -1) throw StateError('No existe ${idOf(after)}');
    _items[index] = after;
    _emit();
  }
}
