import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../shared/services/client_service.dart';
import '../shared/services/product_service.dart';
import '../shared/services/invoice_service.dart';
import '../shared/services/company_service.dart';
import '../features/clients/bloc/client_bloc.dart';
import '../features/products/bloc/product_bloc.dart';
import '../features/invoices/bloc/invoice_bloc.dart';
import 'routes/app_routes.dart';

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider(create: (context) => ClientService()),
            RepositoryProvider(create: (context) => ProductService()),
            RepositoryProvider(create: (context) => InvoiceService()),
            RepositoryProvider(create: (context) => CompanyService()),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => ClientBloc(
                  context.read<ClientService>(),
                ),
              ),
              BlocProvider(
                create: (context) => ProductBloc(
                  context.read<ProductService>(),
                ),
              ),
              BlocProvider(
                create: (context) => InvoiceBloc(
                  context.read<InvoiceService>(),
                ),
              ),
            ],
            child: MaterialApp.router(
              title: 'Invoice App',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                primaryColor: const Color(0xFF1976D2),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1976D2),
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
                cardTheme: const CardThemeData(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              routerConfig: AppRoutes.router,
            ),
          ),
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _getSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/invoices':
      case '/':
        return 0;
      case '/clients':
        return 1;
      case '/products':
        return 2;
      case '/settings':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/invoices');
              break;
            case 1:
              context.go('/clients');
              break;
            case 2:
              context.go('/products');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        backgroundColor: Colors.white,
        elevation: 8,
        height: 80,
        indicatorColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}