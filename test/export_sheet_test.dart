import 'dart:io';

import 'package:expense_tracker/models/app_user.dart';
import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/models/export_job.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/providers/app_providers.dart';
import 'package:expense_tracker/providers/export_providers.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/export_service.dart';
import 'package:expense_tracker/services/export_storage_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:expense_tracker/views/export/export_result_view.dart';
import 'package:expense_tracker/views/export/export_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'helpers/export_fixtures.dart';

class _SeededAuthController extends AuthController {
  _SeededAuthController(AuthService service, HydrationNotifier hydration)
      : super(service, hydration);

  void seed(AppUser user) => state = user;
}

class _SeededTransactionsController extends TransactionsController {
  _SeededTransactionsController(TransactionService service) : super(service);

  void seed(List<TransactionModel> items) => state = items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late DatabaseService db;
  late ExportStorageService storage;
  late ExportService exportService;
  late _SeededAuthController auth;
  late _SeededTransactionsController transactions;

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('export_sheet_test');
    Hive.init(temp.path);
    db = DatabaseService();
    await db.init();

    storage = ExportStorageService(
      root: Directory('${temp.path}${Platform.pathSeparator}exports'),
    );
    exportService = ExportService(
      storage: storage,
      database: db,
      throttle: Duration.zero,
      idGenerator: () => 'job-1',
    );

    final now = DateTime.now();
    auth = _SeededAuthController(AuthService(db), HydrationNotifier())
      ..seed(fixtureUser());
    transactions = _SeededTransactionsController(TransactionService(db))
      ..seed([
        fixtureTransaction(
          id: 'tx-food',
          date: DateTime(now.year, now.month, 15),
          amount: 100,
          category: 'Food',
        ),
        fixtureTransaction(
          id: 'tx-travel',
          date: DateTime(now.year, now.month, 10),
          amount: 250,
          category: 'Travel',
        ),
      ]);
  });

  tearDown(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (temp.existsSync()) {
      try {
        temp.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportStorageServiceProvider.overrideWithValue(storage),
          exportServiceProvider.overrideWithValue(exportService),
          authControllerProvider.overrideWith((_) => auth),
          transactionsControllerProvider.overrideWith((_) => transactions),
        ],
        child: const MaterialApp(home: Scaffold(body: ExportSheet())),
      ),
    );
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final text = find.text(label);
    final inkWells = find.ancestor(of: text, matching: find.byType(InkWell));
    final target =
        inkWells.evaluate().isEmpty ? text.first : inkWells.first;
    await reveal(tester, target);
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> waitForResult(WidgetTester tester) async {
    for (var i = 0; i < 80 && find.byType(ExportResultView).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  group('configuration stage', () {
    testWidgets('renders the header, every format and the action',
        (tester) async {
      await pumpSheet(tester);

      expect(find.text('Export Report'), findsOneWidget);
      expect(find.text('Choose a format and what to include'), findsOneWidget);
      for (final format in ExportFormat.values) {
        expect(find.text(format.label), findsOneWidget);
      }
      expect(find.byType(ExportResultView), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Generate export'),
          findsOneWidget);
    });

    testWidgets('shows a live preview with the row count and totals',
        (tester) async {
      await pumpSheet(tester);

      expect(find.text('2 rows'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Net'), findsOneWidget);
      expect(find.text('₹350.00'), findsOneWidget);
      expect(find.text('₹0.00'), findsOneWidget);
    });

    testWidgets('narrowing the category filter updates the preview',
        (tester) async {
      await pumpSheet(tester);
      expect(find.text('2 rows'), findsOneWidget);

      await tapLabel(tester, 'Food');
      expect(find.text('1 rows'), findsOneWidget);
      expect(find.text('₹100.00'), findsOneWidget);

      await tapLabel(tester, 'Food');
      expect(find.text('2 rows'), findsOneWidget);
    });

    testWidgets('the charts switch only appears for PDF', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Include charts'), findsNothing);

      await tapLabel(tester, 'PDF');
      expect(find.text('Include charts'), findsOneWidget);

      await tapLabel(tester, 'CSV');
      expect(find.text('Include charts'), findsNothing);
    });

    testWidgets('choosing Custom reveals the two date pickers',
        (tester) async {
      await pumpSheet(tester);
      expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);

      await tapLabel(tester, 'Custom');
      expect(find.byIcon(Icons.calendar_today_outlined), findsNWidgets(2));
      expect(find.text('to'), findsOneWidget);

      await tapLabel(tester, 'This month');
      expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
    });

    testWidgets('switching the transaction type segment works',
        (tester) async {
      await pumpSheet(tester);

      await tapLabel(tester, 'Income only');
      expect(find.text('0 rows'), findsOneWidget);

      await tapLabel(tester, 'Income & expenses');
      expect(find.text('2 rows'), findsOneWidget);
    });
  });

  group('generation', () {
    testWidgets('produces a CSV report and shows the result view',
        (tester) async {
      await pumpSheet(tester);

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);

      await tapLabel(tester, 'Generate export');
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget,
          reason: 'the running stage must be visible right after the tap');
      await waitForResult(tester);
      expect(find.byType(ExportResultView), findsOneWidget);
      expect(find.text('Report ready'), findsOneWidget);
      expect(find.textContaining('.csv'), findsOneWidget);
      expect(find.text('Export another'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Save to device'), findsOneWidget);
      expect(find.text('Print / save as PDF'), findsNothing);
    });

    testWidgets('PDF reports expose a print action', (tester) async {
      await pumpSheet(tester);

      await tapLabel(tester, 'PDF');
      await tapLabel(tester, 'Generate export');
      await waitForResult(tester);

      expect(find.text('Report ready'), findsOneWidget);
      expect(find.textContaining('.pdf'), findsOneWidget);
      expect(find.text('Print / save as PDF'), findsOneWidget);
    });

    testWidgets('Export another returns to the configuration stage',
        (tester) async {
      await pumpSheet(tester);

      await tapLabel(tester, 'Generate export');
      await waitForResult(tester);
      expect(find.byType(ExportResultView), findsOneWidget);

      await reveal(tester, find.text('Export another'));
      await tester.tap(find.text('Export another'));
      await tester.pump();

      expect(find.byType(ExportResultView), findsNothing);
      expect(find.text('Generate export'), findsOneWidget);
    });

    testWidgets('runs once per service id, replacing the stored job',
        (tester) async {
      await pumpSheet(tester);

      await tapLabel(tester, 'Generate export');
      await waitForResult(tester);

      expect(exportService.storedJobs(), hasLength(1));
      expect(exportService.storedJobs().single.status,
          ExportJobStatus.completed);
    });
  });
}
