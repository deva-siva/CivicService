import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../models/complaint_model.dart';
import 'complaint_detail_screen.dart';

class RegisterComplaintScreen extends StatefulWidget {
  const RegisterComplaintScreen({super.key});
  @override
  State<RegisterComplaintScreen> createState() => _RegisterComplaintScreenState();
}

class _RegisterComplaintScreenState extends State<RegisterComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _otherDeptCtrl = TextEditingController();
  DepartmentModel? _selectedDept;
  bool _isOtherDept = false;
  File? _image;
  double? _latitude;
  double? _longitude;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().loadDepartments();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _otherDeptCtrl.dispose();
    super.dispose();
  }
  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission denied. Please enable in settings.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          _locationCtrl.text = [p.street, p.subLocality, p.locality, p.administrativeArea]
            .where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (_) {
        _locationCtrl.text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      _showSnack('Could not get location: ${e.toString()}');
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Take Photo'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
              if (picked != null) {
                final compressed = await ImageUtils.compressUnder1MB(File(picked.path));
                setState(() => _image = compressed);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
              if (picked != null) {
                final compressed = await ImageUtils.compressUnder1MB(File(picked.path));
                setState(() => _image = compressed);
              }
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showSuccessDialog(int id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)),
          const SizedBox(height: 16),
          const Text('Complaint Submitted!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Your complaint ID is #$id\nAI is analyzing and routing your complaint.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _reset();
              },
              child: const Text('Report Another'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ComplaintDetailScreen(complaintId: id),
                ));
              },
              child: const Text('View Status'),
            )),
          ]),
        ]),
      ),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locationCtrl.text.isEmpty) {
      _showSnack('Please capture or enter your location');
      return;
    }

    final cp = context.read<ComplaintProvider>();
    final complaint = await cp.submitComplaint(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: 'others', // We use category as 'others' and set department
      locationText: _locationCtrl.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      assignedDepartment: _isOtherDept ? null : _selectedDept?.id,
      otherDepartment: _isOtherDept ? _otherDeptCtrl.text.trim() : null,
      image: _image,
    );

    if (complaint != null && mounted) {
      _showSuccessDialog(complaint.id);
    } else if (mounted) {
      _showSnack(cp.error ?? 'Submission failed. Please try again.');
    }
  }

  void _reset() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    _otherDeptCtrl.clear();
    setState(() { 
      _selectedDept = null; 
      _isOtherDept = false;
      _image = null; 
      _latitude = null; 
      _longitude = null; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    final now = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Report an Issue',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8ECF0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Location Card
            _sectionCard(
              title: 'Complaint Location',
              icon: Icons.location_on_outlined,
              children: [
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    hintText: 'MG Road, Bangalore',
                    prefixIcon: const Icon(Icons.location_pin, color: AppColors.primary),
                    suffixIcon: _gettingLocation
                      ? const Padding(padding: EdgeInsets.all(14),
                          child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(
                          icon: const Icon(Icons.my_location, color: AppColors.primary),
                          tooltip: 'Use my location',
                          onPressed: _getLocation,
                        ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Automatic Capture  •  📍 Current Location  •  🕐 $now',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    )),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Department + Details
            _sectionCard(
              title: 'Which Department?',
              icon: Icons.business_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _isOtherDept ? 'other' : (_selectedDept?.id.toString()),
                  hint: const Text('Select Department'),
                  decoration: const InputDecoration(
                    labelText: 'Target Department',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  items: [
                    ...cp.departments.map((d) =>
                      DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                    const DropdownMenuItem(value: 'other', child: Text('Others (Please specify)')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      if (v == 'other') {
                        _isOtherDept = true;
                        _selectedDept = null;
                      } else {
                        _isOtherDept = false;
                        _selectedDept = cp.departments.firstWhere((d) => d.id.toString() == v);
                      }
                    });
                  },
                  validator: (v) => v == null ? 'Please select a department' : null,
                ),
                if (_isOtherDept) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _otherDeptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mention Department Name',
                      hintText: 'e.g. Traffic Police, Forest Dept',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please specify the department' : null,
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject / Title',
                    hintText: 'e.g. Large pothole causing traffic',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Describe the Issue',
                    hintText: 'Provide details: what is the issue, where exactly, since when...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_outlined),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Description is required';
                    if (v.trim().length < 10) return 'Description must be at least 10 characters';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Photo Upload
            _sectionCard(
              title: 'Upload Photo (Optional)',
              icon: Icons.photo_camera_outlined,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: _image != null ? 180 : 160,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: _image != null
                      ? Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!, width: double.infinity, height: 180, fit: BoxFit.cover)),
                          Positioned(top: 8, right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _image = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16)),
                            )),
                        ])
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text('Attach a photo for evidence\n(JPG/PNG only)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Choose Photo'),
                          ),
                        ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Submit
            CustomButton(
              label: 'Submit Complaint',
              icon: Icons.send_rounded,
              isLoading: cp.submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
}
