import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/sms_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await NotificationService().init();
  await BackgroundService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SmsHomePage(),
    );
  }
}

class SmsHomePage extends StatefulWidget {
  const SmsHomePage({super.key});

  @override
  State<SmsHomePage> createState() => _SmsHomePageState();
}

class _SmsHomePageState extends State<SmsHomePage> {
  final SmsService _smsService = SmsService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messages = await _smsService.getStoredMessages();
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
  }

  Future<void> _requestPermissionsAndSync() async {
    // Check current status before requesting
    PermissionStatus smsStatus = await Permission.sms.status;
    PermissionStatus notificationStatus = await Permission.notification.status;

    if (!smsStatus.isGranted || !notificationStatus.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
        Permission.notification,
      ].request();
      smsStatus = statuses[Permission.sms]!;
      notificationStatus = statuses[Permission.notification]!;
    }

    if (!mounted) return;

    if (smsStatus.isGranted) {
      setState(() => _isLoading = true);
      try {
        await _smsService.fetchAndStoreSms();
        await _loadMessages();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS synchronized successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: ${e.toString()}')));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS permission is required to read messages'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Reader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _requestPermissionsAndSync,
            tooltip: 'Sync SMS',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No messages found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestPermissionsAndSync,
                    child: const Text('Request Permission & Sync'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.message)),
                  title: Text(msg['address'] ?? 'Unknown'),
                  subtitle: Text(msg['body'] ?? ''),
                  trailing: Text(
                    DateTime.fromMillisecondsSinceEpoch(
                      msg['date'],
                    ).toString().split(' ')[0],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}
