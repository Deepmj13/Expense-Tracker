# Expense Tracker

A modern, offline-first expense tracking mobile application built with Flutter.

## Features

- **Manual Transaction Tracking** - Add income and expenses with categories
- **Budget Management** - Set monthly budgets with visual alerts
- **SMS Auto-Sync** - Automatically detect transactions from bank SMS
- **Daily Reminders** - Get notified every 4 hours to add expenses
- **Reports & Analytics** - View spending patterns with charts
- **Multi-Currency** - Support for 8 countries/currencies
- **Dark Mode** - System-aware light/dark theme
- **CSV Export** - Export transactions for external use

---

## Project Structure

```
lib/
├── main.dart                     # Entry point, routing, service init
├── models/                       # Data models
│   ├── app_user.dart            # User & Country data
│   ├── transaction_model.dart     # Transaction with PaymentMethod
│   ├── transaction_type.dart     # Income/Expense enum
│   ├── budget_model.dart        # Budget & AlertLevel
│   ├── transaction_message_model.dart
│   └── parsed_transaction.dart
├── services/                     # Business logic
│   ├── database_service.dart     # Hive database
│   ├── transaction_service.dart   # Transaction CRUD
│   ├── auth_service.dart        # User signup/session
│   ├── budget_service.dart      # Budget operations
│   ├── notification_service.dart  # Local notifications
│   ├── permission_service.dart   # SMS permission handling
│   ├── sms_transaction_service.dart
│   ├── transaction_parser.dart   # SMS parsing logic
│   ├── message_filter_service.dart
│   ├── deduplication_service.dart
│   ├── sms_sync_manager.dart     # Sync orchestration
│   ├── sms_sync_preference_service.dart
│   ├── sms_background_service.dart
│   └── sms_background_sync_service.dart
├── providers/                     # State management
│   └── app_providers.dart        # All Riverpod providers
├── core/                         # Utilities
│   ├── themes/app_theme.dart     # Material 3 theme
│   ├── constants/app_constants.dart
│   ├── constants/oem_instructions.dart
│   └── utils/validators.dart
├── views/                        # UI screens
│   ├── loading_view.dart
│   ├── home_shell.dart
│   ├── auth/
│   ├── dashboard/
│   ├── transactions/
│   ├── reports/
│   ├── settings/
│   ├── budget/
│   └── onboarding/
└── widgets/                      # Shared widgets
    ├── transaction_tile.dart
    └── summary_card.dart
```

---

## Dependencies

```yaml
# State Management
flutter_riverpod: ^2.5.1          # Provider-based state management
go_router: ^14.2.7                # Declarative routing

# Database & Storage
hive: ^2.2.3                      # Local NoSQL database
hive_flutter: ^1.1.0              # Hive Flutter integration
flutter_secure_storage: ^9.2.2    # Encrypted key-value storage

# Notifications & Background
flutter_local_notifications: ^18.0.1  # Local notifications
workmanager: ^0.9.0               # Background task scheduling
timezone: ^0.10.0                 # Timezone support for notifications

# SMS & Permissions
flutter_sms_inbox: ^1.0.1        # Read SMS messages
permission_handler: ^11.3.1        # Runtime permissions

# UI & Data
fl_chart: ^0.68.0                 # Charts for reports
intl: ^0.19.0                     # Internationalization & formatting
csv: ^6.0.0                       # CSV export
file_picker: ^8.1.2               # File selection for import
url_launcher: ^6.3.0               # Open external URLs
```

---

## File Documentation

---

### lib/main.dart

**Purpose:** App entry point with service initialization and routing

**Key Code:**

```dart
// Service Initialization (Lines 16-37)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await DatabaseService().init();           // Hive database
  await NotificationService.instance.init(); // Notifications
  await SmsBackgroundSyncService.instance.init(); // Background tasks
  
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

// Router Setup (Lines 40-68)
final _routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authControllerProvider);
  final isHydrated = ref.watch(isAuthHydratedProvider);
  return GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthWrapper()),
      GoRoute(path: '/home', builder: (_, __) {
        if (!isHydrated) return const LoadingView();
        if (user == null) return const AuthWrapper();
        return HomeShell(user: user);
      }),
    ],
    redirect: (_, state) {
      if (!isHydrated) return null;
      if (user == null && state.matchedLocation != '/auth') return '/auth';
      if (user != null && state.matchedLocation == '/auth') return '/home';
      return null;
    },
  );
});
```

---

### lib/models/app_user.dart

**Purpose:** User data model and country list with currency

**Key Code:**

```dart
// Country List with Currency (Lines 14-37)
static const List<Country> countries = [
  Country(name: 'India', code: 'IN', currency: 'INR', currencySymbol: '₹'),
  Country(name: 'United States', code: 'US', currency: 'USD', currencySymbol: '\$'),
  Country(name: 'United Kingdom', code: 'UK', currency: 'GBP', currencySymbol: '£'),
  Country(name: 'European Union', code: 'EU', currency: 'EUR', currencySymbol: '€'),
  Country(name: 'Japan', code: 'JP', currency: 'JPY', currencySymbol: '¥'),
  Country(name: 'Canada', code: 'CA', currency: 'CAD', currencySymbol: 'C\$'),
  Country(name: 'Australia', code: 'AU', currency: 'AUD', currencySymbol: 'A\$'),
  Country(name: 'Singapore', code: 'SG', currency: 'SGD', currencySymbol: 'S\$'),
];

// AppUser Model (Lines 40-86)
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.country,
    required this.currencySymbol,
    this.sessionToken,
  });
  // Fields: id, name, country, currencySymbol, sessionToken
}
```

---

### lib/models/transaction_model.dart

**Purpose:** Core transaction data model with payment methods

**Key Code:**

```dart
// Payment Methods (Lines 5-63)
enum PaymentMethod {
  cash,
  bank,
  upi,
  card,
  other,
}

// Transaction Source (Lines 65-68)
enum TransactionSource {
  manual,
  sms_auto,
}

// Transaction Model (Lines 70-155)
class TransactionModel {
  final String id;
  final double amount;
  final String title;
  final String category;
  final TransactionType type;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final TransactionSource source;
  final String? note;
  // ... copyWith, toMap, fromMap methods
}
```

---

### lib/models/budget_model.dart

**Purpose:** Monthly budget with alert levels

**Key Code:**

```dart
// Budget Model (Lines 1-51)
class BudgetModel {
  final String id;
  final double monthlyLimit;
  final int month;  // 1-12
  final int year;
  final double currentSpending;
  // Alert level calculated from percentage
}

// Alert Levels (Lines 53-57)
enum BudgetAlertLevel {
  none,    // 0-50% spent
  warning, // 50-80% spent
  danger,  // 80%+ spent
}
```

---

### lib/services/database_service.dart

**Purpose:** Hive database initialization and box management

**Key Code:**

```dart
// Box Names (Lines 8-13)
static const usersBox = 'users';
static const transactionsBox = 'transactions';
static const appBox = 'app_data';
static const processedSmsBox = 'processed_sms';

// Initialization (Lines 14-20)
Future<void> init() async {
  await Hive.initFlutter();
  await Hive.openBox<Map>(usersBox);
  await Hive.openBox<Map>(transactionsBox);
  await Hive.openBox<Map>(appBox);
  await Hive.openBox<String>(processedSmsBox);
}

// Box Getters
Box<Map> usersBox() => Hive.box<Map>(usersBox);
Box<Map> transactionsBox() => Hive.box<Map>(transactionsBox);
Box<Map> appBox() => Hive.box<Map>(appBox);
Box<String> processedSmsBox() => Hive.box<String>(processedSmsBox);
```

---

### lib/services/auth_service.dart

**Purpose:** User signup and session management

**Key Code:**

```dart
// Signup - Creates user with name and country (Lines 15-33)
Future<AppUser?> signup({
  required String name,
  required Country country,
}) async {
  final userId = DateTime.now().microsecondsSinceEpoch.toString();
  
  final user = AppUser(
    id: userId,
    name: name.trim(),
    country: country.name,
    currencySymbol: country.currencySymbol,
    sessionToken: _generateSessionToken(),
  );
  
  await _dbService.usersBox().put(user.id, user.toMap());
  await _secureStorage.write(key: _sessionKey, value: jsonEncode(user.toMap()));
  return user;
}

// Get Current User - Checks session (Lines 35-47)
// Returns null if no session or if old format (with email) exists

// Logout - Clears session (Lines 49-51)
Future<void> logout() async {
  await _secureStorage.delete(key: _sessionKey);
}
```

---

### lib/services/notification_service.dart

**Purpose:** Local notifications for transactions and reminders

**Key Code:**

```dart
// Singleton Pattern (Lines 7-10)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

// Initialization with Timezone (Lines 17-41)
Future<void> init() async {
  tz_data.initializeTimeZones();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await _notifications.initialize(
    InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: _onNotificationTap,
  );
}

// Quiet Hours Check - 11 PM to 7 AM (Lines 174-177)
bool isQuietHours() {
  final hour = DateTime.now().hour;
  return hour >= 23 || hour < 7;
}

// Delayed Transaction Notification (Lines 179-227)
// Schedules notification 2 minutes after sync (non-blocking)

// Reminder Notification (Lines 229-262)
// Uses timestamp-based ID for uniqueness
```

---

### lib/services/transaction_parser.dart

**Purpose:** Parse SMS messages to extract transaction data

**Key Code:**

```dart
// Main Parse Method (Lines 27-51)
ParsedTransaction? parse(String message, DateTime receivedAt) {
  final amount = _extractAmount(message);
  if (amount == null) return null;
  
  final type = _determineTransactionType(message);
  final category = _detectCategory(message, type);
  final date = _extractDate(message, receivedAt);
  
  return ParsedTransaction(
    amount: amount.abs(),
    type: type,
    category: category,
    date: date,
    message: message,
  );
}

// Amount Extraction (Lines 53-132)
// Extracts currency amounts with various formats (₹1,000, $100.00, etc.)

// Category Detection (Lines 323-459)
// Maps keywords to categories: Food, Transport, Shopping, Bills, etc.
```

---

### lib/services/message_filter_service.dart

**Purpose:** Filter OTP and promotional messages

**Key Code:**

```dart
// OTP Keywords (Lines 4-20)
static final otpPatterns = [
  RegExp(r'\b(otp|one.?time.?password|verification.?code)\b', caseSensitive: false),
  RegExp(r'\b\d{4,8}\b'),  // 4-8 digit codes
];

static final promotionalPatterns = [
  RegExp(r'\b(FREE|offer|discount|win|prize|lottery)\b', caseSensitive: false),
];

// Filter Check (Lines 58-62)
bool isValidTransaction(String message) {
  return !isOtpOrPromotional(message);
}
```

---

### lib/services/deduplication_service.dart

**Purpose:** Prevent duplicate transaction imports from SMS

**Key Code:**

```dart
// Duplicate Check using Message Hash (Lines 10-44)
bool isDuplicate(String messageHash) {
  if (_processedHashes.contains(messageHash)) return true;
  _processedHashes.add(messageHash);
  return false;
}

// Hash Generation
String generateHash(String message) {
  return sha256.convert(utf8.encode(message)).toString();
}
```

---

### lib/services/sms_sync_manager.dart

**Purpose:** Orchestrates SMS sync with notification handling

**Key Code:**

```dart
// Scheduled Reminder Time Calculator (Lines 173-183)
DateTime _getNextScheduledReminderTime(DateTime now) {
  final today2PM = DateTime(now.year, now.month, now.day, 14);
  final today6PM = DateTime(now.year, now.month, now.day, 18);
  final today10PM = DateTime(now.year, now.month, now.day, 22);
  
  if (now.isBefore(today2PM)) return today2PM;
  if (now.isBefore(today6PM)) return today6PM;
  if (now.isBefore(today10PM)) return today10PM;
  return today2PM.add(const Duration(days: 1));
}

// Check and Send Reminder (Lines 195-215)
// - Checks if reminders enabled
// - Respects quiet hours
// - Calculates if 4 hours passed since last activity
// - Sends notification with unique ID
```

---

### lib/services/sms_sync_preference_service.dart

**Purpose:** SMS sync preference persistence

**Key Code:**

```dart
// Sync Preferences Model (Lines 9-85)
class SmsSyncPreferences {
  SyncPreference preference;        // none, previous, upcoming
  DateTime? previousFromDate;
  DateTime? lastSyncTime;
  bool periodicSyncEnabled;
  bool syncOnAppOpen;
  bool previousSyncCompleted;
  bool reminderEnabled;
  DateTime? lastAppOpenTime;
  DateTime? lastReminderSentTime;
  DateTime? lastManualTransactionTime;
  DateTime? pausedReminderTime;    // For quiet hours pause
  bool notificationPermissionAsked;
}

// Persistence with Hive (Lines 87-187)
// toMap/fromMap serialization
// Individual setters for each preference
```

---

### lib/providers/app_providers.dart

**Purpose:** All Riverpod providers for state management

**Key Code:**

```dart
// Service Providers (Lines 20-50)
final dbServiceProvider = Provider<DatabaseService>((_) => DatabaseService());
final authServiceProvider = Provider<AuthService>(...);
final transactionServiceProvider = Provider<TransactionService>(...);
final smsSyncManagerProvider = FutureProvider<SmsSyncManager>(...);

// Auth Controller (Lines 113-142)
class AuthController extends StateNotifier<AppUser?> {
  Future<void> hydrate() async {
    state = await _authService.getCurrentUser();
    _hydrationNotifier.setHydrated();
  }
  
  Future<bool> signup(String name, Country country) async {
    final user = await _authService.signup(name: name, country: country);
    state = user;
    return user != null;
  }
  
  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }
}

// Transactions Controller (Lines 189-245)
class TransactionsController extends StateNotifier<List<TransactionModel>> {
  Future<void> load(String userId) async {
    final transactions = await _service.getAll(userId);
    state = transactions;
  }
  
  Future<void> upsert(TransactionModel transaction) async {
    await _service.save(transaction);
    await load(_userId);
  }
}

// Filtered Transactions (Lines 221-245)
final filteredTransactionsProvider = Provider.family<List<TransactionModel>, TransactionFilter>((ref, filter) {
  final transactions = ref.watch(transactionsControllerProvider);
  // Apply category, type, date range filters
  return transactions.where((t) => ...).toList();
});

// Computed Providers
final monthlyExpensesProvider = Provider<double>((ref) {...});
final monthlyIncomeProvider = Provider<double>((ref) {...});
final monthlyBalanceProvider = Provider<double>((ref) {...});
final budgetProgressProvider = Provider<double>((ref) {...});
```

---

### lib/core/themes/app_theme.dart

**Purpose:** Material 3 theme configuration

**Key Code:**

```dart
// Light Theme (Lines 4-63)
static ThemeData light(Color accentColor) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(...),
    cardTheme: CardTheme(...),
    inputDecorationTheme: InputDecorationTheme(...),
  );
}

// Dark Theme (Lines 65-125)
static ThemeData dark(Color accentColor) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: Brightness.dark,
  );
  // Similar structure with dark-specific overrides
}
```

---

### lib/core/constants/app_constants.dart

**Purpose:** Categories, payment methods, accent colors

**Key Code:**

```dart
// Default Categories (Lines 4-17)
static const defaultCategories = [
  'Food & Dining',
  'Transport',
  'Shopping',
  'Bills & Utilities',
  'Entertainment',
  'Health',
  'Education',
  'Travel',
  'Personal Care',
  'Gifts',
  'Other',
];

// Accent Colors (Lines 62-71)
static const accentColors = [
  Color(0xFF6750A4),  // Purple (default)
  Color(0xFF0061A4),  // Blue
  Color(0xFF006E1C),  // Green
  Color(0xFFBA1A1A),  // Red
  Color(0xFFFF8B00),   // Orange
  Color(0xFF9C27B0),  // Deep Purple
  Color(0xFF00897B),   // Teal
];
```

---

### lib/views/home_shell.dart

**Purpose:** Main navigation shell with bottom nav and FAB

**Key Code:**

```dart
// App Lifecycle Observer (Lines 33-72)
class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {
  // Tracks app resume for reminder checks
  
  Future<void> _onAppResumed() async {
    final syncManagerAsync = await ref.read(smsSyncManagerProvider.future);
    await syncManagerAsync.setLastAppOpenTime(DateTime.now());
    await syncManagerAsync.onAppOpen();
    await syncManagerAsync.checkAndSendReminder();
  }
}

// Add Transaction (Lines 204-215)
void _showAddTransaction() async {
  final result = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const TransactionFormSheet(),
  );
  if (result is TransactionModel) {
    await ref.read(transactionsControllerProvider.notifier).upsert(result);
    // Track manual transaction for reminder logic
    final syncManagerAsync = await ref.read(smsSyncManagerProvider.future);
    await syncManagerAsync.setLastManualTransactionTime(DateTime.now());
  }
}
```

---

### lib/views/auth/signup_view.dart

**Purpose:** User onboarding with name and country selection

**Key Code:**

```dart
// Simple Signup Form (Lines 17-127)
class _SignupViewState extends ConsumerState<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  Country _selectedCountry = Country.countries.first;
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier)
        .signup(_name.text, _selectedCountry);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _name,
          validator: (v) => Validators.requiredField(v, field: 'Name'),
          decoration: const InputDecoration(
            labelText: 'Short Name',
            hintText: 'What should we call you?',
          ),
        ),
        DropdownButtonFormField<Country>(
          value: _selectedCountry,
          items: Country.countries.map((c) => DropdownMenuItem(
            value: c,
            child: Text('${c.name} (${c.currencySymbol})'),
          )).toList(),
        ),
        FilledButton(onPressed: _submit, child: const Text('Get Started')),
      ],
    );
  }
}
```

---

### lib/views/dashboard/dashboard_view.dart

**Purpose:** Home dashboard with balance, budget, recent transactions

**Key Code:**

```dart
// Monthly Balance Card (Lines 66-214)
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryColor, primaryColor.withOpacity(0.8)],
    ),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Column(
    children: [
      Text('Total Balance', style: TextStyle(color: Colors.white70)),
      Text('₹12,500', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BalanceItem('Income', incomeAmount, Icons.arrow_downward),
          _BalanceItem('Expense', expenseAmount, Icons.arrow_upward),
        ],
      ),
    ],
  ),
);

// Budget Progress Card (Lines 215-230)
// Shows circular progress indicator with percentage spent

// Recent Transactions (Lines 231-289)
ListView.builder(
  itemCount: recentTransactions.length,
  itemBuilder: (_, i) => TransactionTile(
    transaction: recentTransactions[i],
    onTap: () => _showTransactionDetails(recentTransactions[i]),
  ),
);
```

---

### lib/views/transactions/transaction_form_sheet.dart

**Purpose:** Add/Edit transaction bottom sheet

**Key Code:**

```dart
// Save Transaction (Lines 64-92)
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  
  final type = _selectedType.name == 'income' 
      ? TransactionType.income 
      : TransactionType.expense;
  
  final transaction = TransactionModel(
    id: _isEditing ? widget.transaction!.id : DateTime.now().microsecondsSinceEpoch.toString(),
    amount: double.parse(_amount.text),
    title: _title.text.trim(),
    category: _selectedCategory,
    type: type,
    date: _selectedDate,
    paymentMethod: _selectedPaymentMethod,
    source: TransactionSource.manual,
    note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
  );
  
  Navigator.pop(context, transaction);
}
```

---

### lib/views/settings/settings_view.dart

**Purpose:** All app settings including theme, budget, SMS sync, export

**Key Code:**

```dart
// SMS Sync Card (Lines 570-860)
class _SmsSyncCard extends ConsumerStatefulWidget {
  // Shows SMS permission status
  // Auto-sync toggle
  // Daily reminders toggle
  // Notifications disabled warning with Settings button
}

// CSV Export (Lines 292-359)
Future<void> _exportTransactions() async {
  final transactions = ref.read(transactionsControllerProvider);
  final user = ref.read(authControllerProvider);
  
  final rows = [
    ['Date', 'Title', 'Category', 'Type', 'Amount', 'Payment Method', 'Note'],
    ...transactions.map((t) => [
      DateFormat.yMd().format(t.date),
      t.title,
      t.category,
      t.type.name,
      t.amount.toString(),
      t.paymentMethod.name,
      t.note ?? '',
    ]),
  ];
  
  final csv = const ListToCsvConverter().convert(rows);
  // Save to file picker location
}
```

---

### lib/views/reports/reports_view.dart

**Purpose:** Analytics with charts using fl_chart

**Key Code:**

```dart
// Category Pie Chart (Lines 249-317)
PieChart(
  PieChartData(
    sections: categoryTotals.map((cat) => PieChartSectionData(
      value: cat.amount,
      title: '${cat.percentage.toStringAsFixed(1)}%',
      color: _categoryColors[cat.category],
    )).toList(),
    centerSpaceRadius: 40,
    sectionsSpace: 2,
  ),
);

// Monthly Bar Chart (Lines 319-487)
BarChart(
  BarChartData(
    barGroups: monthlyData.map((m) => BarChartGroupData(
      x: m.month,
      barRods: [
        BarChartRodData(
          toY: m.expense,
          color: expenseColor,
          width: 12,
        ),
        BarChartRodData(
          toY: m.income,
          color: incomeColor,
          width: 12,
        ),
      ],
    )).toList(),
  ),
);
```

---

### lib/widgets/transaction_tile.dart

**Purpose:** Swipeable transaction list tile with details

**Key Code:**

```dart
// Swipe Actions (Lines 27-54)
Dismissible(
  key: Key(transaction.id),
  direction: DismissDirection.horizontal,
  background: Container(color: Colors.red, child: Icon(Icons.delete)),
  secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit)),
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      return await _confirmDelete(context);
    } else {
      _editTransaction();
      return false;
    }
  },
  onDismissed: (_) => _deleteTransaction(),
);

// Transaction Display (Lines 55-156)
// Icon based on category
// Title, category, date
// Amount with color (green for income, red for expense)

// Details Modal (Lines 158-326)
void _showDetails() {
  showModalBottomSheet(
    context: context,
    builder: (_) => Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(transaction.title, style: Theme.of(context).textTheme.headlineSmall),
          _DetailRow('Category', transaction.category),
          _DetailRow('Amount', '₹${transaction.amount}'),
          _DetailRow('Date', DateFormat.yMMMd().format(transaction.date)),
          _DetailRow('Payment', transaction.paymentMethod.name),
          if (transaction.note != null) _DetailRow('Note', transaction.note!),
        ],
      ),
    ),
  );
}
```

---

## Notification System

### Reminder Schedule
- **First reminder:** 2 PM (if no activity since morning)
- **Interval:** Every 4 hours (2 PM → 6 PM → 10 PM)
- **Quiet hours:** 11 PM to 7 AM (no notifications)
- **Skip logic:** If user opens app within 3 hours of scheduled time

### Transaction Notifications
- **Trigger:** 2 minutes after SMS auto-sync completes
- **Quiet hours:** Respects 11 PM - 7 AM quiet hours

---

## SMS Sync Flow

```
1. User grants SMS permission
2. On sync trigger (manual or background):
   ├── MessageFilterService: Filter OTP/promotional
   ├── TransactionParser: Extract amount, type, date, category
   ├── DeduplicationService: Check if already processed
   └── SmsTransactionService: Save to database
3. NotificationService: Show delayed notification
```

---

## Setup & Development

### Prerequisites
- Flutter SDK >= 3.3.0
- Android SDK / Xcode (for iOS)

### Installation

```bash
# Clone repository
git clone <repo-url>
cd expense_tracker

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build Release

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Key Files for Background SMS

For SMS sync to work in background on Android, you may need to:
1. Disable battery optimization for the app
2. Add SMS permission to AndroidManifest.xml
3. Handle OEM-specific background restrictions (see `oem_instructions.dart`)

---

## Database Schema

### Users Box
```dart
{
  'id': String,
  'name': String,
  'country': String,
  'currencySymbol': String,
  'sessionToken': String?,
}
```

### Transactions Box
```dart
{
  'id': String,
  'amount': double,
  'title': String,
  'category': String,
  'type': String,  // 'income' or 'expense'
  'date': String,  // ISO8601
  'paymentMethod': String,
  'source': String,  // 'manual' or 'sms_auto'
  'note': String?,
  'userId': String,
}
```

### App Box
```dart
{
  'budget': {...},  // BudgetModel
  'accentColor': int,
  'themeMode': String,
}
```

### Processed SMS Box
```dart
// Key: message hash
// Value: timestamp
```

---

## Credits

Built with Flutter and various open-source packages.
