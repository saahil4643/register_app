# Graph Report - app  (2026-07-10)

## Corpus Check
- 101 files · ~67,416 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1042 nodes · 1490 edges · 79 communities (65 shown, 14 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Win32Window|Win32Window]]
- [[_COMMUNITY_my_application.cc|my_application.cc]]
- [[_COMMUNITY_What You Must Do When Invoked|What You Must Do When Invoked]]
- [[_COMMUNITY_FlutterMacOS|FlutterMacOS]]
- [[_COMMUNITY_main.dart|main.dart]]
- [[_COMMUNITY_AppDelegate|AppDelegate]]
- [[_COMMUNITY_Flutter|Flutter]]
- [[_COMMUNITY_wWinMain|wWinMain]]
- [[_COMMUNITY_manifest.json|manifest.json]]
- [[_COMMUNITY_graphify reference extra exports and benchmark|graphify reference: extra exports and benchmark]]
- [[_COMMUNITY_graphify reference query, path, explain|graphify reference: query, path, explain]]
- [[_COMMUNITY_GeneratedPluginRegistrant|GeneratedPluginRegistrant]]
- [[_COMMUNITY_handle_new_rx_page|handle_new_rx_page]]
- [[_COMMUNITY_MessageHandler|MessageHandler]]
- [[_COMMUNITY_graphify reference add a URL and watch a folder|graphify reference: add a URL and watch a folder]]
- [[_COMMUNITY_graphify reference commit hook and native CLAUDE.md integration|graphify reference: commit hook and native CLAUDE.md integration]]
- [[_COMMUNITY_graphify reference incremental update and cluster-only|graphify reference: incremental update and cluster-only]]
- [[_COMMUNITY_RegisterPlugins|RegisterPlugins]]
- [[_COMMUNITY_graphify reference GitHub clone and cross-repo merge|graphify reference: GitHub clone and cross-repo merge]]
- [[_COMMUNITY_graphify reference transcribe video and audio|graphify reference: transcribe video and audio]]
- [[_COMMUNITY_MainActivity|MainActivity]]
- [[_COMMUNITY_PackageDescription|PackageDescription]]
- [[_COMMUNITY_app|app]]
- [[_COMMUNITY_graphify|graphify.md]]
- [[_COMMUNITY_extraction-spec|extraction-spec.md]]
- [[_COMMUNITY_graphify|graphify.md]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_README|README.md]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_custom_inputs.dart|custom_inputs.dart]]
- [[_COMMUNITY_custom_states.dart|custom_states.dart]]
- [[_COMMUNITY_dashboard_screen.dart|dashboard_screen.dart]]
- [[_COMMUNITY_AuthProvider|AuthProvider]]
- [[_COMMUNITY_custom_dialogs.dart|custom_dialogs.dart]]
- [[_COMMUNITY_otp_verification_screen.dart|otp_verification_screen.dart]]
- [[_COMMUNITY_custom_buttons.dart|custom_buttons.dart]]
- [[_COMMUNITY_StatelessWidget|StatelessWidget]]
- [[_COMMUNITY_invoice.dart|invoice.dart]]
- [[_COMMUNITY_forgot_password_screen.dart|forgot_password_screen.dart]]
- [[_COMMUNITY_signup_screen.dart|signup_screen.dart]]
- [[_COMMUNITY_login_screen.dart|login_screen.dart]]
- [[_COMMUNITY_reset_password_screen.dart|reset_password_screen.dart]]
- [[_COMMUNITY_splash_screen.dart|splash_screen.dart]]
- [[_COMMUNITY_InvoiceProvider|InvoiceProvider]]
- [[_COMMUNITY_navigation_shell.dart|navigation_shell.dart]]
- [[_COMMUNITY_@example|@example]]
- [[_COMMUNITY_@zbooks|@zbooks]]
- [[_COMMUNITY_String|String?]]
- [[_COMMUNITY_settings_screen.dart|settings_screen.dart]]
- [[_COMMUNITY_packagego_routergo_router.dart|package:go_router/go_router.dart]]
- [[_COMMUNITY_packageflutter_animateflutter_animate.dart|package:flutter_animate/flutter_animate.dart]]
- [[_COMMUNITY_invoice_detail_screen.dart|invoice_detail_screen.dart]]
- [[_COMMUNITY_product_picker_screen.dart|product_picker_screen.dart]]
- [[_COMMUNITY_packagefluttermaterial.dart|package:flutter/material.dart]]
- [[_COMMUNITY_create_customer_screen.dart|create_customer_screen.dart]]
- [[_COMMUNITY_invoice_card.dart|invoice_card.dart]]
- [[_COMMUNITY_product_detail_screen.dart|product_detail_screen.dart]]
- [[_COMMUNITY_main.dart|main.dart]]
- [[_COMMUNITY_products_list_screen.dart|products_list_screen.dart]]
- [[_COMMUNITY_status_badge.dart|status_badge.dart]]
- [[_COMMUNITY_AuthProvider|AuthProvider]]
- [[_COMMUNITY_customer.dart|customer.dart]]
- [[_COMMUNITY_build|build]]
- [[_COMMUNITY_packagefluttermaterial.dart|package:flutter/material.dart]]
- [[_COMMUNITY_State|State]]
- [[_COMMUNITY_......coreconstantsapp_colors.dart|../../../core/constants/app_colors.dart]]
- [[_COMMUNITY_invoice_item_row.dart|invoice_item_row.dart]]
- [[_COMMUNITY_payment.dart|payment.dart]]
- [[_COMMUNITY_theme_provider.dart|theme_provider.dart]]
- [[_COMMUNITY_InvoiceProvider|InvoiceProvider]]
- [[_COMMUNITY_navigation_shell.dart|navigation_shell.dart]]
- [[_COMMUNITY_env.dart|env.dart]]
- [[_COMMUNITY_build|build]]
- [[_COMMUNITY_MaterialPageRoute|MaterialPageRoute]]

## God Nodes (most connected - your core abstractions)
1. `InvoiceProvider` - 44 edges
2. `AuthProvider` - 34 edges
3. `Win32Window` - 22 edges
4. `MessageHandler` - 12 edges
5. `What You Must Do When Invoked` - 12 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `/graphify` - 10 edges
10. `ThemeProvider` - 9 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/features/authentication/screens/forgot_password_screen.dart → lib/features/authentication/providers/auth_provider.dart
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/features/authentication/screens/reset_password_screen.dart → lib/features/authentication/providers/auth_provider.dart
- `build` --references--> `InvoiceProvider`  [EXTRACTED]
  lib/features/invoices/screens/invoice_preview_screen.dart → lib/features/invoices/providers/invoice_provider.dart
- `build` --references--> `InvoiceProvider`  [EXTRACTED]
  lib/features/invoices/screens/product_picker_screen.dart → lib/features/invoices/providers/invoice_provider.dart
- `build` --references--> `InvoiceProvider`  [EXTRACTED]
  lib/features/invoices/widgets/customer_picker_sheet.dart → lib/features/invoices/providers/invoice_provider.dart

## Import Cycles
- None detected.

## Communities (79 total, 14 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 1 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 2 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 3 - "FlutterMacOS"
Cohesion: 0.05
Nodes (30): Any, Cocoa, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS, FlutterPluginRegistry (+22 more)

### Community 4 - "main.dart"
Cohesion: 0.03
Nodes (65): Customer? get, ../../customers/models/payment.dart, dart:math, DateTime get, Invoice? get, addCustomer, addPayment, addProduct (+57 more)

### Community 5 - "AppDelegate"
Cohesion: 0.09
Nodes (22): ../../features/authentication/screens/forgot_password_screen.dart, ../../features/authentication/screens/login_screen.dart, ../../features/authentication/screens/otp_verification_screen.dart, ../../features/authentication/screens/reset_password_screen.dart, ../../features/authentication/screens/signup_screen.dart, ../../features/authentication/screens/splash_screen.dart, ../../features/authentication/screens/success_screen.dart, ../../features/authentication/screens/welcome_screen.dart (+14 more)

### Community 6 - "Flutter"
Cohesion: 0.09
Nodes (21): bool get, dart:convert, _authKey, _capitalize, _checkLoginStatus, clearError, _currentUserEmail, _errorMessage (+13 more)

### Community 7 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 8 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 9 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 10 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 11 - "GeneratedPluginRegistrant"
Cohesion: 0.47
Nodes (4): GeneratedPluginRegistrant, String, FlutterEngine, Keep

### Community 12 - "handle_new_rx_page"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 13 - "MessageHandler"
Cohesion: 0.07
Nodes (26): AppColors, darkBackground, darkBorder, darkPrimary, darkPrimaryContainer, darkSecondary, darkSecondaryContainer, darkSurface (+18 more)

### Community 14 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 15 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 16 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 17 - "RegisterPlugins"
Cohesion: 0.10
Nodes (20): amount, build, changePercentage, description, icon, iconBackgroundColor, iconColor, InformationCard (+12 more)

### Community 34 - "custom_inputs.dart"
Cohesion: 0.10
Nodes (20): FormFieldValidator, build, controller, createState, CustomDropdown, firstDate, hint, items (+12 more)

### Community 35 - "custom_states.dart"
Cohesion: 0.09
Nodes (22): actionLabel, backgroundColor, borderRadius, build, color, description, draft, height (+14 more)

### Community 36 - "dashboard_screen.dart"
Cohesion: 0.05
Nodes (36): CustomPainter, _buildCashFlowChartCard, _buildQuickActionItem, _CashFlowPainter, DashboardScreen, inflowData, isDark, lineColorIn (+28 more)

### Community 37 - "AuthProvider"
Cohesion: 0.06
Nodes (35): double get, copyWith, discountAmount, discountPercentage, fromJson, id, product, quantity (+27 more)

### Community 38 - "custom_dialogs.dart"
Cohesion: 0.12
Nodes (15): custom_buttons.dart, build, buttonLabel, cancelLabel, ConfirmationDialog, confirmLabel, content, ErrorDialog (+7 more)

### Community 39 - "otp_verification_screen.dart"
Cohesion: 0.13
Nodes (15): dart:async, arguments, _controllers, createState, dispose, _focusNodes, _getOtpCode, initState (+7 more)

### Community 40 - "custom_buttons.dart"
Cohesion: 0.14
Nodes (13): Color, double?, build, color, CustomOutlinedButton, CustomPrimaryButton, CustomSecondaryButton, CustomTextButton (+5 more)

### Community 41 - "StatelessWidget"
Cohesion: 0.17
Nodes (12): ListCard, CustomDatePicker, CustomEmailField, CustomNumberField, CustomSearchField, CustomAvatar, EmptyState, ErrorState (+4 more)

### Community 42 - "invoice.dart"
Cohesion: 0.10
Nodes (20): ../../customers/models/customer.dart, draft,
  sent,
  paid,
  overdue,, invoice_item.dart, cancelled, copyWith, customer, dueDate, fromJson (+12 more)

### Community 43 - "forgot_password_screen.dart"
Cohesion: 0.15
Nodes (17): AppRouter, router, AuthProvider, _handleLogin, build, _handleVerify, _handleReset, _handleSignup (+9 more)

### Community 44 - "signup_screen.dart"
Cohesion: 0.18
Nodes (11): _agreeTerms, _businessNameController, createState, dispose, _emailController, _formKey, _nameController, _passwordController (+3 more)

### Community 45 - "login_screen.dart"
Cohesion: 0.20
Nodes (10): FormState, createState, dispose, _emailController, _formKey, LoginScreen, _LoginScreenState, _passwordController (+2 more)

### Community 46 - "reset_password_screen.dart"
Cohesion: 0.09
Nodes (22): _buildCustomerSection, _buildInvoiceMetadataSection, _buildNotesTermsSection, _buildProductsSection, _buildStickyBottomBar, _buildSummaryRow, _buildSummarySection, CreateInvoiceScreen (+14 more)

### Community 47 - "splash_screen.dart"
Cohesion: 0.33
Nodes (6): build, createState, initState, SplashScreen, _SplashScreenState, ../providers/auth_provider.dart

### Community 48 - "InvoiceProvider"
Cohesion: 0.25
Nodes (7): build, _buildMetaLabelValue, _buildPreviewTotalRow, InvoicePreviewScreen, _showDummyToast, ../providers/invoice_provider.dart, ../widgets/status_badge.dart

### Community 49 - "navigation_shell.dart"
Cohesion: 0.17
Nodes (12): ../authentication/providers/auth_provider.dart, _buildFilterChips, _buildSortOption, createState, dispose, InvoicesListScreen, _InvoicesListScreenState, _isSearching (+4 more)

### Community 53 - "settings_screen.dart"
Cohesion: 0.07
Nodes (28): _amountController, backgroundColor, _buildDetailRow, _buildInfoRow, _buildInvoicesTab, _buildNotesTab, _buildPaymentsTab, _buildProductsTab (+20 more)

### Community 54 - "package:go_router/go_router.dart"
Cohesion: 0.20
Nodes (10): ../../../core/widgets/custom_dialogs.dart, build, createState, dispose, _emailController, ForgotPasswordScreen, _ForgotPasswordScreenState, _formKey (+2 more)

### Community 55 - "package:flutter_animate/flutter_animate.dart"
Cohesion: 0.12
Nodes (13): ../constants/app_colors.dart, IconData, AppTheme, build, description, icon, PlaceholderScreen, title (+5 more)

### Community 56 - "invoice_detail_screen.dart"
Cohesion: 0.15
Nodes (12): _buildActionBottomBar, _buildClientCard, _buildDetailSummaryRow, _buildHeaderCard, _buildItemsCard, _buildNotesTermsCard, _buildTimelineCard, _buildTimelineItem (+4 more)

### Community 57 - "product_picker_screen.dart"
Cohesion: 0.17
Nodes (12): build, _buildCategoryTabs, _buildStickyBottomBar, createState, dispose, _getCategoryColor, _getCategoryIcon, ProductPickerScreen (+4 more)

### Community 58 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (9): build, createState, CustomerPickerSheet, _CustomerPickerSheetState, dispose, _searchController, _searchQuery, package:provider/provider.dart (+1 more)

### Community 59 - "create_customer_screen.dart"
Cohesion: 0.09
Nodes (22): _addressController, build, _buildSectionHeader, _cityController, _companyController, createState, _creditLimitController, customer (+14 more)

### Community 60 - "invoice_card.dart"
Cohesion: 0.22
Nodes (8): Invoice, build, invoice, InvoiceCard, onTap, package:intl/intl.dart, status_badge.dart, VoidCallback

### Community 61 - "product_detail_screen.dart"
Cohesion: 0.09
Nodes (21): ../../customers/screens/customer_detail_screen.dart, ../../invoices/models/invoice.dart, _SliverAppBarDelegate, backgroundColor, _buildDetailRow, _buildOverviewTab, _buildSalesTab, _buildStatTile (+13 more)

### Community 62 - "main.dart"
Cohesion: 0.12
Nodes (19): ChangeNotifier, core/config/env.dart, core/config/router.dart, core/theme/app_theme.dart, core/theme/theme_provider.dart, ../../../core/widgets/custom_cards.dart, features/authentication/providers/auth_provider.dart, features/invoices/providers/invoice_provider.dart (+11 more)

### Community 63 - "products_list_screen.dart"
Cohesion: 0.13
Nodes (15): create_product_screen.dart, _activeFilter, _buildFilterChip, _buildSortOption, _buildStatusBadge, createState, dispose, ProductsListScreen (+7 more)

### Community 64 - "status_badge.dart"
Cohesion: 0.33
Nodes (5): InvoiceStatus, build, InvoiceStatusBadge, status, ../models/invoice.dart

### Community 65 - "AuthProvider"
Cohesion: 0.22
Nodes (9): ../../../core/widgets/custom_inputs.dart, build, _confirmPasswordController, createState, dispose, _formKey, _passwordController, ResetPasswordScreen (+1 more)

### Community 66 - "customer.dart"
Cohesion: 0.11
Nodes (17): address, company, copyWith, createdAt, creditLimit, Customer, email, fromJson (+9 more)

### Community 67 - "build"
Cohesion: 0.18
Nodes (12): _buildOverviewTab, build, build, _buildActionBottomBar, build, _showQuickCreate, Route /customers, Route /invoices (+4 more)

### Community 68 - "package:flutter/material.dart"
Cohesion: 0.14
Nodes (14): create_customer_screen.dart, customer_detail_screen.dart, _activeFilter, _buildFilterChip, _buildSortOption, createState, CustomersListScreen, _CustomersListScreenState (+6 more)

### Community 69 - "State"
Cohesion: 0.21
Nodes (15): CustomPasswordField, _CustomPasswordFieldState, CreateCustomerScreen, _CreateCustomerScreenState, CustomerDetailScreen, _CustomerDetailScreenState, _ReceivePaymentDialog, _ReceivePaymentDialogState (+7 more)

### Community 70 - "../../../core/constants/app_colors.dart"
Cohesion: 0.24
Nodes (8): ../../../core/constants/app_colors.dart, ../../../core/widgets/custom_buttons.dart, arguments, SuccessScreen, WelcomeScreen, Map, package:flutter_animate/flutter_animate.dart, package:go_router/go_router.dart

### Community 71 - "invoice_item_row.dart"
Cohesion: 0.14
Nodes (13): InvoiceItem, build, _getCategoryColor, _getCategoryIcon, InvoiceItemRow, item, onDiscountChanged, onQtyChanged (+5 more)

### Community 72 - "payment.dart"
Cohesion: 0.15
Nodes (12): DateTime, amount, copyWith, customerId, fromJson, id, invoiceId, Payment (+4 more)

### Community 73 - "theme_provider.dart"
Cohesion: 0.25
Nodes (7): _loadTheme, setThemeMode, _themeKey, _themeMode, package:shared_preferences/shared_preferences.dart, static const String, ThemeMode get

### Community 74 - "InvoiceProvider"
Cohesion: 0.25
Nodes (8): _saveCustomer, build, initState, InvoiceProvider, build, initState, _saveProduct, build

### Community 75 - "navigation_shell.dart"
Cohesion: 0.33
Nodes (5): ../../../core/widgets/custom_states.dart, ../../invoices/providers/invoice_provider.dart, NavigationShell, _onTap, StatefulNavigationShell

### Community 76 - "env.dart"
Cohesion: 0.33
Nodes (5): apiBaseUrl, Env, init, package:flutter/services.dart, static String

### Community 77 - "build"
Cohesion: 0.33
Nodes (6): build, build, build, Route /forgot-password, Route /login, Route /signup

### Community 78 - "MaterialPageRoute"
Cohesion: 0.33
Nodes (6): build, _navigateToAddCustomer, _buildBuyersTab, build, _navigateToAddProduct, MaterialPageRoute

## Knowledge Gaps
- **552 isolated node(s):** `flutter_export_environment.sh script`, `+registerWithRegistry`, `Env`, `apiBaseUrl`, `init` (+547 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `InvoiceProvider` connect `InvoiceProvider` to `build`, `package:flutter/material.dart`, `State`, `main.dart`, `dashboard_screen.dart`, `navigation_shell.dart`, `MaterialPageRoute`, `reset_password_screen.dart`, `InvoiceProvider`, `navigation_shell.dart`, `settings_screen.dart`, `invoice_detail_screen.dart`, `product_picker_screen.dart`, `package:flutter/material.dart`, `create_customer_screen.dart`, `product_detail_screen.dart`, `main.dart`, `products_list_screen.dart`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Why does `Customer` connect `customer.dart` to `invoice.dart`, `create_customer_screen.dart`, `main.dart`, `settings_screen.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `AuthProvider` connect `forgot_password_screen.dart` to `AuthProvider`, `build`, `AppDelegate`, `Flutter`, `otp_verification_screen.dart`, `navigation_shell.dart`, `signup_screen.dart`, `login_screen.dart`, `build`, `splash_screen.dart`, `navigation_shell.dart`, `package:go_router/go_router.dart`, `main.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_export_environment.sh script`, `+registerWithRegistry` to the rest of the system?**
  _553 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.09401709401709402 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._