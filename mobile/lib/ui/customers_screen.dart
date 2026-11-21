import 'package:flutter/material.dart';

import '../core/ledger_store.dart';
import '../core/models.dart';
import '../l10n/prompts.dart';

class CustomersScreen extends StatelessWidget {
  final LedgerStore store;
  final String langCode;

  const CustomersScreen({super.key, required this.store, required this.langCode});

  @override
  Widget build(BuildContext context) {
    String t(String k) => Prompts.render(langCode, k);
    final rows = [
      for (final c in store.customers) (customer: c, balance: store.balanceOf(c.id)),
    ]..sort((a, b) => b.balance.compareTo(a.balance));

    return Scaffold(
      appBar: AppBar(title: Text(t('uiCustomers'))),
      body: rows.isEmpty
          ? Center(child: Text(t('uiNoCustomers')))
          : ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                return ListTile(
                  title: Text(row.customer.name,
                      style: const TextStyle(fontSize: 18)),
                  trailing: Text(
                    '₹${row.balance}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: row.balance > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerHistoryScreen(
                        store: store,
                        customer: row.customer,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CustomerHistoryScreen extends StatelessWidget {
  final LedgerStore store;
  final Customer customer;

  const CustomerHistoryScreen({super.key, required this.store, required this.customer});

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final entries = store.entriesFor(customer.id);
    final balance = store.balanceOf(customer.id);
    return Scaffold(
      appBar: AppBar(title: Text('${customer.name}   ₹$balance')),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final e = entries[i];
          final isCredit = e.type == EntryType.credit;
          final raw = e.rawText;
          return ListTile(
            leading: Icon(
              isCredit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isCredit ? Colors.red : Colors.green,
            ),
            title: Text('${isCredit ? '+' : '-'} ₹${e.amount}',
                style: const TextStyle(fontSize: 18)),
            subtitle: Text(raw == null || raw.isEmpty
                ? _fmt(e.createdAt)
                : '${_fmt(e.createdAt)}\n"$raw"'),
          );
        },
      ),
    );
  }
}
