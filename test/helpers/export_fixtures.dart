import 'package:expense_tracker/models/app_user.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/transaction_type.dart';

AppUser fixtureUser({
  String id = 'user-1',
  String name = 'Asha Patel',
  String country = 'India',
  String currencySymbol = '₹',
}) {
  return AppUser(
    id: id,
    name: name,
    country: country,
    currencySymbol: currencySymbol,
  );
}

TransactionModel fixtureTransaction({
  String id = 'tx-1',
  double amount = 100,
  TransactionType type = TransactionType.expense,
  String category = 'Food',
  required DateTime date,
  String title = 'Lunch',
  String note = '',
  PaymentMethod paymentMethod = PaymentMethod.cash,
}) {
  return TransactionModel(
    id: id,
    title: title,
    amount: amount,
    type: type,
    category: category,
    date: date,
    note: note,
    paymentMethod: paymentMethod,
  );
}
