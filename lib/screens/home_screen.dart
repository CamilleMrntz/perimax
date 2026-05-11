import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../services/product_repository.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final _dateFmt = DateFormat.yMMMd('fr_FR');

  static const _permDeniedHints =
      'Permission refusee : verifiez dans la console Firebase\n'
      '1) Firestore > Regles : publiees pour la base (default) (attendre ~1 min apres publication).\n'
      '2) App Check > APIs > Firestore : si « Application forcee », desactivez-la pour tester '
      'ou enregistrez l\'app avec un fournisseur de depannage.\n'
      '3) Meme projet que l\'app (google-services.json / projectId perimax).\n\n';

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ProductRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perimax'),
        actions: [
          IconButton(
            tooltip: 'Parametres',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: repo.watchProducts(),
        builder: (context, snap) {
          if (snap.hasError) {
            final err = snap.error.toString();
            final isPerm = err.contains('permission-denied') ||
                err.contains('PERMISSION_DENIED');
            final uidLine = kDebugMode && isPerm
                ? '\n(uid connecte : ${FirebaseAuth.instance.currentUser?.uid ?? "null"})'
                : '';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur Firestore : $err$uidLine\n\n'
                  '${isPerm ? _permDeniedHints : ""}'
                  'Sinon : connexion Internet, projet Firebase (perimax) et flutterfire configure.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun produit enregistre.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scannez la date sur un emballage, puis saisissez le nom du produit.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = items[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('Peremption : ${_dateFmt.format(p.expirationDate)}'),
                leading: CircleAvatar(
                  child: Text(_initial(p.name)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
          );
        },
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scanner'),
      ),
    );
  }
}
