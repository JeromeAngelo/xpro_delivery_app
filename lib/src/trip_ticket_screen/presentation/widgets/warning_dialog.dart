import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/core/enums/mismatched_personnel_reason_code.dart';

class PersonnelWarningDialog extends StatefulWidget {
  final String tripId;
  final String message;

  const PersonnelWarningDialog({
    super.key,
    required this.tripId,
    required this.message,
  });

  @override
  State<PersonnelWarningDialog> createState() => _PersonnelWarningDialogState();
}

class _PersonnelWarningDialogState extends State<PersonnelWarningDialog> {
  MismatchedPersonnelReasonCode? selectedReason;

  // Convert enum to user-friendly text
  String _getReasonDisplayText(MismatchedPersonnelReasonCode reason) {
    switch (reason) {
      case MismatchedPersonnelReasonCode.absent:
        return 'Team Leader Absent';
      case MismatchedPersonnelReasonCode.late_:
        return 'Team Leader Late';
      case MismatchedPersonnelReasonCode.leave:
        return 'Team Leader Leave';
      case MismatchedPersonnelReasonCode.managementApproved:
        return 'Approved by Management';
      case MismatchedPersonnelReasonCode.other:
        return 'Other';
      case MismatchedPersonnelReasonCode.none:
        return 'None';
    }
  }

  // Convert enum to string for database storage
  String _getReasonCode(MismatchedPersonnelReasonCode reason) {
    switch (reason) {
      case MismatchedPersonnelReasonCode.absent:
        return 'absent';
      case MismatchedPersonnelReasonCode.late_:
        return 'late_';
      case MismatchedPersonnelReasonCode.leave:
        return 'leave';
      case MismatchedPersonnelReasonCode.managementApproved:
        return 'managementApproved';
      case MismatchedPersonnelReasonCode.other:
        return 'other';
      case MismatchedPersonnelReasonCode.none:
        return 'none';
    }
  }

  // Handle reason selection and trigger BLoC event
  void _onReasonSelected(MismatchedPersonnelReasonCode? reason) {
    if (reason != null) {
      setState(() {
        selectedReason = reason;
      });

      final reasonCode = _getReasonCode(reason);
      final reasonText = _getReasonDisplayText(reason);
      
      debugPrint('📋 User selected mismatch reason: $reasonText ($reasonCode)');
      AppDebugLogger.instance.logInfo('📋 User selected personnel mismatch reason: $reasonText');
      AppDebugLogger.instance.logInfo('   🎯 Trip ID: ${widget.tripId}');
      AppDebugLogger.instance.logInfo('   📋 Reason Code: $reasonCode');

      // Automatically trigger the BLoC event to record the reason
      context.read<TripBloc>().add(SetMismatchedReasonEvent(
        tripId: widget.tripId,
        reasonCode: reasonCode,
      ));
    }
  }

  // Create user-friendly message from technical error
  Map<String, String> _parseErrorMessage(String technicalMessage) {
    AppDebugLogger.instance.logWarning('🔍 Parsing technical error message for user-friendly display');
    AppDebugLogger.instance.logWarning('📋 Technical message: $technicalMessage');

    // Extract useful information from technical message
    final userFriendlyTitle = 'Trip Assignment Issue';
    String userFriendlyMessage;
    String suggestionMessage;

    if (technicalMessage.contains('not assigned as personnel')) {
      // Personnel assignment issue
      userFriendlyMessage = 'You are not currently assigned to this delivery trip.';
      suggestionMessage = 'Please check with your supervisor or dispatch team to verify your trip assignment.';
    } else if (technicalMessage.contains('none match your user ID')) {
      // User ID mismatch issue  
      userFriendlyMessage = 'Your account is not linked to this trip\'s delivery team.';
      suggestionMessage = 'Contact your supervisor to ensure you\'re properly assigned to this delivery route.';
    } else if (technicalMessage.contains('No personnel assigned')) {
      // No personnel assigned to trip
      userFriendlyMessage = 'This trip has no delivery personnel assigned yet.';
      suggestionMessage = 'Please wait for trip assignment or contact dispatch for assistance.';
    } else {
      // Generic authorization error
      userFriendlyMessage = 'There seems to be an issue with your trip authorization.';
      suggestionMessage = 'Please contact your supervisor or try again later.';
    }

    AppDebugLogger.instance.logInfo('✅ User-friendly message created');
    AppDebugLogger.instance.logInfo('📋 Title: $userFriendlyTitle');
    AppDebugLogger.instance.logInfo('📋 Message: $userFriendlyMessage');
    AppDebugLogger.instance.logInfo('📋 Suggestion: $suggestionMessage');

    return {
      'title': userFriendlyTitle,
      'message': userFriendlyMessage,
      'suggestion': suggestionMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Parse the technical error into user-friendly message
    final parsedMessage = _parseErrorMessage(widget.message);
    
    // Log the technical error for debugging
    AppDebugLogger.instance.logError('🚨 Personnel authorization failed for trip: ${widget.tripId}');
    AppDebugLogger.instance.logError('📋 Technical error details: ${widget.message}');
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 48,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(
        parsedMessage['title']!,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User-friendly error message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'What happened?',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      parsedMessage['message']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              
              
              // Warning about proceeding with reason selection
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Proceed at your own risk',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please select a reason before proceeding:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Reason selection dropdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MismatchedPersonnelReasonCode>(
                          value: selectedReason,
                          hint: Text(
                            'Select reason for override...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          isExpanded: true,
                          items: MismatchedPersonnelReasonCode.values.map((reason) {
                            return DropdownMenuItem<MismatchedPersonnelReasonCode>(
                              value: reason,
                              child: Text(
                                _getReasonDisplayText(reason),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onReasonSelected,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Continuing without authorization may violate policies.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            debugPrint('🚫 User cancelled trip acceptance - returning to homepage');
            AppDebugLogger.instance.logWarning('🚫 User cancelled unauthorized trip acceptance');
            AppDebugLogger.instance.logInfo('📋 Trip ID: ${widget.tripId}');
            AppDebugLogger.instance.logInfo('📋 User decision: Cancelled (recommended)');
            Navigator.of(context).pop();
            context.go('/homepage'); // Navigate back to homepage
          },
          child: Text(
            'Cancel & Go Back',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: selectedReason != null ? () {
            final reasonText = _getReasonDisplayText(selectedReason!);
            debugPrint('⚠️ User chose to continue accepting trip despite authorization warning');
            debugPrint('   📋 Selected reason: $reasonText');
            AppDebugLogger.instance.logWarning('⚠️ User proceeded with unauthorized trip acceptance');
            AppDebugLogger.instance.logWarning('📋 Trip ID: ${widget.tripId}');
            AppDebugLogger.instance.logWarning('📋 User decision: Continue anyway (override)');
            AppDebugLogger.instance.logWarning('📋 Selected reason: $reasonText');
            AppDebugLogger.instance.logWarning('📋 Original error: ${widget.message}');
            AppDebugLogger.instance.logError('🚨 POLICY VIOLATION: Unauthorized trip acceptance override by user');
            Navigator.of(context).pop();

            // Continue with trip acceptance
            context.read<TripBloc>().add(AcceptTripEvent(widget.tripId));

            // Start comprehensive distance tracking (all movement types)
            context.read<TripBloc>().add(
              StartLocationTrackingEvent(
                tripId: widget.tripId,
                updateInterval: const Duration(minutes: 5), // Time-based: every 5 minutes
                distanceFilter: 5.0, // Distance-based: every 5 meters of movement
              ),
            );
          } : null, // Disable button if no reason selected
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedReason != null 
              ? Theme.of(context).colorScheme.error 
              : Colors.grey,
            foregroundColor: selectedReason != null 
              ? Theme.of(context).colorScheme.onError 
              : Colors.white,
          ),
          child: Text(
            selectedReason != null 
              ? 'Override & Continue' 
              : 'Select Reason First',
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );
  }
}
