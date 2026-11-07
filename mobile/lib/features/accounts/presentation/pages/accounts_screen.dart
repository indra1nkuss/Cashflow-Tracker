import 'package:flutter/material.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun & Dompet')),
      body: const Center(child: Text('Halaman Akun — Implementasi Phase 4')),
    );
  }
}

