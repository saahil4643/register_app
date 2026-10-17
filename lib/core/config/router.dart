import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/authentication/providers/auth_provider.dart';
import '../../features/authentication/screens/forgot_password_screen.dart';
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/otp_verification_screen.dart';
import '../../features/authentication/screens/reset_password_screen.dart';
import '../../features/authentication/screens/signup_screen.dart';
import '../../features/authentication/screens/splash_screen.dart';
import '../../features/authentication/screens/success_screen.dart';
import '../../features/authentication/screens/welcome_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/navigation/navigation_shell.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/profile_business_settings_screen.dart';
import '../../features/shared/placeholder_screen.dart';
import '../../features/invoices/screens/invoice_list/invoice_list_screen.dart';
import '../../features/invoices/screens/new_invoice/new_invoice_screen.dart';
import '../../features/invoices/screens/product_picker_screen.dart';
import '../../features/invoices/screens/invoice_preview_screen.dart';
import '../../features/invoices/screens/invoice_details/invoice_details_screen.dart';
import '../../features/customers/screens/customers_list_screen.dart';
import '../../features/products/screens/products_list_screen.dart';
import '../../features/invoices/screens/new_invoice/add_customer_overlay_screen.dart';
import '../../modules/expenses/screens/add_expense_screen.dart';
import '../../modules/expenses/screens/expense_list_screen.dart';
import '../../modules/expenses/models/expense_model.dart';
import '../../features/vendors/screens/vendors_list_screen.dart';
import '../../features/vendors/screens/new_vendor_screen.dart';
import '../../features/vendors/models/vendor.dart';
import '../../features/purchase_orders/screens/purchase_orders_list_screen.dart';
import '../../features/purchase_orders/screens/new_purchase_order_screen.dart';
import '../../features/purchase_orders/models/purchase_order.dart';
import '../../features/bills/screens/bills_list_screen.dart';
import '../../features/bills/screens/new_bill_screen.dart';
import '../../features/bills/models/bill.dart';
import '../../features/quotations/screens/quotations_list_screen.dart';
import '../../features/quotations/screens/new_quotation_screen.dart';
import '../../features/credit_notes/screens/credit_notes_list_screen.dart';
import '../../features/credit_notes/screens/new_credit_note_screen.dart';
import '../../features/proforma_invoices/screens/proforma_invoices_list_screen.dart';
import '../../features/proforma_invoices/screens/new_proforma_invoice_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final bool loggedIn = authProvider.isAuthenticated;
        final bool isUnverified = authProvider.isEmailUnverified || (authProvider.pendingVerificationEmail != null);
        
        final bool isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation == '/otp-verify' ||
            state.matchedLocation == '/reset-password' ||
            state.matchedLocation == '/success';

        // Check if loading or splash
        if (state.matchedLocation == '/') {
          return null;
        }

        // If unverified, redirect to OTP verification (except success screen or otp-verify page itself)
        if (isUnverified && state.matchedLocation != '/otp-verify' && state.matchedLocation != '/success') {
          if (loggedIn || !isAuthRoute) {
            return '/otp-verify';
          }
        }

        if (!loggedIn) {
          return isAuthRoute ? null : '/welcome';
        }

        // If logged in, they shouldn't visit login screens
        if (loggedIn && isAuthRoute) {
          // If we just got verified or completed reset, let SuccessScreen handle it
          // but otherwise, send directly to dashboard
          if (state.matchedLocation == '/success') {
            return null;
          }
          return '/dashboard';
        }

        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Auth Flow
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/otp-verify',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return OtpVerificationScreen(arguments: args);
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return ResetPasswordScreen(arguments: args);
          },
        ),
        GoRoute(
          path: '/success',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return SuccessScreen(arguments: args);
          },
        ),

        // Stateful Navigation Shell
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return NavigationShell(navigationShell: navigationShell);
          },
          branches: [
            // Branch 1: Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            
            // Branch 2: Invoices
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/invoices',
                  builder: (context, state) => const InvoiceListScreen(),
                ),
              ],
            ),

            // Branch 3: Customers
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/customers',
                  builder: (context, state) => const CustomersListScreen(),
                ),
              ],
            ),

            // Branch 4: Products
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/products',
                  builder: (context, state) => const ProductsListScreen(),
                ),
              ],
            ),

            // Branch 5: Expenses
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/expenses',
                  builder: (context, state) => const ExpenseListScreen(),
                ),
              ],
            ),

            // Branch 6: Settings
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),

        // Protected Routes outside Shell (Push Navigation)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/invoices/create',
          builder: (context, state) => const NewInvoiceScreen(isEditing: false),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/invoices/edit',
          builder: (context, state) => const NewInvoiceScreen(isEditing: true),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/invoices/products',
          builder: (context, state) => const ProductPickerScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/invoices/preview',
          builder: (context, state) => const InvoicePreviewScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/invoices/create/add-customer',
          pageBuilder: (context, state) {
            final prefillName = state.extra as String? ?? '';
            return CustomTransitionPage<void>(
              key: state.pageKey,
              opaque: false,
              barrierColor: Colors.transparent,
              child: AddCustomerOverlayScreen(prefillName: prefillName),
              transitionsBuilder: (ctx, animation, _, child) => FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: child,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/invoices/details/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return InvoiceDetailsScreen(invoiceId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/profile',
          builder: (context, state) => const ProfileBusinessSettingsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/notifications',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Notifications Hub',
            description: 'Check automated reminders for overdue invoices, login sessions, and payment gateway events.',
            icon: Icons.notifications_active_outlined,
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/reports',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Financial Reports',
            description: 'View balance sheets, general ledgers, cash flow statements, and tax summary tables.',
            icon: Icons.bar_chart_outlined,
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/quotations',
          builder: (context, state) => const QuotationsListScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/quotations/create',
          builder: (context, state) => const NewQuotationScreen(isEditing: false),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/quotations/edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return NewQuotationScreen(isEditing: true, quotationId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/credit-notes',
          builder: (context, state) => const CreditNotesListScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/credit-notes/create',
          builder: (context, state) => const NewCreditNoteScreen(isEditing: false),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/credit-notes/edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return NewCreditNoteScreen(isEditing: true, creditNoteId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/proforma-invoices',
          builder: (context, state) => const ProformaInvoicesListScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/proforma-invoices/create',
          builder: (context, state) => const NewProformaInvoiceScreen(isEditing: false),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/sales/proforma-invoices/edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return NewProformaInvoiceScreen(isEditing: true, proformaId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Purchases',
            description: 'Manage procurement, purchase orders, vendor contacts, and payable supplier bills.',
            icon: Icons.shopping_bag_rounded,
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/vendors',
          builder: (context, state) => const VendorsListScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/vendors/new',
          builder: (context, state) {
            final initialName = state.extra as String?;
            return NewVendorScreen(initialName: initialName);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/vendors/edit',
          builder: (context, state) {
            final vendor = state.extra as Vendor?;
            return NewVendorScreen(vendorToEdit: vendor);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/purchase-orders',
          builder: (context, state) => const PurchaseOrdersListScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/purchase-orders/new',
          builder: (context, state) => const NewPurchaseOrderScreen(isEditing: false),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/purchase-orders/edit',
          builder: (context, state) {
            final order = state.extra as PurchaseOrder?;
            return NewPurchaseOrderScreen(initialOrder: order, isEditing: true);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/bills',
          builder: (context, state) => const BillsListScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/bills/new',
          builder: (context, state) => const NewBillScreen(isEditing: false),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/purchases/bills/edit',
          builder: (context, state) {
            final bill = state.extra as Bill?;
            return NewBillScreen(initialBill: bill, isEditing: true);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/payments',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Payments',
            description: 'Record customer payment receipts, bank transactions, and payout settlements.',
            icon: Icons.payments_rounded,
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/expenses/create',
          builder: (context, state) => const AddExpenseScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/expenses/add',
          builder: (context, state) => const AddExpenseScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/expenses/edit',
          builder: (context, state) {
            final expense = state.extra as ExpenseModel?;
            return AddExpenseScreen(initialExpense: expense);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/help',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Help Center',
            description: 'Access guides, user manuals, tax assistance documentation, and Prabhim One customer support ticket desk.',
            icon: Icons.help_outline_rounded,
          ),
        ),
      ],
    );
  }
}
