import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/env.dart';
import 'core/config/router.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'features/invoices/providers/invoice_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/products/providers/product_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/vendors/providers/vendor_provider.dart';
import 'features/purchase_orders/providers/purchase_order_provider.dart';
import 'features/bills/providers/bill_provider.dart';
import 'features/quotations/providers/quotation_provider.dart';
import 'features/credit_notes/providers/credit_note_provider.dart';
import 'features/proforma_invoices/providers/proforma_invoice_provider.dart';
import 'modules/expenses/providers/expense_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => QuotationProvider()),
        ChangeNotifierProvider(create: (_) => CreditNoteProvider()),
        ChangeNotifierProvider(create: (_) => ProformaInvoiceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    // Set up unauthorized callback to auto logout on refresh token failure
    ApiService().onUnauthorized = () {
      context.read<AuthProvider>().logout();
    };

    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
            
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? const Color(0xFF111827) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'Prabhim One',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
