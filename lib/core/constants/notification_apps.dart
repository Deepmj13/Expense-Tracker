class NotificationApp {
  final String packagePattern;
  final String name;
  final String category;

  const NotificationApp({
    required this.packagePattern,
    required this.name,
    required this.category,
  });
}

class NotificationApps {
  static const List<NotificationApp> defaultApps = [
    NotificationApp(
      packagePattern: 'com.google.android.apps.nbu.paisa.user',
      name: 'Google Pay',
      category: 'UPI',
    ),
    NotificationApp(
      packagePattern: 'com.phonepe.app',
      name: 'PhonePe',
      category: 'UPI',
    ),
    NotificationApp(
      packagePattern: 'net.one97.paytm',
      name: 'Paytm',
      category: 'UPI',
    ),
    NotificationApp(
      packagePattern: 'in.org.npci.upiapp',
      name: 'BHIM UPI',
      category: 'UPI',
    ),
    NotificationApp(
      packagePattern: 'com.paypal.app',
      name: 'PayPal',
      category: 'Payment',
    ),
    NotificationApp(
      packagePattern: 'com.venmo',
      name: 'Venmo',
      category: 'Payment',
    ),
    NotificationApp(
      packagePattern: 'com.amazon.mobile.shopping',
      name: 'Amazon',
      category: 'Shopping',
    ),
    NotificationApp(
      packagePattern: 'com.flipkart.android',
      name: 'Flipkart',
      category: 'Shopping',
    ),
    NotificationApp(
      packagePattern: 'in.swiggy.android',
      name: 'Swiggy',
      category: 'Food',
    ),
    NotificationApp(
      packagePattern: 'com.zomato',
      name: 'Zomato',
      category: 'Food',
    ),
    NotificationApp(
      packagePattern: 'com.ola.driver',
      name: 'Ola',
      category: 'Transport',
    ),
    NotificationApp(
      packagePattern: 'com.ubercab',
      name: 'Uber',
      category: 'Transport',
    ),
    NotificationApp(
      packagePattern: 'com.mobiwik',
      name: 'MobiKwik',
      category: 'UPI',
    ),
    NotificationApp(
      packagePattern: 'com.freecharge.android',
      name: 'FreeCharge',
      category: 'UPI',
    ),
    NotificationApp(
      packagePattern: 'com.airtel.returns',
      name: 'Airtel Thanks',
      category: 'Bills',
    ),
    NotificationApp(
      packagePattern: 'com.bsbhome.mytata',
      name: 'Tata Cliq',
      category: 'Shopping',
    ),
    NotificationApp(
      packagePattern: 'com.meesho.supply',
      name: 'Meesho',
      category: 'Shopping',
    ),
    NotificationApp(
      packagePattern: 'in.mohalla.video',
      name: 'Moj',
      category: 'Entertainment',
    ),
    NotificationApp(
      packagePattern: 'com.jio.media.jiobeats',
      name: 'JioSaavn',
      category: 'Entertainment',
    ),
    NotificationApp(
      packagePattern: 'com.netflix.mediaclient',
      name: 'Netflix',
      category: 'Entertainment',
    ),
    NotificationApp(
      packagePattern: 'com.spotify.music',
      name: 'Spotify',
      category: 'Entertainment',
    ),
    NotificationApp(
      packagePattern: 'in.startv.hotstar',
      name: 'Disney+ Hotstar',
      category: 'Entertainment',
    ),
    NotificationApp(
      packagePattern: 'com.samsung.android.spay',
      name: 'Samsung Pay',
      category: 'UPI',
    ),
    NotificationApp(
      packagePattern: 'in.amazon.mShop.android.shopping',
      name: 'Amazon Shopping',
      category: 'Shopping',
    ),
    NotificationApp(
      packagePattern: 'com.yesbank',
      name: 'Yes Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.axis.mobile',
      name: 'Axis Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.sbi.lotusretail',
      name: 'State Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.hdfc.bank',
      name: 'HDFC Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.icici.bank',
      name: 'ICICI Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.kotakbank.netbanking',
      name: 'Kotak Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'in.co.pnbnetbank',
      name: 'Punjab National Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.bankofbaroda',
      name: 'Bank of Baroda',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.indus.android.indusnetbank',
      name: 'IndusInd Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.canarabank',
      name: 'Canara Bank',
      category: 'Banking',
    ),
    NotificationApp(
      packagePattern: 'com.bandhan',
      name: 'Bandhan Bank',
      category: 'Banking',
    ),
  ];

  static List<String> get defaultPackagePatterns =>
      defaultApps.map((app) => app.packagePattern).toList();

  static NotificationApp? findAppByPackage(String packageName) {
    for (final app in defaultApps) {
      if (packageName == app.packagePattern ||
          packageName.startsWith('${app.packagePattern}.')) {
        return app;
      }
    }
    return null;
  }
}
