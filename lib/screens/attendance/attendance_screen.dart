import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_absen/models/attendance_model.dart';
import 'package:app_absen/models/shift_model.dart';
import 'package:app_absen/providers/attendance_provider.dart';
import 'package:app_absen/providers/shift_provider.dart';
import 'package:app_absen/providers/auth_provider.dart';
import 'package:app_absen/services/gps_service.dart';
import 'package:app_absen/config/constants.dart';
import 'package:app_absen/config/platform_helper.dart';
import 'package:app_absen/screens/attendance/selfie_screen.dart';

enum AttendanceStep { lokasi, foto, selesai }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  final GpsService _gpsService = GpsService();
  final ImagePicker _imagePicker = ImagePicker();

  AttendanceStep _currentStep = AttendanceStep.lokasi;
  bool _isWithinRadius = false;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  Position? _currentPosition;
  String _address = '';
  double _distanceFromOffice = 0;
  Uint8List? _selfieBytes;
  XFile? _selfieXFile;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStream;

  static const LatLng _officeLocation = LatLng(-6.2088, 106.8456);
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocation();
    }
  }

  Future<void> _initializeScreen() async {
    final auth = context.read<AuthProvider>();
    final attendanceProv = context.read<AttendanceProvider>();
    final shiftProv = context.read<ShiftProvider>();

    if (auth.currentUser != null) {
      await attendanceProv.loadTodayAttendance(auth.currentUser!.id);
    }
    await shiftProv.loadShifts();
    await _getCurrentLocation();
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await _gpsService.requestLocationPermission();
      if (!permission) {
        setState(() {
          _errorMessage = AppConstants.errorLocationDenied;
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await _gpsService.getCurrentLocation();
      final address = await _gpsService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _officeLocation.latitude,
        _officeLocation.longitude,
      );

      final radius = context.read<AttendanceProvider>().isWithinRadius(
            position.latitude,
            position.longitude,
          );

      setState(() {
        _currentPosition = position;
        _address = address;
        _distanceFromOffice = distance;
        _isWithinRadius = radius;
        _isLoadingLocation = false;
        _errorMessage = null;
        if (radius && _currentStep == AttendanceStep.lokasi) {
          _currentStep = AttendanceStep.foto;
        }
      });

      _updateMapMarkers();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (mounted) {
          final newRadius = context.read<AttendanceProvider>().isWithinRadius(
                pos.latitude,
                pos.longitude,
              );
          _gpsService.getAddressFromLatLng(pos.latitude, pos.longitude).then(
              (addr) {
            if (mounted) {
              setState(() {
                _currentPosition = pos;
                _address = addr;
                _distanceFromOffice = Geolocator.distanceBetween(
                  pos.latitude,
                  pos.longitude,
                  _officeLocation.latitude,
                  _officeLocation.longitude,
                );
                _isWithinRadius = newRadius;
              });
              _updateMapMarkers();
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendapatkan lokasi: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _updateMapMarkers() {
    if (_currentPosition == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('office'),
          position: _officeLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(title: 'Kantor'),
        ),
        Marker(
          markerId: const MarkerId('current'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'Lokasi Anda'),
        ),
      };

      _circles = {
        Circle(
          circleId: const CircleId('officeRadius'),
          center: _officeLocation,
          radius: 200,
          fillColor: Colors.blue.withValues(alpha: 0.15),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateToCurrentLocation();
  }

  void _animateToCurrentLocation() {
    if (_currentPosition == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16,
      ),
    );
  }

  Future<void> _takeSelfie() async {
    final result = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (_) => SelfieScreen(
          latitude: _currentPosition?.latitude ?? 0,
          longitude: _currentPosition?.longitude ?? 0,
          address: _address,
        ),
      ),
    );

    if (result != null && mounted) {
      final bytes = await result.readAsBytes();
      setState(() {
        _selfieXFile = result;
        _selfieBytes = bytes;
        _currentStep = AttendanceStep.selesai;
      });
    }
  }

  Future<void> _retakeSelfie() async {
    final picker = ImagePicker();
    final source = PlatformHelper.isWeb ? ImageSource.gallery : ImageSource.camera;
    final file = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: AppConstants.selfieMaxWidth.toDouble(),
      maxHeight: AppConstants.selfieMaxHeight.toDouble(),
      imageQuality: AppConstants.selfieImageQuality.toInt(),
    );

    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selfieXFile = file;
        _selfieBytes = bytes;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_currentPosition == null || _selfieBytes == null) return;

    final auth = context.read<AuthProvider>();
    final attendanceProv = context.read<AttendanceProvider>();
    final shiftProv = context.read<ShiftProvider>();

    if (auth.currentUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final todayAttendance = attendanceProv.todayAttendance;
      final employeeId = auth.currentUser!.id;

      if (todayAttendance == null || todayAttendance.jamKeluar != null) {
        final shift = shiftProv.getEmployeeShift(employeeId, DateTime.now());

        final result = await attendanceProv.checkIn(
          employeeId: employeeId,
          shiftId: shift?.id ?? '',
          photoBytes: _selfieBytes!,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          locationName: _address,
        );

        if (result != null && mounted) {
          setState(() {
            _currentStep = AttendanceStep.selesai;
          });
          _showSuccessDialog(true);
        }
      } else {
        final result = await attendanceProv.checkOut(
          employeeId: employeeId,
          photoBytes: _selfieBytes!,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );

        if (result != null && mounted) {
          _showSuccessDialog(false);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal melakukan absensi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(bool isCheckIn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isCheckIn
                  ? AppConstants.successCheckIn
                  : AppConstants.successCheckOut,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  ShiftModel? _getTodayShift() {
    final auth = context.read<AuthProvider>();
    final shiftProv = context.read<ShiftProvider>();
    if (auth.currentUser == null) return null;
    return shiftProv.getEmployeeShift(auth.currentUser!.id, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mendapatkan lokasi...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLocation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildMapSection(),
            _buildLocationCard(),
            _buildShiftCard(),
            const SizedBox(height: 8),
            _buildProgressSteps(),
            if (_selfieBytes != null) _buildSelfiePreview(),
            if (_errorMessage != null) _buildErrorBanner(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    if (_currentPosition == null) {
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        child: const Center(child: Text('Lokasi tidak tersedia')),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target:
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 16,
            ),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            right: 12,
            top: 12,
            child: FloatingActionButton.small(
              heroTag: 'centerLocation',
              onPressed: _animateToCurrentLocation,
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final distanceText = _distanceFromOffice < 1000
        ? '${_distanceFromOffice.toStringAsFixed(0)} m'
        : '${(_distanceFromOffice / 1000).toStringAsFixed(2)} km';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Lokasi Anda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isWithinRadius
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isWithinRadius ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isWithinRadius
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 14,
                        color:
                            _isWithinRadius ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isWithinRadius ? 'Dalam Radius' : 'Luar Radius',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isWithinRadius
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.straighten,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Jarak dari kantor: $distanceText',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.map,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _distanceFromOffice > 200 ? 1.0 : _distanceFromOffice / 200,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isWithinRadius ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard() {
    final shift = _getTodayShift();
    final todayAttendance = context.watch<AttendanceProvider>().todayAttendance;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Shift Hari Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shift != null) ...[
              Row(
                children: [
                  Text(
                    shift.namaShift,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getShiftColor(shift.tipeShift).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shift.tipeShift.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getShiftColor(shift.tipeShift),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.login, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Masuk: ${shift.jamMasuk.format(context)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.logout, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Keluar: ${shift.jamKeluar.format(context)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              if (todayAttendance != null) ...[
                const Divider(height: 20),
                _buildTodayStatus(todayAttendance),
              ],
            ] else ...[
              Text(
                AppConstants.errorNoShift,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getShiftColor(TipeShift tipe) {
    switch (tipe) {
      case TipeShift.pagi:
        return Colors.orange;
      case TipeShift.siang:
        return Colors.blue;
      case TipeShift.malam:
        return Colors.indigo;
    }
  }

  Widget _buildTodayStatus(AttendanceModel attendance) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Text(
          'Status: ${attendance.status.name}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _getStatusColor(attendance.status),
          ),
        ),
        if (attendance.jamMasuk != null) ...[
          const SizedBox(width: 12),
          Text(
            'Jam masuk: ${DateFormat('HH:mm').format(attendance.jamMasuk!)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Colors.green;
      case AttendanceStatus.telat:
        return Colors.orange;
      case AttendanceStatus.izin:
        return Colors.blue;
      case AttendanceStatus.cuti:
        return Colors.grey;
      case AttendanceStatus.alpha:
        return Colors.red;
    }
  }

  Widget _buildProgressSteps() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            _buildStep(
              number: 1,
              label: 'Lokasi',
              isActive: _currentStep == AttendanceStep.lokasi,
              isCompleted: _currentStep.index > AttendanceStep.lokasi.index,
              icon: Icons.location_on,
            ),
            _buildStepConnector(
                _currentStep.index > AttendanceStep.lokasi.index),
            _buildStep(
              number: 2,
              label: 'Foto',
              isActive: _currentStep == AttendanceStep.foto,
              isCompleted: _currentStep.index > AttendanceStep.foto.index,
              icon: Icons.camera_alt,
            ),
            _buildStepConnector(
                _currentStep.index > AttendanceStep.foto.index),
            _buildStep(
              number: 3,
              label: 'Selesai',
              isActive: _currentStep == AttendanceStep.selesai,
              isCompleted: _currentStep.index >= AttendanceStep.selesai.index &&
                  _selfieBytes != null,
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String label,
    required bool isActive,
    required bool isCompleted,
    required IconData icon,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20, key: ValueKey('check'))
                    : Icon(icon, color: Colors.white, size: 20, key: ValueKey('icon')),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive || isCompleted ? FontWeight.w600 : FontWeight.normal,
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(bool completed) {
    return Container(
      height: 2,
      width: 40,
      color: completed ? Colors.green : Colors.grey.shade300,
    );
  }

  Widget _buildSelfiePreview() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Foto Selfie',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Ambil Ulang'),
                  onPressed: _retakeSelfie,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _selfieBytes != null
                  ? Image.memory(
                      _selfieBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final attendanceProv = context.watch<AttendanceProvider>();
    final todayAttendance = attendanceProv.todayAttendance;
    final isCheckedIn = todayAttendance != null;
    final isCheckedOut = todayAttendance?.jamKeluar != null;

    String buttonText;
    IconData buttonIcon;
    bool canSubmit;

    if (isCheckedIn && isCheckedOut) {
      buttonText = 'Sudah Absen Hari Ini';
      buttonIcon = Icons.check_circle;
      canSubmit = false;
    } else if (isCheckedIn) {
      buttonText = 'ABSEN KELUAR';
      buttonIcon = Icons.logout;
      canSubmit = _isWithinRadius && _selfieBytes != null;
    } else {
      buttonText = 'ABSEN MASUK';
      buttonIcon = Icons.login;
      canSubmit = _isWithinRadius && _selfieBytes != null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selfieBytes == null && _currentStep != AttendanceStep.lokasi)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Ambil Foto Selfie'),
                  onPressed: _isWithinRadius ? _takeSelfie : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (_selfieBytes == null) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(buttonIcon),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                onPressed: canSubmit && !_isSubmitting ? _submitAttendance : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isCheckedIn
                      ? Theme.of(context).primaryColor
                      : Colors.orange,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (!_isWithinRadius && _currentPosition != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppConstants.errorOutOfRadius,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
