import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../widgets/modern_header.dart';

class AdminNotificationComposerScreen extends StatefulWidget {
  const AdminNotificationComposerScreen({super.key});

  @override
  State<AdminNotificationComposerScreen> createState() => _AdminNotificationComposerScreenState();
}

class _AdminNotificationComposerScreenState extends State<AdminNotificationComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _nameController = TextEditingController();
  
  String _target = 'all'; // all, customers, workers
  bool _isSending = false;
  int _currentStep = 0;

  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      // In a real app, you'd call an admin endpoint or write to a 'broadcasts' collection
      // For this demo, we'll write to 'broadcast_notifications' which our Cloud Function will pick up
      await NotificationService().sendBroadcastNotification(
        title: _titleController.text,
        body: _bodyController.text,
        imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
        targetTopic: _target,
        data: {
          'name': _nameController.text,
          'type': 'broadcast',
          'sentAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification broadcast queued successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const ModernHeader(
            title: 'Compose Notification',
            subtitle: 'Broadcast to users',
            showBackButton: true,
          ),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep += 1);
                } else {
                  _sendNotification();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_currentStep == 3 ? 'Send Now' : 'Continue'),
                      ),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Notification Content', style: TextStyle(fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 0,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Notification title',
                          hint: 'Enter notification title',
                          validator: (v) => v!.isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _bodyController,
                          label: 'Notification text',
                          hint: 'Enter notification text',
                          maxLines: 3,
                          validator: (v) => v!.isEmpty ? 'Text is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _imageUrlController,
                          label: 'Notification image (optional)',
                          hint: 'https://example.com/image.png',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Notification name (optional)',
                          hint: 'Internal campaign name',
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Target Selection', style: TextStyle(fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 1,
                  content: Column(
                    children: [
                      _buildTargetOption('All Users', 'all', Icons.groups_rounded),
                      _buildTargetOption('Customers Only', 'customers', Icons.person_rounded),
                      _buildTargetOption('Workers Only', 'workers', Icons.engineering_rounded),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Scheduling', style: TextStyle(fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 2,
                  content: const ListTile(
                    leading: Icon(Icons.send_rounded, color: Colors.blue),
                    title: Text('Send Now'),
                    subtitle: Text('Notification will be sent immediately upon confirmation'),
                  ),
                ),
                Step(
                  title: const Text('Review & Device Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 3,
                  content: Column(
                    children: [
                      _buildPreviewCard(),
                      if (_isSending)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetOption(String title, String value, IconData icon) {
    final isSelected = _target == value;
    return GestureDetector(
      onTap: () => setState(() => _target = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2463EB).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2463EB) : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2463EB) : Colors.grey),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2463EB) : Colors.black87)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF2463EB)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.android, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text('Android Preview', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.isEmpty ? 'Notification Title' : _titleController.text,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _bodyController.text.isEmpty ? 'Notification Text' : _bodyController.text,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
