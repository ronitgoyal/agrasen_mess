import 'package:flutter/material.dart';

import '../models/staff_model.dart';
import '../services/staff_service.dart';
import 'add_staff_screen.dart';
import 'edit_staff_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _service = const StaffService();

  final TextEditingController _searchController = TextEditingController();

  List<StaffModel> _staff = [];
  String _searchText = '';
  bool? _activeFilter;
  bool _isLoading = true;
  String? _errorMessage;
  int? _updatingStaffId;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffModel> get _filteredStaff {
    final query = _searchText.trim().toLowerCase();

    return _staff.where((staff) {
      final matchesSearch =
          query.isEmpty ||
          staff.name.toLowerCase().contains(query) ||
          staff.email.toLowerCase().contains(query) ||
          staff.phoneNumber.toLowerCase().contains(query);

      final matchesStatus =
          _activeFilter == null || staff.isActive == _activeFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final staff = await _service.getStaff();

      

      if (!mounted) return;

      setState(() {
        _staff = staff;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openAddStaff() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AddStaffScreen()));

    if (created == true && mounted) {
      await _loadStaff();
    }
  }
  Future<void> _changeStaffStatus(StaffModel member) async {
  final newStatus = !member.isActive;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(newStatus ? 'Activate staff?' : 'Deactivate staff?'),
      content: Text(
        'Do you want to ${newStatus ? 'activate' : 'deactivate'} ${member.name}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(newStatus ? 'Activate' : 'Deactivate'),
        ),
      ],
    ),
  );

  if (!mounted || confirmed != true) return;

  setState(() => _updatingStaffId = member.id);

  try {
    await _service.updateStaffStatus(
      userId: member.id,
      isActive: newStatus,
    );

    if (!mounted) return;
    await _loadStaff();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${member.name} ${newStatus ? 'activated' : 'deactivated'}.',
        ),
      ),
    );
  } catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) setState(() => _updatingStaffId = null);
  }
}
Future<void> _editStaff(StaffModel staff) async {
  final updated = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditStaffScreen(staff: staff),
    ),
  );

  if (!mounted) return;

  if (updated == true) {
    await _loadStaff();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Staff details updated successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

  void _showStaffDetails(StaffModel staff) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 38,
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  staff.name,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _DetailRow(title: 'Email', value: staff.email),
                _DetailRow(title: 'Phone', value: staff.phoneNumber),
                _DetailRow(title: 'Role', value: staff.displayRole),
                _DetailRow(
                  title: 'Status',
                  value: staff.isActive ? 'Active' : 'Inactive',
                  color: staff.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),

SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: () {
      Navigator.of(context).pop();
      _editStaff(staff);
    },
    icon: const Icon(Icons.edit),
    label: const Text('Edit Details'),
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = _filteredStaff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Staff Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadStaff,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(staff.length),
          _buildSearch(),
          _buildFilters(),
          Expanded(child: _buildStaffList(staff)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStaff,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildSummary(int shownCount) {
    final activeCount = _staff.where((staff) => staff.isActive).length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(title: 'Total', value: _staff.length),
          _SummaryItem(title: 'Active', value: activeCount),
          _SummaryItem(title: 'Shown', value: shownCount),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search name, email or phone',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _activeFilter == null,
            onSelected: (_) {
              setState(() {
                _activeFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Active'),
            selected: _activeFilter == true,
            onSelected: (_) {
              setState(() {
                _activeFilter = true;
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Inactive'),
            selected: _activeFilter == false,
            onSelected: (_) {
              setState(() {
                _activeFilter = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(List<StaffModel> staff) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 65),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadStaff,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (staff.isEmpty) {
      return const Center(child: Text('No staff members found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: staff.length,
        itemBuilder: (context, index) {
          final member = staff[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () {
                _showStaffDetails(member);
              },
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'S',
                ),
              ),
              title: Text(
                member.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${member.email}\n'
                '${member.phoneNumber}',
              ),
             trailing: _updatingStaffId == member.id
    ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : IconButton(
        tooltip: member.isActive ? 'Deactivate staff' : 'Activate staff',
        onPressed: _updatingStaffId != null
            ? null
            : () => _changeStaffStatus(member),
        icon: Icon(
          member.isActive
              ? Icons.person_off_outlined
              : Icons.person_add_alt_1_outlined,
          color: member.isActive ? Colors.red : Colors.green,
        ),
      ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final int value;

  const _SummaryItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        Text(title),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _DetailRow({required this.title, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
