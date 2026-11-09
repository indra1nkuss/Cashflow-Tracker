import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/categories_repository.dart';
import '../../domain/models/category_model.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository();
});

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    return _fetchCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final repo = ref.read(categoriesRepositoryProvider);
    return repo.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }

  Future<bool> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final repo = ref.read(categoriesRepositoryProvider);
    try {
      final newCat = await repo.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      state = AsyncValue.data([...state.value ?? [], newCat]);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final categoriesNotifierProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(() {
  return CategoriesNotifier();
});
