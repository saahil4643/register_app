# Graph Report - app  (2026-07-08)

## Corpus Check
- 80 files · ~41,085 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 616 nodes · 838 edges · 59 communities (45 shown, 14 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
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
- [[_COMMUNITY_settings_screen.dart|settings_screen.dart]]
- [[_COMMUNITY_forgot_password_screen.dart|forgot_password_screen.dart]]
- [[_COMMUNITY_signup_screen.dart|signup_screen.dart]]
- [[_COMMUNITY_login_screen.dart|login_screen.dart]]
- [[_COMMUNITY_reset_password_screen.dart|reset_password_screen.dart]]
- [[_COMMUNITY_splash_screen.dart|splash_screen.dart]]
- [[_COMMUNITY_State|State]]
- [[_COMMUNITY_navigation_shell.dart|navigation_shell.dart]]
- [[_COMMUNITY_@example|@example]]
- [[_COMMUNITY_@zbooks|@zbooks]]
- [[_COMMUNITY_String|String?]]
- [[_COMMUNITY_build|build]]
- [[_COMMUNITY_packagego_routergo_router.dart|package:go_router/go_router.dart]]
- [[_COMMUNITY_packageflutter_animateflutter_animate.dart|package:flutter_animate/flutter_animate.dart]]
- [[_COMMUNITY_env.dart|env.dart]]
- [[_COMMUNITY_build|build]]
- [[_COMMUNITY_packagefluttermaterial.dart|package:flutter/material.dart]]

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 31 edges
2. `Win32Window` - 22 edges
3. `MessageHandler` - 12 edges
4. `What You Must Do When Invoked` - 12 edges
5. `FlutterWindow` - 10 edges
6. `Create` - 10 edges
7. `WndProc` - 10 edges
8. `/graphify` - 10 edges
9. `ThemeProvider` - 9 edges
10. `MessageHandler` - 9 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/features/authentication/screens/forgot_password_screen.dart → lib/features/authentication/providers/auth_provider.dart
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/features/authentication/screens/otp_verification_screen.dart → lib/features/authentication/providers/auth_provider.dart
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/features/authentication/screens/reset_password_screen.dart → lib/features/authentication/providers/auth_provider.dart
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h

## Import Cycles
- None detected.

## Communities (59 total, 14 thin omitted)

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
Cohesion: 0.29
Nodes (6): IconData, build, description, icon, PlaceholderScreen, title

### Community 5 - "AppDelegate"
Cohesion: 0.12
Nodes (15): ../../features/authentication/screens/forgot_password_screen.dart, ../../features/authentication/screens/login_screen.dart, ../../features/authentication/screens/otp_verification_screen.dart, ../../features/authentication/screens/reset_password_screen.dart, ../../features/authentication/screens/signup_screen.dart, ../../features/authentication/screens/splash_screen.dart, ../../features/authentication/screens/success_screen.dart, ../../features/authentication/screens/welcome_screen.dart (+7 more)

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
Cohesion: 0.08
Nodes (24): ../constants/app_colors.dart, AppTheme, amount, build, changePercentage, description, icon, iconBackgroundColor (+16 more)

### Community 34 - "custom_inputs.dart"
Cohesion: 0.09
Nodes (22): DateTime?, FormFieldValidator, build, controller, createState, firstDate, hint, items (+14 more)

### Community 35 - "custom_states.dart"
Cohesion: 0.09
Nodes (22): actionLabel, backgroundColor, borderRadius, build, color, description, draft, height (+14 more)

### Community 36 - "dashboard_screen.dart"
Cohesion: 0.10
Nodes (20): CustomPainter, build, _buildCashFlowChartCard, _buildQuickActionItem, _CashFlowPainter, DashboardScreen, inflowData, isDark (+12 more)

### Community 37 - "AuthProvider"
Cohesion: 0.22
Nodes (9): build, _handleLogin, build, build, build, Route /dashboard, Route /forgot-password, Route /login (+1 more)

### Community 38 - "custom_dialogs.dart"
Cohesion: 0.12
Nodes (15): custom_buttons.dart, build, buttonLabel, cancelLabel, ConfirmationDialog, confirmLabel, content, ErrorDialog (+7 more)

### Community 39 - "otp_verification_screen.dart"
Cohesion: 0.13
Nodes (14): dart:async, arguments, build, _controllers, createState, dispose, _focusNodes, _getOtpCode (+6 more)

### Community 40 - "custom_buttons.dart"
Cohesion: 0.14
Nodes (13): double?, build, color, CustomOutlinedButton, CustomPrimaryButton, CustomSecondaryButton, CustomTextButton, icon (+5 more)

### Community 41 - "StatelessWidget"
Cohesion: 0.17
Nodes (12): CustomDatePicker, CustomDropdown, CustomEmailField, CustomNumberField, CustomSearchField, CustomAvatar, EmptyState, ErrorState (+4 more)

### Community 42 - "settings_screen.dart"
Cohesion: 0.19
Nodes (12): ChangeNotifier, core/theme/theme_provider.dart, ../../../core/widgets/custom_cards.dart, ThemeProvider, build, _getThemeModeIcon, _getThemeModeString, SettingsScreen (+4 more)

### Community 43 - "forgot_password_screen.dart"
Cohesion: 0.24
Nodes (10): AppRouter, router, AuthProvider, _handleSubmit, _handleVerify, _handleReset, _handleSignup, Route /otp-verify (+2 more)

### Community 44 - "signup_screen.dart"
Cohesion: 0.20
Nodes (9): _agreeTerms, _businessNameController, createState, dispose, _emailController, _formKey, _nameController, _passwordController (+1 more)

### Community 45 - "login_screen.dart"
Cohesion: 0.25
Nodes (7): createState, dispose, _emailController, _formKey, _passwordController, _rememberMe, _showSocialMock

### Community 46 - "reset_password_screen.dart"
Cohesion: 0.14
Nodes (14): ../../../core/widgets/custom_dialogs.dart, ../../../core/widgets/custom_inputs.dart, FormState, build, createState, dispose, _emailController, _formKey (+6 more)

### Community 47 - "splash_screen.dart"
Cohesion: 0.33
Nodes (5): Color, build, createState, initState, ../providers/auth_provider.dart

### Community 48 - "State"
Cohesion: 0.29
Nodes (6): core/config/env.dart, core/config/router.dart, core/theme/app_theme.dart, features/authentication/providers/auth_provider.dart, init, main

### Community 49 - "navigation_shell.dart"
Cohesion: 0.29
Nodes (6): ../authentication/providers/auth_provider.dart, ../../../core/widgets/custom_states.dart, NavigationShell, _onTap, package:go_router/go_router.dart, StatefulNavigationShell

### Community 53 - "build"
Cohesion: 0.22
Nodes (8): _loadTheme, setThemeMode, _themeKey, _themeMode, package:shared_preferences/shared_preferences.dart, static const String, ThemeMode, ThemeMode get

### Community 54 - "package:go_router/go_router.dart"
Cohesion: 0.17
Nodes (16): CustomPasswordField, _CustomPasswordFieldState, ForgotPasswordScreen, _ForgotPasswordScreenState, LoginScreen, _LoginScreenState, OtpVerificationScreen, _OtpVerificationScreenState (+8 more)

### Community 55 - "package:flutter_animate/flutter_animate.dart"
Cohesion: 0.25
Nodes (7): ../../../core/constants/app_colors.dart, ../../../core/widgets/custom_buttons.dart, arguments, SuccessScreen, WelcomeScreen, Map, package:flutter_animate/flutter_animate.dart

### Community 56 - "env.dart"
Cohesion: 0.33
Nodes (5): apiBaseUrl, Env, init, package:flutter/services.dart, static String

### Community 57 - "build"
Cohesion: 0.40
Nodes (5): _navigateToNext, build, Route /help, Route /reports, Route /welcome

### Community 58 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): package:app/main.dart, package:flutter/material.dart, package:flutter_test/flutter_test.dart, main

## Knowledge Gaps
- **251 isolated node(s):** `flutter_export_environment.sh script`, `+registerWithRegistry`, `Env`, `apiBaseUrl`, `init` (+246 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `forgot_password_screen.dart` to `AppDelegate`, `Flutter`, `AuthProvider`, `otp_verification_screen.dart`, `settings_screen.dart`, `signup_screen.dart`, `login_screen.dart`, `reset_password_screen.dart`, `splash_screen.dart`, `navigation_shell.dart`, `package:go_router/go_router.dart`, `build`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Why does `FlutterWindow` connect `Win32Window` to `FlutterMacOS`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_export_environment.sh script`, `+registerWithRegistry` to the rest of the system?**
  _252 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.09401709401709402 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._