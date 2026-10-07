import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../Avatar/avatar_creation_page.dart';
import '../Avatar/avatar_model.dart';
import '../Avatar/avatar_widget.dart';
import 'story_repository.dart';
import 'story_state.dart';
import 'pay_statement_sheet.dart';

String dollars(int cents) =>
    NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(cents / 100);
String shortDate(DateTime date) => DateFormat('MMM d').format(date);

class PrototypePage extends StatefulWidget {
  const PrototypePage({super.key, this.now = DateTime.now});
  final DateTime Function() now;
  @override
  State<PrototypePage> createState() => _PrototypePageState();
}

class _PrototypePageState extends State<PrototypePage>
    with WidgetsBindingObserver {
  StoryRepository? repository;
  String? loadError;
  bool busy = false;
  int tab = 0;
  Timer? timer;
  StoryState get data => repository!.state;
  DateTime get now => widget.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  Future<void> _load() async {
    try {
      repository = StoryRepository(Hive.box<dynamic>('account'));
      await _change((_) {});
    } catch (e) {
      if (mounted) {
        setState(
          () => loadError =
              'Your saved data could not be loaded. It has not been reset.\n$e',
        );
      }
    }
  }

  Future<void> _refresh() async {
    if (!mounted || busy || repository == null || loadError != null) return;
    if (data.started &&
        !(data.ended(now) &&
            data.stubs.isNotEmpty &&
            data.stubs.last.periodEnd == dateKey(data.lastDate)) &&
        !dateOnly(now).isBefore(data.nextPayday) &&
        data.nextPayday.compareTo(data.finishDate) <= 0) {
      await _change((_) {});
    } else {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<bool> _change(void Function(StoryState) command) async {
    if (busy || repository == null) return false;
    setState(() => busy = true);
    try {
      await repository!.update(now, command);
      if (mounted) setState(() {});
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Not saved: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget panel(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget line(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(title)),
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

  Widget page(List<Widget> children) => ListView(
    key: ValueKey(tab),
    padding: const EdgeInsets.all(12),
    children: children,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyReality'),
        actions: [
          IconButton(
            tooltip: 'Prototype details',
            icon: const Icon(Icons.info_outline),
            onPressed: _about,
          ),
        ],
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(loadError!),
                ),
              )
            : repository == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: [home, shop, account][tab](),
                ),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget home() {
    final today = data.entry(dateKey(now));
    final ended = data.ended(now);
    return page([
      _scene(),
      if (!data.started)
        panel('Your first three-week Story', [
          const Text(
            'Build a version of MyReality your friend can test. Show up on weekdays, earn weekly pay, and watch your workspace change.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _begin,
            child: const Text('Create my Story'),
          ),
        ])
      else ...[
        panel(ended ? 'Your Story has ended' : data.title, [
          Text(
            '${shortDate(data.startDate)} – ${shortDate(data.lastDate)} · Review ${shortDate(data.finishDate)}',
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value:
                ((dateOnly(now).difference(data.startDate).inHours / 24) / 21)
                    .clamp(0.0, 1.0),
          ),
          const SizedBox(height: 8),
          Text(
            ended
                ? 'Three weeks recorded. Your work remains yours.'
                : '${data.scheduledDays.where((d) => !d.isBefore(dateOnly(now))).length} scheduled workdays remaining',
          ),
          line(
            'Consistency so far',
            '${(data.consistency(now) * 100).round()}%',
          ),
          line('Full-day streak', '${data.streak(now)} scheduled days'),
          line(
            'Completed full days',
            '${data.work.where((e) => e.minutes == data.targetMinutes).length} / 15',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(data.deliverable),
            subtitle: const Text(
              'Mark when your real project deliverable is ready',
            ),
            value: data.deliverableDone,
            onChanged: busy
                ? null
                : (v) => _change((s) => s.deliverableDone = v!),
          ),
          if (data.why.isNotEmpty) Text('Your why: “${data.why}”'),
        ]),
        if (!ended)
          panel(
            data.scheduled(dateOnly(now))
                ? 'Today’s coding commitment'
                : now.isBefore(data.startDate)
                ? 'Your Story starts ${shortDate(data.startDate)}'
                : 'Planned rest',
            [
              if (data.scheduled(dateOnly(now))) ...[
                Text(
                  '${today?.minutes ?? 0} / ${data.targetMinutes} minutes · total for today',
                ),
                const SizedBox(height: 8),
                Text(
                  today?.legacy == true
                      ? 'Already completed and paid in the previous version.'
                      : 'Full completion earns 8 simulated hours. Partial work earns proportional credit.',
                ),
                if (today?.reason.isNotEmpty == true)
                  Text('Absence recorded: ${today!.reason}'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed:
                          busy ||
                              today?.legacy == true ||
                              today?.minutes == data.targetMinutes
                          ? null
                          : _record,
                      child: Text(
                        today?.minutes == data.targetMinutes
                            ? 'Today completed'
                            : 'Record coding work',
                      ),
                    ),
                    OutlinedButton(
                      onPressed:
                          busy ||
                              today?.legacy == true ||
                              today?.minutes == data.targetMinutes
                          ? null
                          : _callIn,
                      child: const Text('Call In'),
                    ),
                  ],
                ),
              ] else
                const Text(
                  'No coding obligation today. Rest does not break your streak or reduce your agreed weekly earning potential.',
                ),
            ],
          ),
        if (ended)
          panel('Your three-week result', [
            line('Longest streak', '${data.longestStreak} days'),
            line(
              'Net pay earned',
              dollars(data.stubs.fold(0, (n, p) => n + p.net)),
            ),
            line('Saved toward your reward', dollars(data.savings)),
            Text(
              data.deliverableDone
                  ? 'Deliverable completed.'
                  : 'Deliverable not yet marked complete. Your recorded effort still counts.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Your final partial paycheck has been settled. You can keep this Story, celebrate, and take a break.',
            ),
          ]),
        panel('Your work, day by day', [
          if (data.work.isEmpty)
            const Text('Your first work note will appear here.'),
          for (final e in [
            ...data.work,
          ]..sort((a, b) => b.day.compareTo(a.day)))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                e.minutes == data.targetMinutes
                    ? Icons.check_circle_outline
                    : e.minutes == 0
                    ? Icons.event_busy
                    : Icons.timelapse,
              ),
              title: Text('${e.day} · ${e.minutes} min'),
              subtitle: Text(
                e.note.isNotEmpty
                    ? e.note
                    : e.reason.isNotEmpty
                    ? e.reason
                    : 'Work recorded',
              ),
            ),
        ]),
      ],
    ]);
  }

  Widget _scene() {
    final a = data.avatar;
    final name = data.owned.contains('reward')
        ? 'A space you earned.'
        : data.owned.contains('workspace')
        ? 'Room to grow.'
        : 'This is your beginning.';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 270,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/bg/home.png', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99213a30),
                    Color(0x00213a30),
                    Color(0xcc132a24),
                  ],
                  stops: [0, .45, 1],
                ),
              ),
            ),
            if (a != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AvatarWidget(
                    avatar: AvatarModel(
                      bodyType: a['body'],
                      skinTone: a['skin'],
                      hairStyle: a['hair'],
                      hairColor: a['hairColor'] ?? 'natural',
                    ),
                    size: 190,
                  ),
                ),
              ),
            const Positioned(
              left: 20,
              top: 22,
              child: Text(
                'YOUR SPACE',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2.5,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 10,
              child: FilledButton.tonalIcon(
                onPressed: busy ? null : _avatar,
                icon: const Icon(Icons.tune, size: 16),
                label: Text(a == null ? 'Create avatar' : 'Edit avatar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xeef4f5f0),
                  foregroundColor: const Color(0xff183b33),
                ),
              ),
            ),
            if (data.owned.contains('plant'))
              const Positioned(
                left: 25,
                bottom: 58,
                child: Icon(Icons.yard, size: 50, color: Color(0xff8fcfa5)),
              ),
            if (data.owned.contains('workspace'))
              const Positioned(
                right: 20,
                bottom: 58,
                child: Icon(Icons.desk, size: 65, color: Color(0xffffd39b)),
              ),
            if (data.owned.contains('reward'))
              const Positioned(
                right: 36,
                bottom: 108,
                child: Icon(Icons.computer, size: 40, color: Colors.white),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget shop() => page([
    panel('Make this space yours', [
      line('Available in Checking', dollars(data.available)),
      const Text(
        'One-time visual purchases. Items do not increase pay or complete work.',
      ),
    ]),
    for (final p in StoryState.products.entries)
      panel(p.value.$1, [
        Text(dollars(p.value.$2)),
        const SizedBox(height: 8),
        Text(
          p.key == 'reward'
              ? 'At the ending: real deliverable completed, 80% Story consistency, and \$400 in Savings.'
              : 'Appears in your Home scene. Earn it through your recorded work.',
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: busy || !data.started || data.owned.contains(p.key)
              ? null
              : () => _buy(p.key),
          child: Text(data.owned.contains(p.key) ? 'Owned' : 'Review purchase'),
        ),
      ]),
  ]);

  Widget account() => page([
    panel('Checking', [
      Text(
        dollars(data.checking),
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      line('Unpaid essentials', dollars(data.arrears)),
      line('Available after unpaid essentials', dollars(data.available)),
      if (data.arrears > 0 && data.checking > 0)
        OutlinedButton(
          onPressed: busy ? null : () => _change((s) => s.payArrears(now)),
          child: const Text('Pay unpaid essentials'),
        ),
      if (data.arrears > 0)
        const Text(
          'No late fees. Unpaid essentials are capped at one starter week. Savings are never taken automatically.',
        ),
    ]),
    panel('Payday', [
      if (!data.started)
        const Text('Create your Story to start earning.')
      else ...[
        line(
          data.ended(now) ? 'Final settlement' : 'Next payday',
          shortDate(data.nextPayday),
        ),
        line('Pending gross earnings', dollars(data.pendingGross)),
        line('Current game wage', '${dollars(data.wageOn(now))}/hour'),
        const Text(
          'Net pay is deposited after each calendar week. Starter essentials cost \$64 per scheduled weekday and are paid after payroll. Partial weeks are prorated.',
        ),
        const SizedBox(height: 8),
        Text(
          data.raisedFrom == null
              ? 'First review: earn 10 full-day equivalents with at least 90% recent consistency. The \$0.50 raise applies from the next pay period.'
              : 'Raise earned! Your rate increased from ${data.raisedFrom}.',
        ),
      ],
      const SizedBox(height: 8),
      const Text(
        'Simulated Ontario 2026 deductions · fixed three-week prototype assumptions',
      ),
      const SizedBox(height: 16),
      Text('Pay statements', style: Theme.of(context).textTheme.titleMedium),
      if (data.stubs.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Your first statement will appear here after payday. Pending earnings are not a deposited paycheck.',
          ),
        ),
      for (final p in data.stubs.reversed)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text('${p.payday} · ${dollars(p.net)} net'),
          subtitle: Text('${p.periodStart} – ${p.periodEnd}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _stub(p),
        ),
    ]),
    panel('Savings · ${data.reward}', [
      line('Saved', '${dollars(data.savings)} / ${dollars(data.goalCents)}'),
      LinearProgressIndicator(
        value: (data.savings / data.goalCents).clamp(0.0, 1.0),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonal(
            onPressed: busy || data.available == 0
                ? null
                : () => _transfer(true),
            child: const Text('Move to savings'),
          ),
          OutlinedButton(
            onPressed: busy || data.savings == 0
                ? null
                : () => _transfer(false),
            child: const Text('Move to checking'),
          ),
        ],
      ),
    ]),
    panel('Recent transactions', [
      if (data.ledger.isEmpty)
        const Text('Your first paycheck will appear here.'),
      for (final e in data.ledger.reversed.take(30))
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(e.title),
          subtitle: Text('${e.day} · ${e.account}'),
          trailing: Text(
            '${e.cents >= 0 ? '+' : '−'}${dollars(e.cents.abs())}',
          ),
        ),
    ]),
    if (data.legacyDays.isNotEmpty || data.legacyStatement != null)
      panel('Previous version', [
        Text('${data.legacyDays.length} legacy check-ins preserved.'),
        if (data.legacyStatement != null)
          line('Legacy gross statement', dollars(data.legacyStatement!)),
        const Text(
          'Old earnings were already credited. They are not paid again.',
        ),
      ]),
    TextButton.icon(
      onPressed: _export,
      icon: const Icon(Icons.copy),
      label: const Text('Copy prototype backup'),
    ),
  ]);

  Future<void> _begin() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const StorySetupDialog(),
    );
    if (result == null || !mounted) return;
    await _change(
      (s) => s.begin(
        now,
        name: result['title'],
        outcome: result['outcome'],
        reason: result['why'],
        minutes: result['minutes'],
        nextMonday: result['nextMonday'],
      ),
    );
  }

  Future<void> _record() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => WorkDialog(
        target: data.targetMinutes,
        previous: data.entry(dateKey(now)),
      ),
    );
    if (result == null || !mounted) return;
    await _change((s) => s.record(now, result['minutes'], result['note'], ''));
  }

  Future<void> _callIn() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Record an absence'),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Reasons are optional reflection data. They do not change pay. Any work already recorded is kept.',
            ),
          ),
          for (final r in [
            'Prefer not to say',
            'Sick',
            'Family responsibility',
            'School/work conflict',
            'Mental recovery/rest',
            'Other',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, r),
              child: Text(r),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    await _change((s) {
      final old = s.entry(dateKey(now));
      s.record(now, old?.minutes ?? 0, old?.note ?? '', reason);
    });
  }

  Future<void> _avatar() async {
    final result = await Navigator.push<AvatarModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarCreatorPage(
          initial: data.avatar == null
              ? null
              : AvatarModel(
                  bodyType: data.avatar!['body'],
                  skinTone: data.avatar!['skin'],
                  hairStyle: data.avatar!['hair'],
                  hairColor: data.avatar!['hairColor'] ?? 'natural',
                ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    await _change(
      (s) => s.avatar = {
        'body': result.bodyType,
        'skin': result.skinTone,
        'hair': result.hairStyle,
        'hairColor': result.hairColor,
      },
    );
  }

  Future<void> _buy(String id) async {
    final p = StoryState.products[id]!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Buy ${p.$1}?'),
        content: Text(
          '${dollars(p.$2)} will leave ${id == 'reward' ? 'Savings' : 'Checking'}. This purchase is permanent in this prototype.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep saving'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _change((s) => s.buy(now, id));
  }

  Future<void> _transfer(bool toSavings) async {
    final cents = await showDialog<int>(
      context: context,
      builder: (_) =>
          TransferDialog(maximum: toSavings ? data.available : data.savings),
    );
    if (cents != null && mounted) {
      await _change((s) => s.transfer(now, cents, toSavings: toSavings));
    }
  }

  void _stub(PayStub p) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: const Color(0xfff4f5f0),
    constraints: const BoxConstraints(maxWidth: 780),
    builder: (c) => FractionallySizedBox(
      heightFactor: .94,
      child: PayStatementSheet(stub: p, history: List.of(data.stubs)),
    ),
  );

  Future<void> _export() async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(data.toMap()),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup copied. It includes your private work notes.'),
        ),
      );
    }
  }

  void _about() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Three-week prototype'),
      content: const SingleChildScrollView(
        child: Text(
          'One Story. Monday–Friday. Weekends are rest. Record real coding work; repeating a save cannot multiply earnings.\n\n'
          'Calendar-week paychecks use fixed 2026 Ontario simulation rules. The final partial week settles when the 21-day Story ends.\n\n'
          'This first build uses one bundled essentials bill, one raise and three visual items. Flexible schedules, forecasts, Story revisions and multiple Stories come later.\n\n'
          'Everything is saved locally. Your original account data remains intact.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

class StorySetupDialog extends StatefulWidget {
  const StorySetupDialog({super.key});
  @override
  State<StorySetupDialog> createState() => _StorySetupDialogState();
}

class _StorySetupDialogState extends State<StorySetupDialog> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(
    text: 'Get MyReality ready for my friend’s first test',
  );
  final outcome = TextEditingController(
    text: 'A working app my friend can test',
  );
  final why = TextEditingController();
  final minutes = TextEditingController(text: '120');
  bool nextMonday = false;
  @override
  void dispose() {
    title.dispose();
    outcome.dispose();
    why.dispose();
    minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your three-week agreement'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Story name'),
              maxLength: 100,
              validator: (v) => v!.trim().isEmpty ? 'Name your Story' : null,
            ),
            TextFormField(
              controller: outcome,
              decoration: const InputDecoration(
                labelText: 'What will be ready at the end?',
              ),
              maxLength: 200,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Choose a concrete deliverable' : null,
            ),
            TextFormField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Coding minutes per weekday',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 15 || n > 480
                    ? 'Enter 15–480 minutes'
                    : null;
              },
            ),
            TextFormField(
              controller: why,
              decoration: const InputDecoration(
                labelText: 'Why this matters (optional)',
              ),
              maxLength: 400,
              maxLines: 2,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start next Monday'),
              subtitle: const Text('Off: start today'),
              value: nextMonday,
              onChanged: (v) => setState(() => nextMonday = v),
            ),
            const Text(
              '21 calendar days · 15 weekdays · weekends off. Final reward: save \$400, complete your deliverable and reach 80% consistency. Partial work counts proportionally.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, {
              'title': title.text,
              'outcome': outcome.text,
              'why': why.text,
              'minutes': int.parse(minutes.text),
              'nextMonday': nextMonday,
            });
          }
        },
        child: const Text('Start my Story'),
      ),
    ],
  );
}

class WorkDialog extends StatefulWidget {
  final int target;
  final WorkEntry? previous;
  const WorkDialog({super.key, required this.target, this.previous});
  @override
  State<WorkDialog> createState() => _WorkDialogState();
}

class _WorkDialogState extends State<WorkDialog> {
  final form = GlobalKey<FormState>();
  late final minutes = TextEditingController(
    text: '${widget.previous?.minutes ?? 0}',
  );
  late final note = TextEditingController(text: widget.previous?.note ?? '');
  @override
  void dispose() {
    minutes.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('What did you move forward?'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total minutes today (0–${widget.target})',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null ||
                        n < (widget.previous?.minutes ?? 0) ||
                        n > widget.target
                    ? 'Enter your total, between ${widget.previous?.minutes ?? 0} and ${widget.target}'
                    : null;
              },
            ),
            TextFormField(
              controller: note,
              maxLength: 400,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What changed? (optional)',
              ),
            ),
            const Text(
              'You can add more work today. Credit stops at your daily target; extra time does not buy tomorrow’s completion.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, {
              'minutes': int.parse(minutes.text),
              'note': note.text,
            });
          }
        },
        child: const Text('Save work'),
      ),
    ],
  );
}

class TransferDialog extends StatefulWidget {
  final int maximum;
  const TransferDialog({super.key, required this.maximum});
  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  int? parse(String value) {
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) return null;
    return (double.parse(value) * 100).round();
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Move your money'),
    content: Form(
      key: form,
      child: TextFormField(
        controller: amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Amount in dollars',
          helperText: 'Available: ${dollars(widget.maximum)}',
        ),
        validator: (v) {
          final n = parse(v ?? '');
          return n == null || n <= 0 || n > widget.maximum
              ? 'Enter an amount within your balance'
              : null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, parse(amount.text));
          }
        },
        child: const Text('Transfer'),
      ),
    ],
  );
}
