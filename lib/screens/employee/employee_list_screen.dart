import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:app_absen/models/user_model.dart';
import 'package:app_absen/models/position_model.dart';
import 'package:app_absen/providers/employee_provider.dart';
import 'package:app_absen/providers/auth_provider.dart';
import 'package:app_absen/config/constants.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Role? _filterRole;
  bool? _filterActive;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    _isAdmin = auth.currentUser?.role == Role.admin;
    context.read<EmployeeProvider>().loadAllEmployees();
  }

  List<UserModel> _filterEmployees(List<UserModel> employees) {
    var result = employees.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        return e.namaLengkap.toLowerCase().contains(q) ||
            e.nip.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q);
      }).toList();
    }

    if (_filterRole != null) {
      result = result.where((e) => e.role == _filterRole).toList();
    }

    if (_filterActive != null) {
      result = result.where((e) => e.isActive == _filterActive).toList();
    }

    result.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.namaLengkap.compareTo(b.namaLengkap);
    });

    return result;
  }

  Future<void> _confirmDeactivate(UserModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(employee.isActive ? 'Nonaktifkan Karyawan' : 'Aktifkan Karyawan'),
        content: Text(
          employee.isActive
              ? 'Apakah Anda yakin ingin menonaktifkan ${employee.namaLengkap}?'
              : 'Apakah Anda yakin ingin mengaktifkan kembali ${employee.namaLengkap}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: employee.isActive ? Colors.red : Colors.green,
            ),
            child: Text(employee.isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<EmployeeProvider>();
      await provider.toggleActive(employee.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              employee.isActive
                  ? '${employee.namaLengkap} telah dinonaktifkan'
                  : '${employee.namaLengkap} telah diaktifkan',
            ),
          ),
        );
      }
    }
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddEmployeeDialog(
        onCreated: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Karyawan berhasil ditambahkan')),
            );
          }
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Role', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: _filterRole == null,
                    onSelected: (_) => setState(() => _filterRole = null),
                  ),
                  ...Role.values.map(
                    (role) => FilterChip(
                      label: Text(role.toString().toUpperCase()),
                      selected: _filterRole == role,
                      onSelected: (_) {
                        setState(() {
                          _filterRole = _filterRole == role ? null : role;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Status', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: _filterActive == null,
                    onSelected: (_) => setState(() => _filterActive = null),
                  ),
                  FilterChip(
                    label: const Text('Aktif'),
                    selected: _filterActive == true,
                    onSelected: (_) {
                      setState(() {
                        _filterActive = _filterActive == true ? null : true;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  FilterChip(
                    label: const Text('Nonaktif'),
                    selected: _filterActive == false,
                    onSelected: (_) {
                      setState(() {
                        _filterActive = _filterActive == false ? null : false;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _filterRole = null;
                      _filterActive = null;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset Filter'),
                ),
              ),
            ],
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karyawan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.employees.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = _filterEmployees(provider.employees);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          provider.employees.isEmpty
                              ? 'Belum ada karyawan'
                              : 'Tidak ada hasil pencarian',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<EmployeeProvider>().loadAllEmployees();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final employee = filtered[index];
                      return _buildEmployeeCard(employee);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _showAddEmployeeDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari karyawan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildEmployeeCard(UserModel employee) {
    return Dismissible(
      key: Key(employee.id),
      direction: _isAdmin ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: employee.isActive ? Colors.red.shade400 : Colors.green.shade400,
        child: Icon(
          employee.isActive ? Icons.person_off : Icons.person,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async {
        if (!_isAdmin) return false;
        await _confirmDeactivate(employee);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/employee-detail',
              arguments: employee,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: employee.fotoUrl.isNotEmpty
                      ? NetworkImage(employee.fotoUrl)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: employee.fotoUrl.isEmpty
                      ? Text(
                          employee.namaLengkap.isNotEmpty
                              ? employee.namaLengkap[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              employee.namaLengkap,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildRoleBadge(employee.role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.nip,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Position ID: ${employee.positionId}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: employee.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(Role role) {
    Color color = Colors.grey;
    switch (role) {
      case Role.admin:
        color = Colors.red;
        break;
      case Role.manager:
        color = Colors.orange;
        break;
      case Role.karyawan:
        color = Colors.blue;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.toString().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _AddEmployeeDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _AddEmployeeDialog({required this.onCreated});

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();
  final _nipController = TextEditingController();
  final _noTeleponController = TextEditingController();
  final _alamatController = TextEditingController();
  Role _selectedRole = Role.karyawan;
  String _selectedPositionId = '';
  List<PositionModel> _positions = [];
  bool _isLoadingPositions = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    setState(() => _isLoadingPositions = true);
    try {
      final data = await DefaultAssetBundle.of(context)
          .loadString('assets/positions.json');
      // fallback: use hardcoded for now since service may not exist
      _positions = [
        const PositionModel(
          id: 'pos-1',
          namaJabatan: 'Staff',
          gajiPokok: 4000000,
          tunjanganTetap: 500000,
          uangMakan: 300000,
          uangTransport: 200000,
        ),
        const PositionModel(
          id: 'pos-2',
          namaJabatan: 'Senior Staff',
          gajiPokok: 6000000,
          tunjanganTetap: 700000,
          uangMakan: 400000,
          uangTransport: 300000,
        ),
        const PositionModel(
          id: 'pos-3',
          namaJabatan: 'Supervisor',
          gajiPokok: 8000000,
          tunjanganTetap: 1000000,
          uangMakan: 500000,
          uangTransport: 400000,
        ),
        const PositionModel(
          id: 'pos-4',
          namaJabatan: 'Manager',
          gajiPokok: 12000000,
          tunjanganTetap: 1500000,
          uangMakan: 700000,
          uangTransport: 500000,
        ),
      ];
      if (_selectedPositionId.isEmpty && _positions.isNotEmpty) {
        _selectedPositionId = _positions.first.id;
      }
    } catch (_) {
      _positions = [
        PositionModel(
          id: 'pos-1',
          namaJabatan: 'Staff',
          gajiPokok: 4000000,
          tunjanganTetap: 500000,
          uangMakan: 300000,
          uangTransport: 200000,
        ),
      ];
      _selectedPositionId = _positions.first.id;
    } finally {
      setState(() => _isLoadingPositions = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'nama_lengkap': _namaController.text.trim(),
      'nip': _nipController.text.trim(),
      'no_telepon': _noTeleponController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'role': _selectedRole.toString(),
      'position_id': _selectedPositionId,
    };

    final provider = context.read<EmployeeProvider>();
    final success = await provider.createEmployee(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onCreated();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan karyawan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Karyawan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'NIP wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noTeleponController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Role>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.shield),
                ),
                items: Role.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toString().toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
              ),
              const SizedBox(height: 16),
              if (_isLoadingPositions)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _selectedPositionId,
                  decoration: const InputDecoration(
                    labelText: 'Posisi / Jabatan',
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: _positions.map((pos) {
                    return DropdownMenuItem(
                      value: pos.id,
                      child: Text(pos.namaJabatan),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPositionId = v);
                  },
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _nipController.dispose();
    _noTeleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}
