import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint_model.dart';
import '../../widgets/common/custom_button.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({super.key});
  @override
  State<ManageDepartmentsScreen> createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      context.read<ComplaintProvider>().loadDepartments());
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Manage Departments', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showDeptSheet(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ComplaintProvider>().loadDepartments(),
        child: cp.loading
          ? const Center(child: CircularProgressIndicator())
          : cp.departments.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.business_outlined, size: 64, color: AppColors.primary.withOpacity(0.2)),
                ),
                const SizedBox(height: 20),
                Text('No Departments Found', 
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('Add your first department to get started', 
                  style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showDeptSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add), 
                  label: Text('Add Department', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: cp.departments.length,
                itemBuilder: (_, i) => _DeptCard(
                  dept: cp.departments[i],
                  onEdit: () => _showDeptSheet(context, dept: cp.departments[i]),
                  onToggle: () => _toggleDept(context, cp.departments[i]),
                ),
              ),
      ),
    );
  }

  void _toggleDept(BuildContext context, DepartmentModel dept) async {
    await context.read<ComplaintProvider>().updateDepartment(
      dept.id, {'is_active': !dept.isActive});
  }

  void _showDeptSheet(BuildContext context, {DepartmentModel? dept}) {
    final nameCtrl = TextEditingController(text: dept?.name ?? '');
    final descCtrl = TextEditingController(text: dept?.description ?? '');
    final respCtrl = TextEditingController(text: dept?.responsibilities ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) =>
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 24, right: 24, top: 12,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(dept == null ? 'New Department' : 'Edit Department',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Define department details and areas of responsibility.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),
            
            _textField(nameCtrl, 'Department Name', Icons.business_outlined, required: true),
            const SizedBox(height: 20),
            _textField(descCtrl, 'Description', Icons.description_outlined, maxLines: 2),
            const SizedBox(height: 20),
            _textField(respCtrl, 'Responsibilities', Icons.assignment_outlined, 
              hint: 'e.g. Roads, Potholes, Street Lights', maxLines: 2),
            
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: CustomButton(
              label: dept == null ? 'Create Department' : 'Save Changes',
              isLoading: saving,
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                setModal(() => saving = true);
                final cp = context.read<ComplaintProvider>();
                bool ok;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'responsibilities': respCtrl.text.trim(),
                };
                if (dept == null) {
                  ok = await cp.createDepartment(data);
                } else {
                  ok = await cp.updateDepartment(dept.id, data);
                }
                setModal(() => saving = false);
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon, 
      {bool required = false, String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label + (required ? ' *' : ''), 
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}

class _DeptCard extends StatelessWidget {
  final DepartmentModel dept;
  final VoidCallback onEdit, onToggle;
  const _DeptCard({required this.dept, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.business_rounded, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dept.name, 
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _badge('${dept.activeComplaintsCount} Active', color),
                                const SizedBox(width: 8),
                                _badge(dept.isActive ? 'Live' : 'Hidden', 
                                  dept.isActive ? AppColors.success : AppColors.textHint),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: dept.isActive, 
                        onChanged: (_) => onToggle(),
                        activeColor: AppColors.success,
                      ),
                    ],
                  ),
                  if (dept.responsibilities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text('RESPONSIBILITIES', 
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textHint, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(dept.responsibilities, 
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
