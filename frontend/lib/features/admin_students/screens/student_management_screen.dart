import 'package:flutter/material.dart';

import '../models/admin_student_model.dart';
import '../services/admin_student_service.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final AdminStudentService _service = const AdminStudentService();

  final TextEditingController _searchController = TextEditingController();

  List<AdminStudentModel> _students = [];

  bool _isLoading = true;
  bool? _activeFilter;
  String _searchText = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminStudentModel> get _filteredStudents {
    final query = _searchText.trim().toLowerCase();

    return _students.where((student) {
      final matchesSearch =
          query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query) ||
          student.roomNumber.toLowerCase().contains(query);

      final matchesStatus =
          _activeFilter == null || student.isActive == _activeFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _service.getStudents();

      if (!mounted) return;

      setState(() {
        _students = students;
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

  Future<void> _changeStudentStatus(AdminStudentModel student) async {
    final newStatus = !student.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newStatus ? 'Activate student?' : 'Deactivate student?'),
        content: Text(
          'Do you want to ${newStatus ? 'activate' : 'deactivate'} ${student.name}?',
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

    try {
      await _service.updateStudentStatus(
        studentId: student.id,
        isActive: newStatus,
      );

      if (!mounted) return;
      await _loadStudents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${student.name} ${newStatus ? 'activated' : 'deactivated'}.',
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
    }
  }

  Future<void> _editStudent(AdminStudentModel student) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditStudentScreen(student: student)),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadStudents();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student details updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showStudentDetails(AdminStudentModel student) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 38,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  student.name,
                  style: Theme.of(sheetContext).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _DetailRow(title: 'Email', value: student.email),

                _DetailRow(title: 'Room', value: student.roomNumber),
                _DetailRow(title: 'Phone', value: student.phoneNumber),
                _DetailRow(
                  title: 'Status',
                  value: student.isActive ? 'Active' : 'Inactive',
                  valueColor: student.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _editStudent(student);
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
    final students = _filteredStudents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(students.length),
          _buildSearch(),
          _buildFilters(),
          Expanded(child: _buildStudentList(students)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );

          if (created == true && mounted) {
            await _loadStudents();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildSummary(int shownStudents) {
    final activeStudents = _students
        .where((student) => student.isActive)
        .length;

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
          _SummaryItem(label: 'Total', value: _students.length),
          _SummaryItem(label: 'Active', value: activeStudents),
          _SummaryItem(label: 'Shown', value: shownStudents),
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
          hintText: 'Search name, email or room',
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildStudentList(List<AdminStudentModel> students) {
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
                onPressed: _loadStudents,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return const Center(child: Text('No students found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () {
                _showStudentDetails(student);
              },
              leading: CircleAvatar(
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                ),
              ),
              title: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${student.email}\n'
                'Room: ${student.roomNumber}',
              ),
              trailing: IconButton(
                tooltip: student.isActive
                    ? 'Deactivate student'
                    : 'Activate student',
                onPressed: () => _changeStudentStatus(student),
                icon: Icon(
                  student.isActive
                      ? Icons.person_off_outlined
                      : Icons.person_add_alt_1_outlined,
                  color: student.isActive ? Colors.red : Colors.green,
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
  final String label;
  final int value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }
}
