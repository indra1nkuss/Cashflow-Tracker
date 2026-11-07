import 'package:flutter/material.dart';

/// Add Transaction Screen — Placeholder for Phase 4 (Transaction CRUD)
class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Form Tambah Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('Implementasi pada Phase 4', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

