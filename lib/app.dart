import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/attendance/selfie_screen.dart';
import 'screens/attendance/history_screen.dart';
import 'screens/employee/employee_list_screen.dart';
import 'screens/employee/employee_detail_screen.dart';
import 'screens/shift/shift_screen.dart';
import 'screens/leave/leave_request_screen.dart';
import 'screens/leave/leave_approval_screen.dart';
import 'screens/overtime/overtime_screen.dart';
import 'screens/payroll/payroll_screen.dart';
import 'screens/payroll/payroll_detail_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/profile/profile_screen.dart';

class AppAbsenApp extends StatelessWidget {
  const AppAbsenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.login,
      routes: _buildRoutes(),
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const _NotFoundScreen(),
        );
      },
    );
  }

  String _getInitialRoute(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return auth.isLoggedIn ? AppRoutes.home : AppRoutes.login;
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.login: (_) => const LoginScreen(),
      AppRoutes.home: (_) => const HomeScreen(),
      AppRoutes.attendance: (_) => const AttendanceScreen(),
      AppRoutes.selfie: (_) => const SelfieScreen(),
      AppRoutes.history: (_) => const HistoryScreen(),
      AppRoutes.employees: (_) => const EmployeeListScreen(),
      AppRoutes.employeeDetail: (_) => const EmployeeDetailScreen(),
      AppRoutes.shifts: (_) => const ShiftScreen(),
      AppRoutes.leaveRequest: (_) => const LeaveRequestScreen(),
      AppRoutes.leaveApproval: (_) => const LeaveApprovalScreen(),
      AppRoutes.overtime: (_) => const OvertimeScreen(),
      AppRoutes.payroll: (_) => const PayrollScreen(),
      AppRoutes.payrollDetail: (_) => const PayrollDetailScreen(),
      AppRoutes.reports: (_) => const ReportScreen(),
      AppRoutes.profile: (_) => const ProfileScreen(),
    };
  }
}

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String selfie = '/selfie';
  static const String history = '/history';
  static const String employees = '/employees';
  static const String employeeDetail = '/employee-detail';
  static const String shifts = '/shifts';
  static const String leaveRequest = '/leave-request';
  static const String leaveApproval = '/leave-approval';
  static const String overtime = '/overtime';
  static const String payroll = '/payroll';
  static const String payrollDetail = '/payroll-detail';
  static const String reports = '/reports';
  static const String profile = '/profile';
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Halaman tidak ditemukan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
