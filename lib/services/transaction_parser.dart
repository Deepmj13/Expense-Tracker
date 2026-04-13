import '../models/transaction_message_model.dart';
import '../models/parsed_transaction.dart';
import '../models/transaction_type.dart';

class _AmountPattern {
  _AmountPattern(this.regex, this.priority);
  final RegExp regex;
  final int priority;
}

class _AmountMatch {
  _AmountMatch(this.amount, this.position, this.priority);
  final double amount;
  final int position;
  final int priority;
}

class _TypeResult {
  _TypeResult(this.type, this.isCredit);
  final TransactionType type;
  final bool isCredit;
}

class TransactionParser {
  const TransactionParser();

  ParsedTransaction? parse(TransactionMessageModel message) {
    final rawText = message.rawText;
    final packageName = message.packageName;

    final typeResult = determineType(rawText);
    if (typeResult == null) return null;

    final amount = extractAmount(rawText, typeResult.isCredit);
    if (amount == null || amount <= 0) return null;

    final source = extractSource(rawText, typeResult.isCredit);
    final category = determineCategory(rawText, packageName);
    final title = generateTitle(
        rawText, packageName, source, typeResult.isCredit, amount);

    return ParsedTransaction(
      amount: amount,
      type: typeResult.type,
      title: title,
      category: category,
      source: source,
      rawText: rawText,
      timestamp: message.receivedAt,
    );
  }

  double? extractAmount(String text, bool isCredit) {
    final amounts = extractAllAmountsWithContext(text, isCredit);
    if (amounts.isEmpty) return null;
    return amounts.first;
  }

  List<double> extractAllAmountsWithContext(String text, bool isCredit) {
    final List<_AmountMatch> matches = [];
    final patterns = [
      _AmountPattern(RegExp(r'[\u20B9₹]\s*([\d,]+(?:\.\d{1,2})?)'), 10),
      _AmountPattern(
          RegExp(r'rs\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false), 9),
      _AmountPattern(
          RegExp(r'inr\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false), 8),
      _AmountPattern(RegExp(r'\$\s*([\d,]+(?:\.\d{1,2})?)'), 7),
      _AmountPattern(
          RegExp(r'(?:amount|amt)[:\s]*([\d,]+(?:\.\d{1,2})?)',
              caseSensitive: false),
          6),
      _AmountPattern(RegExp(r'\b([\d,]+\.\d{2})\b'), 1),
    ];

    final lowerText = text.toLowerCase();

    for (final pattern in patterns) {
      for (final match in pattern.regex.allMatches(text)) {
        if (match.groupCount >= 1) {
          final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0 && amount < 100000000) {
            matches.add(_AmountMatch(amount, match.start, pattern.priority));
          }
        }
      }
    }

    if (matches.isEmpty) return [];

    _AmountMatch? transactionAmount;

    if (isCredit) {
      final creditedPatterns = [
        'credited',
        'received',
        'deposited',
        'refund',
        'cashback',
      ];

      for (final keyword in creditedPatterns) {
        final keywordIndex = lowerText.indexOf(keyword);
        if (keywordIndex != -1) {
          transactionAmount = _findClosestAmount(matches, keywordIndex);
          break;
        }
      }
    } else {
      final debitedPatterns = [
        'debited',
        'paid',
        'spent',
        'withdrawn',
        'deducted',
        'payment to',
      ];

      for (final keyword in debitedPatterns) {
        final keywordIndex = lowerText.indexOf(keyword);
        if (keywordIndex != -1) {
          transactionAmount = _findClosestAmount(matches, keywordIndex);
          break;
        }
      }
    }

    transactionAmount ??=
        matches.reduce((a, b) => a.priority > b.priority ? a : b);

    return [transactionAmount.amount];
  }

  _AmountMatch _findClosestAmount(
      List<_AmountMatch> matches, int keywordIndex) {
    _AmountMatch? closest;
    int minDistance = 999999;

    for (final match in matches) {
      final distance = (match.position - keywordIndex).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closest = match;
      }
    }

    return closest!;
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

  _TypeResult? determineType(String text) {
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
        return _TypeResult(TransactionType.income, true);
      }
    }

    for (final keyword in debitKeywords) {
      if (lowerText.contains(keyword)) {
        return _TypeResult(TransactionType.expense, false);
      }
    }

    return null;
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

    return 'Other';
  }

  String generateTitle(String text, String packageName, ParsedSource? source,
      bool isCredit, double amount) {
    final lowerText = text.toLowerCase();
    final currencySymbol = text.contains('₹')
        ? '₹'
        : (text.contains('rs') || text.contains('inr') ? 'Rs.' : '\$');

    String? merchantName;

    final merchantPatterns = [
      'swiggy',
      'zomato',
      'ubereats',
      'dominos',
      'pizza hut',
      'kfc',
      'mcdonalds',
      'amazon',
      'flipkart',
      'myntra',
      'snapdeal',
      'meesho',
      'ajio',
      'nykaa',
      'uber',
      'ola',
      'rapido',
      'indriver',
      'paytm',
      'phonepe',
      'gpay',
      'google pay',
      'bhim',
      'netflix',
      'prime',
      'hotstar',
      'disney',
      'spotify',
      'youtube premium',
      'airtel',
      'jio',
      'bsnl',
      'electricity',
      'gas bill',
      'water bill',
    ];

    for (final merchant in merchantPatterns) {
      if (lowerText.contains(merchant)) {
        merchantName = _capitalizeFirst(merchant);
        break;
      }
    }

    if (merchantName != null) {
      return '$merchantName Payment';
    }

    if (source?.upiId != null) {
      return 'UPI ${isCredit ? 'Received' : 'Payment'}';
    }

    if (source?.bankName != null) {
      return '${source!.bankName} ${isCredit ? 'Credit' : 'Debit'}';
    }

    if (source?.appName != null) {
      return '${source!.appName} Transaction';
    }

    return '${isCredit ? '+' : '-'}$currencySymbol${amount.toStringAsFixed(0)} ${isCredit ? 'Received' : 'Paid'}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
