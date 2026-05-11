import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/expiry_reminder_service.dart';
import '../services/product_repository.dart';

class RegisterProductScreen extends StatefulWidget {
  const RegisterProductScreen({
    super.key,
    required this.ocrText,
    required this.suggestedDates,
  });

  final String ocrText;
  final List<DateTime> suggestedDates;

  @override
  State<RegisterProductScreen> createState() => _RegisterProductScreenState();
}

class _RegisterProductScreenState extends State<RegisterProductScreen> {
  final _nameCtrl = TextEditingController();
  late DateTime _expiration;
  final _repo = ProductRepository();
  bool _saving = false;

  static final _dateFmt = DateFormat.yMMMd('fr_FR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.suggestedDates.isNotEmpty) {
      _expiration = widget.suggestedDates.first;
    } else {
      _expiration = DateTime(now.year, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickOtherDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiration,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() => _expiration = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez le nom du produit.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await _repo.addProduct(name: name, expirationDate: _expiration);
      try {
        await ExpiryReminderService.instance.scheduleProductIfEnabled(
          productId: id,
          productName: name,
          expirationDate: _expiration,
        );
      } on Object {
        // Ne pas bloquer l'enregistrement Firestore si la notification echoue.
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement impossible : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau produit')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom du produit',
              border: OutlineInputBorder(),
              hintText: 'Ex. : Yaourt nature',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Date de peremption',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (widget.suggestedDates.isNotEmpty) ...[
            Text(
              'Dates detectees sur l\'etiquette :',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.suggestedDates.map((d) {
                final selected = _isSameDay(d, _expiration);
                return FilterChip(
                  label: Text(_dateFmt.format(d)),
                  selected: selected,
                  onSelected: (_) => setState(() => _expiration = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ] else
            Text(
              'Aucune date automatique trouvee. Choisissez la date manuellement.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickOtherDate,
            icon: const Icon(Icons.calendar_month),
            label: Text('Autre date : ${_dateFmt.format(_expiration)}'),
          ),
          const SizedBox(height: 24),
          if (widget.ocrText.trim().isNotEmpty)
            ExpansionTile(
              title: const Text('Texte lu (OCR)'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    widget.ocrText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Enregistrement...' : 'Enregistrer dans Firestore'),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
