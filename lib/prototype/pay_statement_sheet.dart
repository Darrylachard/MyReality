import 'package:flutter/material.dart';
import 'story_state.dart';

/// A read-only presentation of settled payroll; never recalculates past taxes.
class PayStatementSheet extends StatelessWidget {
  final PayStub stub;
  final List<PayStub> history;
  const PayStatementSheet({
    super.key,
    required this.stub,
    required this.history,
  });

  String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  List<PayStub> get yearToDate => history
      .where(
        (p) =>
            p.payday.substring(0, 4) == stub.payday.substring(0, 4) &&
            (p.payday.compareTo(stub.payday) < 0 ||
                (p.payday == stub.payday &&
                    p.periodEnd.compareTo(stub.periodEnd) <= 0)),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final ytd = yearToDate;
    int total(int Function(PayStub) value) =>
        ytd.fold(0, (sum, p) => sum + value(p));
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pay statement',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Close statement',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xffdce3de)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MYREALITY',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Color(0xff183b33),
                            fontSize: 22,
                          ),
                        ),
                        const Text(
                          'EARNINGS STATEMENT',
                          style: TextStyle(fontSize: 12, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Simulated pay · CAD',
                          style: TextStyle(color: Color(0xff59675f)),
                        ),
                        const Divider(height: 32, thickness: 2),
                        _detail('Period beginning', stub.periodStart),
                        _detail('Period ending', stub.periodEnd),
                        _detail('Pay date', stub.payday),
                        _detail(
                          'Statement ID',
                          'MR-${stub.periodStart.replaceAll('-', '')}',
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xffe8f1eb),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Net deposited',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                money(stub.net),
                                key: const Key('statement-net'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff183b33),
                                ),
                              ),
                              const Text('Deposited to Checking'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _title('Earnings'),
                        _detail(
                          'Equivalent work hours',
                          stub.hours.toStringAsFixed(2),
                        ),
                        _detail('Hourly game wage', '${money(stub.wage)}/hr'),
                        const SizedBox(height: 8),
                        _table([
                          _row('Earnings', 'Current', 'YTD', bold: true),
                          _row(
                            'Regular work',
                            money(stub.gross),
                            money(total((p) => p.gross)),
                          ),
                          _row(
                            'Gross pay',
                            money(stub.gross),
                            money(total((p) => p.gross)),
                            bold: true,
                          ),
                        ]),
                        const SizedBox(height: 8),
                        const Text(
                          'Hours are game-equivalent hours earned from your daily target, not actual coding hours.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff59675f),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _title('Deductions'),
                        _table([
                          _row('Deduction', 'Current', 'YTD', bold: true),
                          _row(
                            'Federal income tax',
                            money(stub.federal),
                            money(total((p) => p.federal)),
                          ),
                          _row(
                            'Ontario income tax¹',
                            money(stub.ontario),
                            money(total((p) => p.ontario)),
                          ),
                          _row(
                            'CPP contribution',
                            money(stub.cpp),
                            money(total((p) => p.cpp)),
                          ),
                          _row(
                            'EI premium',
                            money(stub.ei),
                            money(total((p) => p.ei)),
                          ),
                          _row(
                            'Total deductions',
                            money(stub.deductions),
                            money(total((p) => p.deductions)),
                            bold: true,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _title('Pay summary'),
                        _table([
                          _row('Summary', 'Current', 'YTD', bold: true),
                          _row(
                            'Gross pay',
                            money(stub.gross),
                            money(total((p) => p.gross)),
                          ),
                          _row(
                            'Less deductions',
                            money(stub.deductions),
                            money(total((p) => p.deductions)),
                          ),
                          _row(
                            'Net pay',
                            money(stub.net),
                            money(total((p) => p.net)),
                            bold: true,
                          ),
                        ]),
                        const SizedBox(height: 20),
                        const Text(
                          'Expenses and savings transfers occur separately in Checking. They do not change this statement.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Divider(height: 28),
                        const Text(
                          '¹ Includes the simulated Ontario health premium.\nYTD includes saved MyReality paychecks in the pay-date year through this statement. Imported balances are excluded.\n\nOntario 2026 prototype estimates. Virtual money only. This is not an ADP document or a real payroll record.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Color(0xff59675f),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _table(List<TableRow> rows) => Table(
    columnWidths: const {
      0: FlexColumnWidth(1.55),
      1: FlexColumnWidth(1),
      2: FlexColumnWidth(1),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    border: const TableBorder(
      horizontalInside: BorderSide(color: Color(0xffe5e9e6)),
    ),
    children: rows,
  );

  TableRow _row(
    String label,
    String current,
    String ytd, {
    bool bold = false,
  }) => TableRow(
    decoration: bold ? const BoxDecoration(color: Color(0xfff3f6f3)) : null,
    children: [
      for (final cell in [
        (label, TextAlign.left),
        (current, TextAlign.right),
        (ytd, TextAlign.right),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
          child: Text(
            cell.$1,
            textAlign: cell.$2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
    ],
  );
}
