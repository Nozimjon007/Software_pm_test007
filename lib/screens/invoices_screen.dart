import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/status_pill.dart';

enum _Period { monthToDate, fullMonth, custom }

/// Invoice generated from bookings (FR-06). In production this happens
/// automatically at the end of the billing period; here a button triggers it.
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  _Period _period = _Period.monthToDate;
  DateTimeRange? _custom;
  Invoice? _selected;

  DateTimeRange _range(AppState state) {
    final t = state.today;
    switch (_period) {
      case _Period.monthToDate:
        return DateTimeRange(start: DateTime(t.year, t.month, 1), end: t);
      case _Period.fullMonth:
        return DateTimeRange(start: DateTime(t.year, t.month, 1), end: DateTime(t.year, t.month + 1, 0));
      case _Period.custom:
        return _custom ?? DateTimeRange(start: DateTime(t.year, t.month, 1), end: t);
    }
  }

  Future<void> _pickCustom(AppState state) async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(state.today.year - 1),
      lastDate: DateTime(state.today.year + 1, 12, 31),
      initialDateRange: _range(state),
    );
    if (r != null) {
      setState(() {
        _custom = r;
        _period = _Period.custom;
      });
    }
  }

  void _generate(AppState state) {
    final r = _range(state);
    final invoice = state.generateInvoice(r.start, r.end);
    setState(() => _selected = invoice);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invoice ${invoice.number} generated · ${Fmt.money(invoice.total)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final range = _range(state);
    final seatsInPeriod = state.bookings.where((b) {
      final d = Fmt.dateOnly(b.date);
      return b.isActive && !d.isBefore(range.start) && !d.isAfter(range.end);
    }).length;
    final invoice = _selected ?? (state.invoices.isEmpty ? null : state.invoices.first);

    return PageBody(
      children: [
        const PageHeader(
          title: 'Invoices',
          subtitle: 'Invoices are built from booked seats. Cancelled seats are not billed.',
          requirementIds: ['FR-06', 'NFR-01'],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Billing period', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('This month so far'),
                    selected: _period == _Period.monthToDate,
                    onSelected: (_) => setState(() => _period = _Period.monthToDate),
                  ),
                  ChoiceChip(
                    label: const Text('Whole month'),
                    selected: _period == _Period.fullMonth,
                    onSelected: (_) => setState(() => _period = _Period.fullMonth),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.date_range, size: 16),
                    label: Text(_custom == null
                        ? 'Custom…'
                        : '${Fmt.date(_custom!.start)} – ${Fmt.date(_custom!.end)}'),
                    selected: _period == _Period.custom,
                    onSelected: (_) => _pickCustom(state),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${Fmt.date(range.start)} – ${Fmt.date(range.end)} · $seatsInPeriod booked seats',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  FilledButton.icon(
                    key: const Key('generate_invoice'),
                    onPressed: () => _generate(state),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Generate invoice'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Final version: runs automatically on the last day of each billing period.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (invoice == null)
          const AppCard(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No invoices yet',
              message: 'Choose a period and press "Generate invoice".',
            ),
          )
        else
          _InvoiceDocument(invoice: invoice),
        if (state.invoices.length > 1) ...[
          const SizedBox(height: 18),
          const Text('Invoice history', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final inv in state.invoices)
                  ListTile(
                    selected: inv.id == invoice?.id,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(inv.number),
                    subtitle: Text('${Fmt.date(inv.periodStart)} – ${Fmt.date(inv.periodEnd)}'),
                    trailing: Text(Fmt.money(inv.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () => setState(() => _selected = inv),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InvoiceDocument extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceDocument({required this.invoice});

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 12);

    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_bus_filled, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('RideLine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('Shuttle operator services', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('INVOICE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text(invoice.number, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Issued ${Fmt.date(invoice.createdAt)}', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 40,
            runSpacing: 12,
            children: [
              const _Field(label: 'Billed to', value: 'Company HR Department\n(shuttle program)'),
              _Field(label: 'Billing period', value: '${Fmt.date(invoice.periodStart)} –\n${Fmt.date(invoice.periodEnd)}'),
              _Field(label: 'Seats billed', value: '${invoice.totalSeats}'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.background,
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('ROUTE', style: head)),
                Expanded(flex: 2, child: Text('SEATS', style: head, textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text('UNIT PRICE', style: head, textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text('AMOUNT', style: head, textAlign: TextAlign.right)),
              ],
            ),
          ),
          if (invoice.lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No booked seats in this period.', style: TextStyle(color: AppColors.textMuted)),
            ),
          for (final l in invoice.lines)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(flex: 5, child: Text(l.routeName)),
                  Expanded(flex: 2, child: Text('${l.seats}', textAlign: TextAlign.right)),
                  Expanded(flex: 3, child: Text(Fmt.money(l.unitPrice), textAlign: TextAlign.right)),
                  Expanded(
                    flex: 3,
                    child: Text(Fmt.money(l.total), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 320,
              child: Column(
                children: [
                  _TotalRow(label: 'Subtotal', value: Fmt.money(invoice.subtotal)),
                  _TotalRow(label: 'VAT ${(Invoice.vatRate * 100).round()}%', value: Fmt.money(invoice.vat)),
                  const Divider(),
                  _TotalRow(label: 'Total due', value: Fmt.money(invoice.total), bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill('Generated from bookings', tone: PillTone.ok, icon: Icons.check),
              StatusPill('Payment data encrypted (NFR-01, final version)', tone: PillTone.info, icon: Icons.lock_outline),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, fontSize: bold ? 17 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
