import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_notifications.dart';
import 'core/storage.dart';
import 'core/router.dart';
import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/service_request_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/visit_provider.dart';
import 'providers/invoice_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await Storage.init();
  await AppNotifications.instance.init();
  runApp(const TeklifProApp());
}

class TeklifProApp extends StatelessWidget {
  const TeklifProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ServiceRequestProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => VisitProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context);
          return MaterialApp.router(
            title: 'Teklif Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
