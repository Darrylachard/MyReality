import 'dart:math' as math;
import 'daily_progress.dart';

String dateKey(DateTime value) {
  final d = value.toLocal();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int count) =>
    DateTime(d.year, d.month, d.day + count);

/// Fixed, deliberately narrow 2026 Ontario simulation: weekly regular pay,
/// standard personal credits, CPP-eligible adult, one three-week employer.
/// Maximum prototype wage is $17.70, so higher brackets / annual caps cannot
/// be reached. Do not reuse this as a general-purpose payroll calculator.
class PayStub {
  final String periodStart, periodEnd, payday;
  final int gross, federal, ontario, cpp, ei;
  final double hours;
  final int wage;
  int get deductions => federal + ontario + cpp + ei;
  int get net => gross - deductions;

  PayStub({
    required this.periodStart,
    required this.periodEnd,
    required this.payday,
    required this.gross,
    required this.federal,
    required this.ontario,
    required this.cpp,
    required this.ei,
    required this.hours,
    required this.wage,
  });

  factory PayStub.calculate(
    String start,
    String end,
    String payday,
    int gross,
    double hours,
    int wage,
  ) {
    if (gross < 0 || gross > 70800) {
      throw StateError('Pay outside prototype limits');
    }
    final g = gross / 100;
    final cpp = (math.max(0, g - 67.30) * .0595 * 100).round();
    final ei = (g * .0163 * 100).round();
    final enhanced = cpp / 100 * .01 / .0595;
    final base = cpp / 100 * .0495 / .0595;
    final annual = 52 * (g - enhanced);
    final federal =
        (math.max(
                  0,
                  .14 *
                      (annual -
                          16452 -
                          math.min(1501, g * 52) -
                          52 * (base + ei / 100)),
                ) /
                52 *
                100)
            .round();
    final basic = math.max(
      0.0,
      .0505 * (annual - 12989 - 52 * (base + ei / 100)),
    );
    final reduction = math.min(basic, math.max(0.0, 600 - basic));
    final health = annual <= 20000
        ? 0.0
        : annual <= 36000
        ? math.min(300.0, .06 * (annual - 20000))
        : math.min(450.0, 300 + .06 * (annual - 36000));
    final ontario = ((basic - reduction + health) / 52 * 100).round();
    return PayStub(
      periodStart: start,
      periodEnd: end,
      payday: payday,
      gross: gross,
      federal: federal,
      ontario: ontario,
      cpp: cpp,
      ei: ei,
      hours: hours,
      wage: wage,
    );
  }

  Map<String, dynamic> toMap() => {
    'start': periodStart,
    'end': periodEnd,
    'payday': payday,
    'gross': gross,
    'federal': federal,
    'ontario': ontario,
    'cpp': cpp,
    'ei': ei,
    'hours': hours,
    'wage': wage,
    'rules': 'Ontario-2026-prototype-v1',
  };
  factory PayStub.fromMap(Map m) => PayStub(
    periodStart: m['start'],
    periodEnd: m['end'],
    payday: m['payday'],
    gross: m['gross'],
    federal: m['federal'],
    ontario: m['ontario'],
    cpp: m['cpp'],
    ei: m['ei'],
    hours: (m['hours'] as num).toDouble(),
    wage: m['wage'],
  );
}

class WorkEntry {
  final String day, note, reason;
  final int minutes, wage;
  final bool legacy;
  WorkEntry(
    this.day,
    this.minutes,
    this.note,
    this.reason,
    this.wage, {
    this.legacy = false,
  });
  Map<String, dynamic> toMap() => {
    'day': day,
    'minutes': minutes,
    'note': note,
    'reason': reason,
    'wage': wage,
    'legacy': legacy,
  };
  factory WorkEntry.fromMap(Map m) => WorkEntry(
    m['day'],
    m['minutes'],
    m['note'],
    m['reason'],
    m['wage'],
    legacy: m['legacy'] ?? false,
  );
}

class MoneyEntry {
  final String id, day, title, account, category;
  final int cents;
  MoneyEntry(
    this.id,
    this.day,
    this.title,
    this.account,
    this.category,
    this.cents,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'day': day,
    'title': title,
    'account': account,
    'category': category,
    'cents': cents,
  };
  factory MoneyEntry.fromMap(Map m) => MoneyEntry(
    m['id'],
    m['day'],
    m['title'],
    m['account'],
    m['category'],
    m['cents'],
  );
}

/// Persist the entire command result in one Hive value. Ledger balances are
/// derived; a purchase, transfer or payroll cannot commit only half its state.
class StoryState {
  String? start;
  String title = 'Get MyReality ready for my friend’s first test';
  String why = '';
  String deliverable = 'A working app my friend can test';
  int targetMinutes = 120;
  int goalCents = 40000;
  String reward = 'My upgraded workspace';
  bool deliverableDone = false;
  String? raisedFrom;
  Map<String, dynamic>? avatar;
  List<WorkEntry> work = [];
  List<PayStub> stubs = [];
  List<MoneyEntry> ledger = [];
  List<String> owned = [];
  List<String> legacyDays = [];
  int? legacyStatement;
  int arrears = 0;

  bool get started => start != null;
  DateTime get startDate => DateTime.parse(start!);
  // Inclusive 21-day Story; the next date is the final settlement boundary.
  DateTime get finishDate => addDays(startDate, 21);
  DateTime get lastDate => addDays(finishDate, -1);
  bool ended(DateTime now) => started && !dateOnly(now).isBefore(finishDate);
  int balance(String account) =>
      ledger.where((e) => e.account == account).fold(0, (n, e) => n + e.cents);
  int get checking => balance('checking');
  int get savings => balance('savings');
  int get available => math.max(0, checking - arrears);
  WorkEntry? entry(String day) {
    for (final e in work) {
      if (e.day == day) return e;
    }
    return null;
  }

  bool scheduled(DateTime date) =>
      started &&
      !date.isBefore(startDate) &&
      date.isBefore(finishDate) &&
      date.weekday <= 5;
  List<DateTime> get scheduledDays => !started
      ? []
      : [
          for (var i = 0; i < 21; i++)
            if (scheduled(addDays(startDate, i))) addDays(startDate, i),
        ];
  double fraction(WorkEntry? e) =>
      e == null ? 0 : (e.minutes / targetMinutes).clamp(0.0, 1.0);
  DailyProgress progressFor(WorkEntry? e) => DailyProgress(
    actualMinutes: e?.minutes ?? 0,
    targetMinutes: targetMinutes,
  );
  int participationDays(DateTime now) => dueDays(
    now,
  ).where((d) => progressFor(entry(dateKey(d))).participated).length;
  int get targetMetDays => scheduledDays
      .where((d) => progressFor(entry(dateKey(d))).targetMet)
      .length;
  int grossFor(WorkEntry e) =>
      e.legacy ? 0 : (fraction(e) * 8 * e.wage).round();
  int wageOn(DateTime date) =>
      raisedFrom != null && dateKey(date).compareTo(raisedFrom!) >= 0
      ? 1770
      : 1720;
  List<DateTime> dueDays(DateTime now) => scheduledDays
      .where(
        (d) =>
            d.isBefore(dateOnly(now)) ||
            (dateKey(d) == dateKey(now) && entry(dateKey(d)) != null),
      )
      .toList();
  double consistency(DateTime now) {
    final days = dueDays(now);
    return days.isEmpty
        ? 0
        : days.fold<double>(0, (n, d) => n + fraction(entry(dateKey(d)))) /
              days.length;
  }

  int streak(DateTime now) {
    var count = 0;
    for (final d in dueDays(now).reversed) {
      // An unfinished current day still has time left; only closed days can
      // break momentum. Completing today extends the streak immediately.
      if (dateKey(d) == dateKey(now) && fraction(entry(dateKey(d))) < 1) {
        continue;
      }
      if (fraction(entry(dateKey(d))) < 1) break;
      count++;
    }
    return count;
  }

  int get longestStreak {
    var best = 0, current = 0;
    for (final d in scheduledDays) {
      current = fraction(entry(dateKey(d))) == 1 ? current + 1 : 0;
      best = math.max(best, current);
    }
    return best;
  }

  int get pendingGross =>
      work.fold(0, (n, e) => n + grossFor(e)) -
      stubs.fold(0, (n, p) => n + p.gross);

  factory StoryState.fromLegacy(Map? legacy) {
    final s = StoryState();
    if (legacy != null) {
      s.legacyDays = List<String>.from(legacy['completedDays'] as List);
      s.legacyStatement = legacy['lastStatementCents'] as int?;
      s.ledger.add(
        MoneyEntry(
          'legacy-opening',
          '',
          'Opening balance from previous version',
          'checking',
          'opening',
          legacy['balanceCents'] as int,
        ),
      );
    }
    return s;
  }
  StoryState();

  void begin(
    DateTime now, {
    required String name,
    required String outcome,
    required String reason,
    required int minutes,
    required bool nextMonday,
  }) {
    if (started) throw StateError('This prototype supports one Story');
    if (name.trim().isEmpty ||
        outcome.trim().isEmpty ||
        minutes < 15 ||
        minutes > 480) {
      throw ArgumentError('Enter a goal, deliverable and 15–480 minutes');
    }
    final today = dateOnly(now);
    final first = nextMonday ? addDays(today, 8 - today.weekday) : today;
    start = dateKey(first);
    title = name.trim();
    deliverable = outcome.trim();
    why = reason.trim();
    targetMinutes = minutes;
    if (legacyDays.contains(dateKey(today)) && scheduled(today)) {
      work.add(
        WorkEntry(
          dateKey(today),
          targetMinutes,
          'Check-in completed before migration; already paid.',
          '',
          1720,
          legacy: true,
        ),
      );
    }
  }

  bool settledDay(DateTime date) {
    final key = dateKey(date);
    return stubs.any(
      (p) =>
          key.compareTo(p.periodStart) >= 0 && key.compareTo(p.periodEnd) <= 0,
    );
  }

  void record(
    DateTime now,
    int minutes,
    String note,
    String reason, {
    String? expectedDay,
  }) {
    final d = dateOnly(now), key = dateKey(now);
    if (expectedDay != null && key != expectedDay) {
      throw StateError(
        'The date changed. Reopen the form for today before saving.',
      );
    }
    if (!scheduled(d)) {
      throw StateError('Work can only be recorded on a scheduled day');
    }
    if (settledDay(d)) {
      throw StateError(
        'This workday belongs to a settled pay period and is locked',
      );
    }
    final previous = entry(key);
    if (previous?.legacy == true) {
      throw StateError('Today’s legacy check-in has already been paid');
    }
    if (minutes < (previous?.minutes ?? 0) ||
        minutes < 0 ||
        minutes > DailyProgress.maximumDailyMinutes) {
      throw ArgumentError('Record your total for today, up to 1440 minutes');
    }
    work.removeWhere((e) => e.day == key);
    work.add(WorkEntry(key, minutes, note.trim(), reason, wageOn(d)));
  }

  DateTime get nextPayday {
    var period = addDays(startDate, 1 - startDate.weekday);
    while (stubs.any((p) => p.periodStart == dateKey(period))) {
      period = addDays(period, 7);
    }
    final monday = addDays(period, 7);
    return monday.isBefore(finishDate) ? monday : finishDate;
  }

  void settle(DateTime now) {
    if (!started) return;
    final today = dateOnly(now);
    for (
      var period = addDays(startDate, 1 - startDate.weekday);
      period.isBefore(finishDate);
      period = addDays(period, 7)
    ) {
      final monday = addDays(period, 7);
      final end = monday.isBefore(finishDate) ? monday : finishDate;
      if (today.isBefore(end) ||
          stubs.any((p) => p.periodStart == dateKey(period))) {
        continue;
      }
      final entries = work
          .where(
            (e) =>
                e.day.compareTo(dateKey(period)) >= 0 &&
                e.day.compareTo(dateKey(end)) < 0,
          )
          .toList();
      final gross = entries.fold(0, (n, e) => n + grossFor(e));
      final hours = entries
          .where((e) => !e.legacy)
          .fold<double>(0, (n, e) => n + fraction(e) * 8);
      final stub = PayStub.calculate(
        dateKey(period),
        dateKey(addDays(end, -1)),
        dateKey(end),
        gross,
        hours,
        wageOn(period),
      );
      stubs.add(stub);
      if (stub.net > 0) {
        ledger.add(
          MoneyEntry(
            'pay:${stub.periodStart}',
            stub.payday,
            'Weekly paycheck',
            'checking',
            'income',
            stub.net,
          ),
        );
      }
      // Simple prototype essentials: $64 per scheduled weekday, settled after
      // payroll. Arrears never exceed one $320 starter week; no late fees.
      final days = scheduledDays
          .where((d) => !d.isBefore(period) && d.isBefore(end))
          .length;
      final due = arrears + days * 6400;
      final paid = math.min(checking, due);
      if (paid > 0) {
        ledger.add(
          MoneyEntry(
            'bill:${stub.periodStart}',
            stub.payday,
            'Starter essentials',
            'checking',
            'expense',
            -paid,
          ),
        );
      }
      arrears = math.min(32000, due - paid);
      final past = scheduledDays.where((d) => d.isBefore(end)).toList();
      final units = past.fold<double>(
        0,
        (n, d) => n + fraction(entry(dateKey(d))),
      );
      final recent = past.length > 20 ? past.sublist(past.length - 20) : past;
      final score = recent.isEmpty
          ? 0
          : recent.fold<double>(0, (n, d) => n + fraction(entry(dateKey(d)))) /
                recent.length;
      if (raisedFrom == null && units >= 10 && score >= .9) {
        raisedFrom = dateKey(end);
      }
    }
  }

  void payArrears(DateTime now) {
    final paid = math.min(checking, arrears);
    if (paid <= 0) {
      throw StateError('No Checking funds available for unpaid essentials');
    }
    ledger.add(
      MoneyEntry(
        'arrears:${ledger.length}',
        dateKey(now),
        'Pay unpaid essentials',
        'checking',
        'expense',
        -paid,
      ),
    );
    arrears -= paid;
  }

  void transfer(DateTime now, int cents, {required bool toSavings}) {
    if (cents <= 0 || cents > (toSavings ? available : savings)) {
      throw ArgumentError('Choose an amount within your available balance');
    }
    final id = 'transfer:${ledger.length}';
    ledger.add(
      MoneyEntry(
        '$id:checking',
        dateKey(now),
        toSavings ? 'Transfer to savings' : 'Transfer from savings',
        'checking',
        'transfer',
        toSavings ? -cents : cents,
      ),
    );
    ledger.add(
      MoneyEntry(
        '$id:savings',
        dateKey(now),
        toSavings ? 'Transfer from checking' : 'Transfer to checking',
        'savings',
        'transfer',
        toSavings ? cents : -cents,
      ),
    );
  }

  static const products = {
    'plant': ('Desk plant', 3000),
    'workspace': ('Workspace upgrade', 10000),
    'reward': ('Final workspace reward', 40000),
  };
  void buy(DateTime now, String id) {
    final product = products[id];
    if (!started || product == null || owned.contains(id)) {
      throw StateError('Item unavailable');
    }
    if (id == 'reward') {
      if (!ended(now) ||
          !deliverableDone ||
          consistency(now) < .8 ||
          savings < product.$2) {
        throw StateError(
          'Finish your deliverable, reach 80% weighted plan completion and save \$400',
        );
      }
      ledger.add(
        MoneyEntry(
          'buy:$id',
          dateKey(now),
          product.$1,
          'savings',
          'expense',
          -product.$2,
        ),
      );
    } else {
      if (available < product.$2 || arrears > 0) {
        throw StateError('Not enough available money after essentials');
      }
      ledger.add(
        MoneyEntry(
          'buy:$id',
          dateKey(now),
          product.$1,
          'checking',
          'expense',
          -product.$2,
        ),
      );
    }
    owned.add(id);
  }

  Map<String, dynamic> toMap() => {
    'version': 1,
    'start': start,
    'title': title,
    'why': why,
    'deliverable': deliverable,
    'minutes': targetMinutes,
    'goal': goalCents,
    'reward': reward,
    'done': deliverableDone,
    'raise': raisedFrom,
    'avatar': avatar,
    'arrears': arrears,
    'work': work.map((e) => e.toMap()).toList(),
    'stubs': stubs.map((p) => p.toMap()).toList(),
    'ledger': ledger.map((e) => e.toMap()).toList(),
    'owned': owned,
    'legacyDays': legacyDays,
    'legacyStatement': legacyStatement,
  };
  factory StoryState.fromMap(Map m) {
    if (m['version'] != 1) throw StateError('Unsupported saved Story version');
    return StoryState()
      ..start = m['start']
      ..title = m['title']
      ..why = m['why']
      ..deliverable = m['deliverable']
      ..targetMinutes = m['minutes']
      ..goalCents = m['goal']
      ..reward = m['reward']
      ..deliverableDone = m['done']
      ..raisedFrom = m['raise']
      ..avatar = m['avatar'] == null
          ? null
          : Map<String, dynamic>.from(m['avatar'])
      ..arrears = m['arrears']
      ..work = (m['work'] as List).map((e) => WorkEntry.fromMap(e)).toList()
      ..stubs = (m['stubs'] as List).map((e) => PayStub.fromMap(e)).toList()
      ..ledger = (m['ledger'] as List)
          .map((e) => MoneyEntry.fromMap(e))
          .toList()
      ..owned = List<String>.from(m['owned'])
      ..legacyDays = List<String>.from(m['legacyDays'])
      ..legacyStatement = m['legacyStatement'];
  }
}
