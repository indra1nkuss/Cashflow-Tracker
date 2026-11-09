import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../domain/models/category_model.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet(BuildContext context, String currentType) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String type = currentType;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tambah Kategori Baru',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        hintText: 'cth: Langganan SaaS, Kopi, Bonus',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama kategori wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kategori',
                        prefixIcon: Icon(Icons.swap_vert_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EXPENSE', child: Text('Pengeluaran')),
                        DropdownMenuItem(value: 'INCOME', child: Text('Pemasukan')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isLoading = true);

                              final success = await ref
                                  .read(categoriesNotifierProvider.notifier)
                                  .createCategory(
                                    name: nameCtrl.text.trim(),
                                    type: type,
                                  );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Kategori berhasil ditambahkan!'
                                        : 'Gagal menambahkan kategori'),
                                  ),
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Kategori'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pengeluaran', icon: Icon(Icons.arrow_upward_rounded)),
            Tab(text: 'Pemasukan', icon: Icon(Icons.arrow_downward_rounded)),
          ],
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const AppLoadingWidget(message: 'Memuat kategori...'),
        error: (err, _) => AppErrorWidget(
          message: 'Gagal memuat kategori: $err',
          onRetry: () => ref.read(categoriesNotifierProvider.notifier).refresh(),
        ),
        data: (categories) {
          final expenseCategories =
              categories.where((c) => c.type == 'EXPENSE').toList();
          final incomeCategories =
              categories.where((c) => c.type == 'INCOME').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories, theme, Colors.red.shade600),
              _buildCategoryList(incomeCategories, theme, Colors.green.shade600),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentType = _tabController.index == 0 ? 'EXPENSE' : 'INCOME';
          _showAddCategorySheet(context, currentType);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori'),
      ),
    );
  }

  Widget _buildCategoryList(
    List<CategoryModel> list,
    ThemeData theme,
    Color accentColor,
  ) {
    if (list.isEmpty) {
      return const Center(child: Text('Belum ada kategori'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = list[index];
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: accentColor.withValues(alpha: 0.12),
              child: Icon(Icons.category_rounded, color: accentColor, size: 20),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              cat.isDefault ? 'Bawaan Sistem' : 'Kustom Pengguna',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            trailing: cat.isDefault
                ? const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey)
                : null,
          ),
        );
      },
    );
  }
}
