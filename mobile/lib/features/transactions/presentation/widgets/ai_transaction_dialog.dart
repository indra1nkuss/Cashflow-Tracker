import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/transactions_provider.dart';

class AiTransactionDialog extends ConsumerStatefulWidget {
  const AiTransactionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AiTransactionDialog(),
    );
  }

  @override
  ConsumerState<AiTransactionDialog> createState() => _AiTransactionDialogState();
}

class _AiTransactionDialogState extends ConsumerState<AiTransactionDialog> {
  final _inputCtrl = TextEditingController();
  bool _isAnalyzing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _parsedResult;
  String? _errorMessage;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyzeMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _parsedResult = null;
    });

    try {
      final response = await ApiClient().dio.post(
        ApiRoutes.aiParse,
        data: {'message': text},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      setState(() {
        _parsedResult = data;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memproses pesan via AI: $e';
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveParsedTransaction() async {
    if (_parsedResult == null) return;

    final type = _parsedResult!['type'] as String?;
    final amount = (_parsedResult!['amount'] as num?)?.toDouble();
    final description = _parsedResult!['description'] as String? ?? _inputCtrl.text;
    final categoryName = _parsedResult!['category'] as String?;

    if (type == null || amount == null) return;

    final accounts = ref.read(accountsNotifierProvider).value ?? [];
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buat rekening/dompet terlebih dahulu')),
      );
      return;
    }
    final accountId = accounts.first.id;

    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    final matchedCat = categories.firstWhere(
      (c) =>
          c.type == type &&
          (categoryName != null &&
              c.name.toLowerCase().contains(categoryName.toLowerCase())),
      orElse: () => categories.firstWhere(
        (c) => c.type == type,
        orElse: () => categories.first,
      ),
    );

    setState(() => _isSaving = true);

    final success = await ref
        .read(transactionsNotifierProvider.notifier)
        .createTransaction(
          type: type,
          amount: amount,
          description: description,
          accountId: accountId,
          categoryId: matchedCat.id,
        );

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi AI berhasil dicatat!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Quick Transaction',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ketik teks transaksi bebas bertenaga Groq AI',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _inputCtrl,
            decoration: InputDecoration(
              hintText: 'cth: Membeli bensin 50rb, Makan bakso 25.000',
              suffixIcon: IconButton(
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                onPressed: _isAnalyzing ? null : _analyzeMessage,
              ),
            ),
            onSubmitted: (_) => _analyzeMessage(),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),

          if (_parsedResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hasil Analisis AI:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_parsedResult!['type'] == 'INCOME')
                              ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                              : const Color(0xFFDC2626).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _parsedResult!['type'] == 'INCOME'
                              ? 'PEMASUKAN'
                              : 'PENGELUARAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (_parsedResult!['type'] == 'INCOME')
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nominal: ${CurrencyFormatter.format(_parsedResult!['amount'] ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kategori: ${_parsedResult!['category'] ?? "-"} • Deskripsi: ${_parsedResult!['description'] ?? "-"}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_parsedResult!['needsClarification'] == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ ${_parsedResult!['clarificationMessage'] ?? "Nominal transaksi belum lengkap."}',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_parsedResult!['amount'] != null &&
                _parsedResult!['needsClarification'] != true)
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveParsedTransaction,
                icon: const Icon(Icons.check_rounded),
                label: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Transaksi Ini'),
              ),
          ],
        ],
      ),
    );
  }
}

