# AGENTS.md - Expense Tracker

## Skill: Software Development Coding Agent
### Overview
Generate clean, readable, efficient code following language conventions. Debug and optimize. Apply SOLID, DRY, KISS principles.
### Code Style
- Avoid comments unless explaining non-obvious logic
- Follow existing patterns in this repo (singleton services, Riverpod naming, ConsumerWidget)
- Prefer `const` constructors and minimal widget nesting
### Debugging
- Provide root cause analysis with minimal fixes
- Explain issues clearly when needed
### Testing
- Write tests for new features; run `flutter test`
- Test file: `test/widget_test.dart`
### Constraints
- Do not generate insecure code
- Do not assume missing requirements—ask if unclear
- Keep solutions practical, not overly theoretical

## Commands

```bash
# Install dependencies
flutter pub get

# Run app (debug)
flutter run

# Analyze / lint
flutter analyze

# Build release APK
flutter build apk --release
```

## Architecture

- **Entry point**: `lib/main.dart` - initializes Hive, notifications, background sync
- **State management**: Riverpod (`lib/providers/app_providers.dart`)
- **Routing**: go_router in `lib/main.dart`
- **Database**: Hive local storage (4 boxes: users, transactions, app_data, processed_sms)

```
lib/
├── main.dart           # Entry + router
├── models/           # Data classes (AppUser, TransactionModel, BudgetModel)
├── services/         # Business logic (auth, transaction, SMS, notifications)
├── providers/       # Riverpod state
├── views/            # UI screens (auth/, dashboard/, transactions/, reports/, settings/)
├── widgets/          # Shared widgets
└── core/            # Themes, constants, utils
```

## Key Patterns

- **Services**: Singleton pattern used (e.g., `NotificationService.instance`)
- **Models**: Include `toMap()`/`fromMap()` for Hive serialization
- **Providers**: Follow naming `XxxController extends StateNotifier<...>`
- **Views**: Use ConsumerWidget/ConsumerStatefulWidget for Riverpod

## State Management

- Auth flow: `authControllerProvider` (StateNotifier<AppUser?>)
- Transactions: `transactionsControllerProvider` (StateNotifier<List<TransactionModel>>)
- Filtered transactions: `filteredTransactionsProvider.family` with TransactionFilter param
- Computed: `monthlyExpensesProvider`, `monthlyIncomeProvider`, `monthlyBalanceProvider`

## Data Models

- **AppUser**: id, name, country, currencySymbol
- **TransactionModel**: id, amount, title, category, type, date, paymentMethod, source, note
- **TransactionType**: income, expense (enum)
- **PaymentMethod**: cash, bank, upi, card, other (enum)
- **TransactionSource**: manual, sms_auto (enum)

## Hive Boxes

- `users`: Map - user data
- `transactions`: Map - transaction records  
- `app_data`: Map - budget, accentColor, themeMode
- `processed_sms`: String - deduplication hashes

## Important Files

- `lib/core/constants/app_constants.dart`: Categories list, accent colors
- `lib/core/themes/app_theme.dart`: Material 3 theming
- `lib/services/transaction_parser.dart`: SMS parsing logic
- `lib/services/sms_sync_manager.dart`: Reminder scheduling (2 PM, 6 PM, 10 PM)
- `lib/core/constants/oem_instructions.dart`: OEM-specific background restrictions

## Testing

- Test file: `test/widget_test.dart`
- Run: `flutter test`

## Lint

- Uses `flutter_lints` (package:flutter_lints/flutter.yaml)
- Run: `flutter analyze`