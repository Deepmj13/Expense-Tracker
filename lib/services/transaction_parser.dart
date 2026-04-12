import '../models/notification_model.dart';
import '../models/parsed_transaction.dart';
import '../models/transaction_type.dart';
import '../core/constants/notification_apps.dart';

class TransactionParser {
  const TransactionParser();

  ParsedTransaction? parse(NotificationModel notification) {
    final rawText = notification.rawText;
    final packageName = notification.packageName;

    final amount = extractAmount(rawText);
    if (amount == null || amount <= 0) return null;

    final type = determineType(rawText);
    final source = extractSource(rawText, type == TransactionType.income);
    final category = determineCategory(rawText, packageName);
    final title = generateTitle(rawText, packageName, source);

    return ParsedTransaction(
      amount: amount,
      type: type,
      title: title,
      category: category,
      source: source,
      rawText: rawText,
      timestamp: notification.receivedAt,
    );
  }

  double? extractAmount(String text) {
    final amounts = extractAllAmounts(text);
    if (amounts.isEmpty) return null;
    return amounts.reduce((a, b) => a > b ? a : b);
  }

  List<double> extractAllAmounts(String text) {
    final Set<double> amountSet = {};
    final patterns = [
      RegExp(r'[\u20B9₹]\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'rs\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'inr\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'\$\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'(?:amount|amt)[:\s]*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
      RegExp(r'(?:rs\.?|₹)\s*([\d,]*\.\d{2})\b'),
      RegExp(r'\b([\d,]+\.\d{2})\b'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        if (match.groupCount >= 1) {
          final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0 && amount < 100000000) {
            amountSet.add(amount);
          }
        }
      }
    }

    return amountSet.toList();
  }

  TransactionType determineType(String text) {
    final lowerText = text.toLowerCase();

    final creditKeywords = [
      'credited',
      'received',
      'deposited',
      'refund',
      'refunded',
      'cashback',
      'reward',
      'salary',
      'interest earned',
      'money in',
      'funds received',
      'added to',
      'loaded',
      'recharged',
      'money returned',
      'amount returned',
      'reversed',
      'chargeback',
      'money back',
      'credited back',
      'debited back',
      'claim credited',
      'settlement',
    ];

    final debitKeywords = [
      'debited',
      'paid',
      'spent',
      'withdrawn',
      'deducted',
      'transfer to',
      'payment to',
      'paid to',
      'sent to',
      'transfer from',
      'withdraw',
    ];

    for (final keyword in creditKeywords) {
      if (lowerText.contains(keyword)) {
        return TransactionType.income;
      }
    }

    for (final keyword in debitKeywords) {
      if (lowerText.contains(keyword)) {
        return TransactionType.expense;
      }
    }

    return TransactionType.expense;
  }

  ParsedSource? extractSource(String text, bool isCredit) {
    final lowerText = text.toLowerCase();

    String? upiId;
    String? bankName;
    String? appName;

    final upiPatterns = [
      RegExp(
          r'(?:from|received from|credited by|paid to|paid by|sent to)\s*([a-z0-9]+@[a-z]+)',
          caseSensitive: false),
      RegExp(r'([a-z0-9]+@[a-z]+)\s*(?:on|via|at)', caseSensitive: false),
      RegExp(r'upi\s*(?:id)?\s*[:\-]?\s*([a-z0-9]+@[a-z]+)',
          caseSensitive: false),
    ];

    for (final pattern in upiPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null && match.groupCount >= 1) {
        upiId = match.group(1);
        break;
      }
    }

    if (upiId == null) {
      final simpleUpiPattern = RegExp(r'([a-z0-9]+@[a-z]{2,})');
      final match = simpleUpiPattern.firstMatch(lowerText);
      if (match != null) {
        upiId = match.group(1);
      }
    }

    bankName = _extractBankName(lowerText);

    return ParsedSource(
      upiId: isCredit ? upiId : null,
      bankName: bankName,
      appName: appName,
    );
  }

  String? _extractBankName(String text) {
    final bankPatterns = {
      'sbi': ['sbi', 'state bank', 'statebank', 'yono', 'onlinesbi'],
      'hdfc': ['hdfc', 'hdfc bank', 'netbanking'],
      'icici': ['icici', 'icici bank', 'icici quick', 'icicibank'],
      'axis': ['axis', 'axis bank', 'axisbank', 'axispay'],
      'kotak': ['kotak', 'kotak bank', 'kotak81'],
      'yes bank': ['yes bank', 'yesbank'],
      'pnb': ['pnb', 'punjab national', 'pnbank', 'punjab national bank'],
      'bank of baroda': ['bank of baroda', 'bob', 'baroda'],
      'canara': ['canara', 'canara bank'],
      'indusind': ['indusind', 'indusind bank'],
      'idbi': ['idbi', 'idbi bank'],
      'bandhan': ['bandhan', 'bandhan bank'],
      'uco': ['uco', 'uco bank'],
      'union bank': ['union bank'],
      'central bank': ['central bank', 'central bank of india'],
      'federal': ['federal', 'federal bank'],
      'south indian': ['south indian', 'sib', 'south indian bank'],
      'idfc': ['idfc', 'idfc first'],
      'rbl': ['rbl', 'rbl bank'],
      'standard chartered': ['standard chartered', 'sc bank'],
      'citi': ['citi', 'citibank'],
      'hsbc': ['hsbc'],
      'deutsche': ['deutsche bank'],
      'paytm': ['paytm', 'paytm bank'],
      'phonepe': ['phonepe', 'phone pe'],
      'gpay': ['google pay', 'gpay', 'tez', 'googlepay'],
      'bhim': ['bhim', 'bhim upi', 'upi'],
      'amazon pay': ['amazon pay', 'amazonpay'],
      'mobiwik': ['mobiwik'],
      'freecharge': ['freecharge'],
      'airtel': ['airtel payments', 'airtel money'],
      'jio': ['jio pay', 'jiopay'],
    };

    for (final entry in bankPatterns.entries) {
      for (final pattern in entry.value) {
        if (text.contains(pattern)) {
          return entry.key.toUpperCase();
        }
      }
    }

    return null;
  }

  String determineCategory(String text, String packageName) {
    final lowerText = text.toLowerCase();

    final categoryKeywords = {
      'Food': [
        'food',
        'restaurant',
        'swiggy',
        'zomato',
        'pizza',
        'burger',
        'meal',
        'dinner',
        'lunch',
        'breakfast',
        'dominos',
        'kfc',
      ],
      'Travel': [
        'uber',
        'ola',
        'taxi',
        'flight',
        'train',
        'bus',
        'metro',
        'railway',
        'irctc',
        'redbus',
      ],
      'Transport': [
        'petrol',
        'diesel',
        'fuel',
        'parking',
        'toll',
        'auto',
        'rickshaw',
        'cab',
      ],
      'Shopping': [
        'amazon',
        'flipkart',
        'myntra',
        'snapdeal',
        'shop',
        'store',
        'tata cliq',
        'meesho',
        'ajio',
        'nykaa',
      ],
      'Bills': [
        'bill',
        'electricity',
        'water bill',
        'gas',
        'recharge',
        'prepaid',
        'postpaid',
        'mobile',
        'broadband',
        'dth',
      ],
      'Entertainment': [
        'netflix',
        'spotify',
        'hotstar',
        'disney',
        'movie',
        'game',
        'subscription',
        'youtube',
        'prime',
        'sony liv',
        'zee5',
      ],
      'Health': [
        'doctor',
        'medicine',
        'hospital',
        'pharmacy',
        'health',
        'medical',
        'clinic',
        'diagnostic',
        'pathlab',
      ],
      'Education': [
        'course',
        'tuition',
        'book',
        'school',
        'college',
        'fee',
        'university',
        'coaching',
        'udemy',
        'coursera',
      ],
      'Salary': [
        'salary',
        'income',
        'refund',
      ],
      'Investment': [
        'sip',
        'mutual fund',
        'stock',
        'fd',
        'recurring',
        'share',
        'demat',
        'zerodha',
        'groww',
      ],
      'Groceries': [
        'grocery',
        'bigbasket',
        'blinkit',
        'zepto',
        'supermarket',
        'DMart',
        'reliance fresh',
      ],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    final appInfo = NotificationApps.findAppByPackage(packageName);
    if (appInfo != null) {
      final appCategoryMap = {
        'UPI': 'Transfer',
        'Banking': 'Banking',
        'Shopping': 'Shopping',
        'Food': 'Food',
        'Transport': 'Transport',
        'Bills': 'Bills',
        'Entertainment': 'Entertainment',
        'Subscription': 'Entertainment',
      };
      final mappedCategory = appCategoryMap[appInfo.category];
      if (mappedCategory != null) {
        return mappedCategory;
      }
    }

    return 'Other';
  }

  String generateTitle(String text, String packageName, ParsedSource? source) {
    if (text.length > 4) {
      final truncated = text.length > 50 ? '${text.substring(0, 47)}...' : text;
      return _capitalizeWords(truncated);
    }

    final appInfo = NotificationApps.findAppByPackage(packageName);
    if (appInfo != null) {
      return 'Transaction via ${appInfo.name}';
    }

    if (source?.upiId != null) {
      return 'Transaction ${source!.upiId}';
    }

    if (source?.bankName != null) {
      return 'Transaction ${source!.bankName}';
    }

    return 'Notification Transaction';
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word == '₹') return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
