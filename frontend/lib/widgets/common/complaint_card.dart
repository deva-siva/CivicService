import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/complaint_model.dart';
import 'custom_button.dart';

class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onTap;
  final bool showUser;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
    this.showUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(complaint.category);
    final icon = AppTheme.getCategoryIcon(complaint.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${complaint.id} • ${_categoryLabel(complaint.category)}',
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          complaint.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: complaint.status),
                      const SizedBox(height: 4),
                      PriorityBadge(priority: complaint.priority),
                    ],
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showUser && complaint.submittedByName != null)
                    _infoRow(Icons.person_outline, complaint.submittedByName!),
                  _infoRow(Icons.location_on_outlined, complaint.locationText.isEmpty
                    ? 'Location not specified' : complaint.locationText),
                  _infoRow(Icons.access_time,
                    DateFormat('MMM dd, yyyy hh:mm a').format(complaint.createdAt.toLocal())),
                  if (complaint.departmentName != null)
                    _infoRow(Icons.business_outlined, complaint.departmentName!),
                  if (complaint.isEscalated)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 14),
                          SizedBox(width: 4),
                          Text('ESCALATED', style: TextStyle(color: AppColors.error,
                            fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  if (complaint.isDuplicate)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, color: AppColors.warning, size: 14),
                          SizedBox(width: 4),
                          Text('Possible Duplicate', style: TextStyle(color: AppColors.warning,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Expanded(child: Text(text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  String _categoryLabel(String cat) {
    const map = {
      'road_pothole': 'Road / Pothole', 'water_leakage': 'Water Leakage',
      'drainage': 'Drainage', 'street_light': 'Street Light',
      'garbage_sanitation': 'Garbage / Sanitation', 'others': 'Others',
    };
    return map[cat] ?? cat;
  }
}
