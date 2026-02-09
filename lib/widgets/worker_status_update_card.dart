import 'package:flutter/material.dart';
import '../services/booking_service.dart';

/// Widget for workers to update their travel status
/// Shows "On my way" and "Arrived" buttons with estimated time picker
class WorkerStatusUpdateCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onStatusUpdated;

  const WorkerStatusUpdateCard({
    super.key,
    required this.booking,
    this.onStatusUpdated,
  });

  @override
  State<WorkerStatusUpdateCard> createState() => _WorkerStatusUpdateCardState();
}

class _WorkerStatusUpdateCardState extends State<WorkerStatusUpdateCard> {
  final BookingService _bookingService = BookingService();
  bool _isUpdating = false;
  int _selectedMinutes = 15;

  String get _currentStatus => widget.booking['workerStatus'] as String? ?? 'pending';
  String get _requestId => widget.booking['id'] as String;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Your Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatusButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusLabel(),
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    switch (_currentStatus) {
      case 'pending':
      case 'accepted':
        return _buildOnMyWaySection();
      case 'on_the_way':
        return _buildArrivedSection();
      case 'arrived':
        return _buildStartWorkSection();
      case 'working':
        return _buildWorkingSection();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Section for "On my way" with ETA picker
  Widget _buildOnMyWaySection() {
    return Column(
      children: [
        // ETA Picker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated arrival time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTimePill(5),
                  const SizedBox(width: 8),
                  _buildTimePill(10),
                  const SizedBox(width: 8),
                  _buildTimePill(15),
                  const SizedBox(width: 8),
                  _buildTimePill(20),
                  const SizedBox(width: 8),
                  _buildTimePill(30),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // On my way button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUpdating ? null : _onMyWay,
            icon: _isUpdating 
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.directions_car_rounded, size: 20),
            label: Text(
              _isUpdating ? 'Updating...' : 'I\'m On My Way',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2463EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePill(int minutes) {
    final isSelected = _selectedMinutes == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMinutes = minutes),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2463EB) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2463EB) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            '${minutes}m',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  /// Section for "Arrived" button
  Widget _buildArrivedSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _markArrived,
        icon: _isUpdating 
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.location_on_rounded, size: 20),
        label: Text(
          _isUpdating ? 'Updating...' : 'I have reached',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Section for "Start Work" button
  Widget _buildStartWorkSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _startWork,
        icon: _isUpdating 
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(
          _isUpdating ? 'Starting...' : 'Start Work',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Section for working status with "Request Extra Time" option
  Widget _buildWorkingSection() {
    final extraTime = widget.booking['extraTimeRequest'];
    final bool hasPendingRequest = extraTime != null && extraTime['status'] == 'pending';

    return Column(
      children: [
        _buildCompletedIndicator(),
        const SizedBox(height: 16),
        
        const SizedBox(height: 12),
        
        if (hasPendingRequest)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waiting for customer to approve ${extraTime['hours']} hour(s) extra time...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUpdating ? null : _showExtraTimePicker,
              icon: const Icon(Icons.more_time_rounded, size: 20),
              label: const Text(
                'Request More Time',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2463EB),
                side: const BorderSide(color: Color(0xFF2463EB), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showExtraTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request More Time',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How many extra hours do you need to complete this job?',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildHourOption(1, _selectedExtraHours == 1, (h) => setModalState(() => _selectedExtraHours = h)),
                        const SizedBox(width: 12),
                        _buildHourOption(2, _selectedExtraHours == 2, (h) => setModalState(() => _selectedExtraHours = h)),
                        const SizedBox(width: 12),
                        _buildHourOption(3, _selectedExtraHours == 3, (h) => setModalState(() => _selectedExtraHours = h)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleRequestExtraTime(_selectedExtraHours);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2463EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Confirm Request',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  int _selectedExtraHours = 1;

  Widget _buildHourOption(int hours, bool isSelected, Function(int) onSelect) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(hours),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2463EB).withOpacity(0.1) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2463EB) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$hours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF2463EB) : const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Hour(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFF2463EB) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _handleRequestExtraTime(int hours) async {
    setState(() => _isUpdating = true);
    try {
      await _bookingService.requestExtraTime(_requestId, hours);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request for $hours extra hour(s) sent to customer'),
            backgroundColor: const Color(0xFF2463EB),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
        widget.onStatusUpdated?.call();
      }
    }
  }

  /// Completed indicator
  Widget _buildCompletedIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
          SizedBox(width: 8),
          Text(
            'Work in progress',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMyWay() async {
    setState(() => _isUpdating = true);
    await _bookingService.updateWorkerStatusOnTheWay(
      requestId: _requestId,
      estimatedMinutes: _selectedMinutes,
    );
    setState(() => _isUpdating = false);
    widget.onStatusUpdated?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer notified - ETA: $_selectedMinutes minutes'),
          backgroundColor: const Color(0xFF2463EB),
        ),
      );
    }
  }

  Future<void> _markArrived() async {
    setState(() => _isUpdating = true);
    await _bookingService.updateWorkerStatusArrived(_requestId);
    setState(() => _isUpdating = false);
    widget.onStatusUpdated?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer notified - You\'ve arrived!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _startWork() async {
    setState(() => _isUpdating = true);
    await _bookingService.updateWorkerStatusWorking(_requestId);
    setState(() => _isUpdating = false);
    widget.onStatusUpdated?.call();
  }

  Future<void> _completeJob() async {
    setState(() => _isUpdating = true);
    try {
      await _bookingService.completeJob(_requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job successfully completed!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
        widget.onStatusUpdated?.call();
      }
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'pending':
      case 'accepted':
        return const Color(0xFF64748B);
      case 'on_the_way':
        return const Color(0xFF2463EB);
      case 'arrived':
        return const Color(0xFF10B981);
      case 'working':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case 'pending':
      case 'accepted':
        return Icons.schedule_rounded;
      case 'on_the_way':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.location_on_rounded;
      case 'working':
        return Icons.build_rounded;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel() {
    switch (_currentStatus) {
      case 'pending':
      case 'accepted':
        return 'Pending';
      case 'on_the_way':
        return 'On My Way';
      case 'arrived':
        return 'Arrived';
      case 'working':
        return 'Working';
      default:
        return 'Unknown';
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case 'pending':
      case 'accepted':
        return 'Let the customer know when you\'re leaving';
      case 'on_the_way':
        return 'Mark arrived when you reach the location';
      case 'arrived':
        return 'Start work when you\'re ready';
      case 'working':
        return 'Complete the job from the job details';
      default:
        return '';
    }
  }
}
