class MessageFilterService {
  const MessageFilterService();

  bool isOtpOrPromotional(String text) {
    final lowerText = text.toLowerCase();

    for (final pattern in _otpPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }

    for (final pattern in _promotionalPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  bool isTransactionRelated(String text) {
    final lowerText = text.toLowerCase();

    for (final pattern in _transactionPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  bool hasAmount(String text) {
    final lowerText = text.toLowerCase();

    for (final pattern in _amountPatterns) {
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }

    return false;
  }

  bool hasTransactionKeyword(String text) {
    final lowerText = text.toLowerCase();

    for (final keyword in _transactionKeywords) {
      if (lowerText.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  bool isValidTransaction(String text) {
    if (isOtpOrPromotional(text)) return false;
    if (isFailedTransaction(text)) return false;
    return hasAmount(text) && hasTransactionKeyword(text);
  }

  bool isFailedTransaction(String text) {
    final lowerText = text.toLowerCase();
    for (final pattern in _failedPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  static const _otpPatterns = [
    'otp',
    'one time password',
    'verification code',
    'security code',
    '2fa',
    'two factor',
    'auth code',
    'login otp',
    'transaction otp',
    'please do not share',
    'do not share',
    'enter otp',
    'otp for',
  ];

  static const _promotionalPatterns = [
    'promotion',
    'promotional',
    'click here',
    'subscribe',
    'subscribe now',
    'free',
    'bonus',
    'win',
    'winner',
    'congratulations',
    'you have won',
    'cashback expired',
    'offer ends',
    'limited time',
    'order id',
    'tracking',
    'delivery update',
    'out for delivery',
    'delivered to',
    'plan activated',
    'membership',
    'premium',
  ];

  static const _transactionPatterns = [
    'rs.',
    '₹',
    'rupee',
    'credited',
    'debited',
    'paid',
    'amount',
    'transfer',
    'upi',
    'bank',
    'account',
    'balance',
    'transaction',
  ];

  static final _amountPatterns = [
    RegExp(r'[\u20B9₹]\s*[\d,]+\.?\d*'),
    RegExp(r'rs\.?\s*[\d,]+\.?\d*', caseSensitive: false),
    RegExp(r'inr\s*[\d,]+\.?\d*', caseSensitive: false),
    RegExp(r'\$\s*[\d,]+\.?\d*'),
    RegExp(r'[\d,]+\.\d{2}'),
  ];

  static const _transactionKeywords = [
    'credited',
    'debited',
    'paid',
    'received',
    'deposited',
    'withdrawn',
    'transfer',
    'upi',
    'transaction',
    'sent',
    'spent',
    'refund',
    'cashback',
  ];

  static const _failedPatterns = [
    'failed',
    'failed to',
    'transaction failed',
    'declined',
    'unsuccessful',
    'could not complete',
    'not successful',
    'try again',
    'retry',
    'failed due to',
    'payment failed',
    'transfer failed',
    'payment declined',
    'insufficient balance',
    'low balance',
    'exceeded limit',
    'limit exceeded',
    'timeout',
    'timed out',
  ];
}
