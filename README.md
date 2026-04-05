# Developer Documentation

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Data Layer](#data-layer)
- [Key Components](#key-components)
- [Navigation](#navigation)
- [Theming](#theming)
- [Multi-Currency Support](#multi-currency-support)

---

## Architecture Overview

This expense tracker app follows a **Clean Architecture** pattern with separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                      Views (UI)                          │
│  Dashboard │ Transactions │ Reports │ Settings            │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Providers (Business Logic)            │
│  AuthController │ TransactionsController │ ThemeMode     │
│  currencySymbolProvider                                 │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                     Services (Data)                     │
│  AuthService │ TransactionService │ DatabaseService     │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                      Storage (Hive)                     │
│  Users Box │ Transactions Box │ Secure Storage           │
└─────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # App-wide constants
│   ├── themes/
│   │   └── app_theme.dart           # Light & dark theme definitions
│   └── utils/
│       └── validators.dart          # Form validation utilities
├── models/
│   ├── app_user.dart                 # User model + Country class
│   ├── transaction_model.dart        # Transaction data model
│   └── transaction_type.dart         # Income/Expense enum
├── providers/
│   └── app_providers.dart            # All Riverpod providers
├── services/
│   ├── auth_service.dart             # Authentication logic
│   ├── database_service.dart         # Hive database operations
│   └── transaction_service.dart      # Transaction CRUD operations
├── views/
│   ├── auth/
│   │   ├── login_view.dart          # Login screen
│   │   └── signup_view.dart         # Registration screen + country
│   ├── dashboard/
│   │   └── dashboard_view.dart      # Home/dashboard screen
│   ├── home_shell.dart               # Main shell with bottom nav
│   ├── reports/
│   │   └── reports_view.dart        # Analytics & charts
│   ├── settings/
│   │   └── settings_view.dart      # App settings + bug reporting
│   └── transactions/
│       ├── transaction_form_sheet.dart  # Add/Edit transaction modal
│       └── transactions_view.dart       # Transactions list
├── widgets/
│   ├── summary_card.dart             # Reusable summary card widget
│   └── transaction_tile.dart         # Transaction list item widget
└── main.dart                        # App entry point
```

---

## State Management

The app uses **Riverpod** for state management. All providers are defined in `lib/providers/app_providers.dart`.

### Key Providers

#### 1. Theme Provider
```dart
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  ref.watch(authControllerProvider);
  return ThemeMode.system;
});
```
- Manages light/dark/system theme state
- Located in `settings_view.dart` and controlled by a toggle switch
- Supports dynamic theme title (Light/Dark/System)

#### 2. Currency Symbol Provider
```dart
final currencySymbolProvider = Provider<String>((ref) {
  final user = ref.watch(authControllerProvider);
  return user?.currencySymbol ?? '₹';
});
```
- Provides the user's selected currency symbol
- Used throughout the app for displaying amounts
- Falls back to ₹ (Indian Rupee) if no user is logged in

#### 3. Authentication Provider
```dart
final authControllerProvider = StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.read(authServiceProvider));
});
```
- Manages user authentication state
- Handles login, signup (with country), logout, and session hydration

#### 4. Transactions Provider
```dart
final transactionsControllerProvider = StateNotifierProvider<TransactionsController, List<TransactionModel>>((ref) {
  return TransactionsController(ref.read(transactionServiceProvider));
});
```
- Manages list of transactions
- Handles CRUD operations (Create, Read, Update, Delete)

#### 5. Filter Provider
```dart
final transactionFilterProvider = StateProvider<TransactionFilter>((_) => const TransactionFilter());
final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  // Filters transactions based on category, type, date range, and search
});
```
- Provides filtered view of transactions for the transactions screen

---

## Data Layer

### Database Service (`services/database_service.dart`)

The database service manages all **Hive** boxes:

```dart
class DatabaseService {
  static const String usersBox = 'users';
  static const String transactionsBox = 'transactions';
  
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<AppUser>(usersBox);
    await Hive.openBox<TransactionModel>(transactionsBox);
  }
}
```

**Boxes:**
- `users` - Stores user accounts (with country and currency)
- `transactions` - Stores all transactions

### Authentication Service (`services/auth_service.dart`)

Handles user authentication with secure storage for passwords:

```dart
class AuthService {
  // Uses flutter_secure_storage for password hashing
  // Stores users in Hive with unique IDs
  // Signup includes country selection
}
```

**Security Features:**
- Passwords stored securely using `flutter_secure_storage`
- Session persisted across app restarts
- User's country and currency stored in user profile

### Transaction Service (`services/transaction_service.dart`)

Provides business logic for transactions:

```dart
class TransactionService {
  double incomeTotal(List<TransactionModel> items);
  double expenseTotal(List<TransactionModel> items);
  List<TransactionModel> getAll(String userId);
  Future<void> save(String userId, TransactionModel model);
  Future<void> delete(String id);
}
```

---

## Key Components

### Country Model (`models/app_user.dart`)

The `Country` class defines supported countries and their currencies:

```dart
class Country {
  final String name;
  final String code;
  final String currency;
  final String currencySymbol;

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
}
```

### AppUser Model

Extended to include country and currency:

```dart
class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String country;          // User's selected country
  final String currencySymbol;   // User's currency symbol
}
```

### Home Shell (`views/home_shell.dart`)

The main navigation container with bottom navigation bar:

```dart
class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  
  final _pages = const [
    DashboardView(),
    TransactionsView(),
    ReportsView(),
    SettingsView(),
  ];
}
```

**Features:**
- Manages tab navigation with `setState`
- Floating action button on dashboard only
- Animated page transitions
- Centered bottom navigation bar with rounded corners and shadow

### Transaction Model (`models/transaction_model.dart`)

```dart
@HiveType(typeId: 0)
class TransactionModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final TransactionType type;
  
  @HiveField(4)
  final String category;
  
  @HiveField(5)
  final DateTime date;
  
  @HiveField(6)
  final String note;
}
```

---

## Navigation

The app uses **go_router** for navigation (`main.dart`):

```dart
final _routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: user == null ? '/auth' : '/home',
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const _AuthWrapper()),
      GoRoute(path: '/home', builder: (_, __) => HomeShell(user: user!)),
    ],
    redirect: (_, state) {
      // Auth guard logic
    },
  );
});
```

**Navigation Flow:**
1. App starts → checks for existing session
2. No session → redirects to `/auth`
3. Has session → redirects to `/home`
4. Theme changes → stay on current page (uses provider-based routing)

---

## Theming

### Light & Dark Themes (`core/themes/app_theme.dart`)

```dart
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color(0xFFF8FAFC),
    // Clean white backgrounds
  );
  
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,  // Pure black for OLED
    cardTheme: CardThemeData(
      color: Color(0xFF0D0D0D),  // Near-black cards
    ),
    // ... transparent nav bar, etc.
  );
}
```

### Theme Features:
- **Light Mode**: Clean white/gray backgrounds
- **Dark Mode**: Pure black (`Colors.black`) for OLED screens
- **Pure Black Theme**: Near-black (`#0D0D0D`) for cards and inputs
- **Transparent Nav Bar**: Navigation bar uses transparent background with blur

### Theme Switching

Theme is controlled by `themeModeProvider` in settings:
1. **System** (default) - Follows device settings
2. **Light** - Always light mode
3. **Dark** - Always dark mode with pure black background

The router is a provider to prevent navigation resets on theme changes.

---

## Multi-Currency Support

### How It Works

1. **Signup**: User selects their country from a dropdown
2. **Currency Selection**: Country determines the currency symbol
3. **Dynamic Display**: All amounts use the user's currency symbol

### Provider Usage

```dart
// In any widget that displays currency
final currencySymbol = ref.watch(currencySymbolProvider);

// Format currency
final currencyFormat = NumberFormat.currency(
  symbol: currencySymbol,
  decimalDigits: 2,
);
```

### Adding New Countries

To add support for a new country:

1. Open `models/app_user.dart`
2. Add a new `Country` to the `Country.countries` list:
```dart
Country(
  name: 'Australia',
  code: 'AU',
  currency: 'AUD',
  currencySymbol: 'A\$',
),
```

---

## Help & Bug Reporting

The app includes a bug reporting feature that uses `url_launcher`:

```dart
Future<void> _reportBug(BuildContext context) async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'deepmujpara@gmail.com',
    queryParameters: {
      'subject': 'Bug Report - Expense Tracker',
      'body': 'Describe the bug...\n\nSteps to reproduce...',
    },
  );
  
  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  }
}
```

**Note**: The email body includes a template for users to fill in bug details.

---

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.5.1 | State management |
| go_router | ^14.2.7 | Navigation |
| hive | ^2.2.3 | Local database |
| hive_flutter | ^1.1.0 | Hive Flutter integration |
| flutter_secure_storage | ^9.2.2 | Secure credential storage |
| fl_chart | ^0.68.0 | Charts (pie, bar) |
| intl | ^0.19.0 | Date/currency formatting |
| csv | ^6.0.0 | CSV export |
| file_picker | ^8.1.2 | File save dialog |
| path_provider | ^2.1.4 | App directories |
| url_launcher | ^6.3.0 | Email intents for bug reporting |

---

## Adding New Features

### Adding a New Country

1. Update `Country.countries` list in `models/app_user.dart`
2. No other changes needed - currency will automatically work

### Adding a New Category

1. Update `TransactionFormSheet` in `views/transactions/transaction_form_sheet.dart`
2. Add the category to the `_categories` list with an icon

### Adding a New Screen

1. Create the view in `views/<section>/`
2. Add the route in `main.dart`
3. Add navigation item in `home_shell.dart`

### Modifying Transaction Data

1. Update `TransactionModel` in `models/transaction_model.dart`
2. Update Hive adapters if adding new fields
3. Update `TransactionService` if adding new business logic

---

## Building for Production

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## Testing

Run tests with:
```bash
flutter test
```

---

## License

This project is for educational purposes.
