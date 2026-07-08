class AppConstants {
  AppConstants._();

  static const String appName = 'App Absen';
  static const String appVersion = '1.0.0';

  // GPS
  static const double gpsDefaultRadiusMeters = 10.0;
  static const double gpsMaxAccuracyMeters = 50.0;
  static const int gpsTimeoutSeconds = 30;
  static const int gpsUpdateIntervalMs = 5000;

  // Working Hours
  static const String workStartTime = '08:00';
  static const String workEndTime = '16:00';
  static const int workHoursPerDay = 8;
  static const int workDaysPerWeek = 5;

  // Late Tolerance
  static const int maxLateToleranceMinutes = 15;

  // Overtime Multipliers
  static const double overtimeWeekdayMultiplier = 1.5;
  static const double overtimeWeekendMultiplier = 2.0;
  static const double overtimeHolidayMultiplier = 2.0;

  // BPJS (Indonesian Social Insurance) Percentages
  static const double bpjsKesehatanEmployee = 1.0; // 1%
  static const double bpjsKesehatanEmployer = 4.0; // 4%
  static const double bpjsKetenagakerjaanJKK = 0.24; // 0.24%
  static const double bpjsKetenagakerjaanJKM = 0.3; // 0.3%
  static const double bpjsKetenagakerjaanJHTEmployee = 2.0; // 2%
  static const double bpjsKetenagakerjaanJHTEmployer = 3.7; // 3.7%
  static const double bpjsKetenagakerjaanJPEmployee = 1.0; // 1%
  static const double bpjsKetenagakerjaanJPEmployer = 2.0; // 2%

  // PPh 21 (Income Tax)
  static const double pph21Tier1Rate = 5.0; // 5% up to Rp 60M
  static const double pph21Tier1Max = 60000000;
  static const double pph21Tier2Rate = 15.0; // 15% Rp 60M-250M
  static const double pph21Tier2Max = 250000000;
  static const double pph21Tier3Rate = 25.0; // 25% Rp 250M-500M
  static const double pph21Tier3Max = 500000000;
  static const double pph21Tier4Rate = 30.0; // 30% > Rp 500M
  static const double ptkpSingle = 54000000; // PTKP TK/0
  static const double ptkpMarried = 58500000; // PTKP K/0
  static const double ptkpPerDependent = 4500000; // Additional per dependent

  // API Endpoints
  static const String apiBaseUrl = 'https://your-project.supabase.co';
  static const String apiAuthLogin = '/auth/v1/token?grant_type=password';
  static const String apiAuthRegister = '/auth/v1/signup';
  static const String apiAuthLogout = '/auth/v1/logout';
  static const String apiAttendanceCheckIn = '/rest/v1/rpc/check_in';
  static const String apiAttendanceCheckOut = '/rest/v1/rpc/check_out';
  static const String apiAttendanceHistory = '/rest/v1/attendances';
  static const String apiAttendanceToday = '/rest/v1/rpc/get_today_attendance';
  static const String apiEmployees = '/rest/v1/employees';
  static const String apiEmployeeDetail = '/rest/v1/employees';
  static const String apiShifts = '/rest/v1/shifts';
  static const String apiShiftAssignments = '/rest/v1/shift_assignments';
  static const String apiLeaveRequests = '/rest/v1/leave_requests';
  static const String apiLeaveApproval = '/rest/v1/rpc/approve_leave';
  static const String apiLeaveBalance = '/rest/v1/rpc/get_leave_balance';
  static const String apiOvertime = '/rest/v1/overtime';
  static const String apiOvertimeApproval = '/rest/v1/rpc/approve_overtime';
  static const String apiPayroll = '/rest/v1/payroll';
  static const String apiPayrollDetail = '/rest/v1/payroll_details';
  static const String apiPayrollGenerate = '/rest/v1/rpc/generate_payroll';
  static const String apiReports = '/rest/v1/rpc/generate_report';
  static const String apiProfile = '/rest/v1/employees';
  static const String apiUploadSelfie = '/rest/v1/rpc/upload_selfie';
  static const String apiSelfie = '/rest/v1/selfies';

  // SharedPreferences Keys
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefUserId = 'user_id';
  static const String prefEmployeeId = 'employee_id';
  static const String prefUserRole = 'user_role';
  static const String prefUserName = 'user_name';
  static const String prefUserEmail = 'user_email';
  static const String prefUserAvatar = 'user_avatar';
  static const String prefAuthToken = 'auth_token';
  static const String prefRefreshToken = 'refresh_token';
  static const String prefLastSync = 'last_sync';
  static const String prefDarkMode = 'dark_mode';
  static const String prefLanguage = 'language';
  static const String prefSessionExpiry = 'session_expiry';
  static const String prefLastCheckIn = 'last_check_in';
  static const String prefLastCheckOut = 'last_check_out';
  static const String prefDeviceId = 'device_id';
  static const String prefFcmToken = 'fcm_token';

  // Date Format Patterns
  static const String dateFormatFull = 'dd MMMM yyyy';
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatMonthDay = 'dd MMM';
  static const String dateFormatDayName = 'EEEE';
  static const String dateFormatMonth = 'MMMM yyyy';
  static const String dateFormatYearMonth = 'yyyy-MM';
  static const String dateFormatISO = 'yyyy-MM-dd';
  static const String dateFormatISOFull = 'yyyy-MM-ddTHH:mm:ss';
  static const String timeFormat24 = 'HH:mm';
  static const String timeFormat12 = 'hh:mm a';
  static const String dateTimeFormatFull = 'dd MMMM yyyy HH:mm';
  static const String dateTimeFormatShort = 'dd/MM/yyyy HH:mm';
  static const String dateTimeFormatISO = 'yyyy-MM-dd HH:mm:ss';

  // Error Messages
  static const String errorNetwork = 'Tidak ada koneksi internet. Silakan coba lagi.';
  static const String errorServer = 'Terjadi kesalahan server. Silakan coba lagi.';
  static const String errorTimeout = 'Permintaan timeout. Silakan coba lagi.';
  static const String errorUnauthorized = 'Sesi anda telah berakhir. Silakan login kembali.';
  static const String errorInvalidCredentials = 'Email atau password salah.';
  static const String errorEmailAlreadyUsed = 'Email sudah terdaftar.';
  static const String errorWeakPassword = 'Password terlalu lemah. Minimal 6 karakter.';
  static const String errorLocationDenied = 'Akses lokasi ditolak. Aktifkan GPS untuk melakukan absensi.';
  static const String errorLocationService = 'Layanan lokasi tidak aktif. Silakan aktifkan GPS.';
  static const String errorCameraDenied = 'Akses kamera ditolak. Izinkan akses kamera untuk selfie.';
  static const String errorSelfieRequired = 'Selfie wajib diambil untuk absensi.';
  static const String errorOutOfRadius = 'Anda berada di luar radius absensi.';
  static const String errorAlreadyCheckedIn = 'Anda sudah melakukan check-in hari ini.';
  static const String errorAlreadyCheckedOut = 'Anda sudah melakukan check-out hari ini.';
  static const String errorNotCheckedIn = 'Anda belum melakukan check-in hari ini.';
  static const String errorLateCheckIn = 'Anda terlambat {minutes} menit.';
  static const String errorEarlyCheckOut = 'Anda check-out lebih awal {minutes} menit.';
  static const String errorNoShift = 'Tidak ada jadwal shift untuk hari ini.';
  static const String errorNoLeaveBalance = 'Sisa cuti anda tidak mencukupi.';
  static const String errorLeaveConflict = 'Sudah ada pengajuan cuti di tanggal tersebut.';
  static const String errorOvertimeExceeded = 'Lembur melebihi batas maksimal harian.';
  static const String errorPayrollGenerated = 'Payroll sudah digenerate untuk periode ini.';
  static const String errorDataNotFound = 'Data tidak ditemukan.';
  static const String errorPermissionDenied = 'Anda tidak memiliki akses ke fitur ini.';
  static const String errorInvalidQrCode = 'QR Code tidak valid.';
  static const String errorExpiredQrCode = 'QR Code sudah kadaluarsa.';
  static const String errorFaceNotRecognized = 'Wajah tidak dikenali. Silakan coba lagi.';
  static const String errorGeneral = 'Terjadi kesalahan. Silakan coba lagi.';

  // Success Messages
  static const String successLogin = 'Berhasil login.';
  static const String successCheckIn = 'Check-in berhasil.';
  static const String successCheckOut = 'Check-out berhasil.';
  static const String successLeaveSubmitted = 'Pengajuan cuti berhasil dikirim.';
  static const String successLeaveApproved = 'Cuti berhasil disetujui.';
  static const String successLeaveRejected = 'Cuti berhasil ditolak.';
  static const String successOvertimeSubmitted = 'Pengajuan lembur berhasil dikirim.';
  static const String successOvertimeApproved = 'Lembur berhasil disetujui.';
  static const String successPayrollGenerated = 'Payroll berhasil di-generate.';
  static const String successProfileUpdated = 'Profil berhasil diperbarui.';
  static const String successSelfieUploaded = 'Selfie berhasil diupload.';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 100;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int maxPhoneLength = 15;
  static const int maxAddressLength = 500;
  static const int maxNotesLength = 500;
  static const int maxOvertimeHoursPerDay = 4;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSizeMb = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Selfie
  static const double selfieImageQuality = 80;
  static const int selfieMaxWidth = 1024;
  static const int selfieMaxHeight = 1024;
}
