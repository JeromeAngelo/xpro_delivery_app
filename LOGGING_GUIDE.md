# App Debug Logging System

## Overview
A comprehensive logging system that provides VS Code-like debug console functionality for the entire app. Track authentication, navigation, data loading, API calls, BLoC events, and errors in real-time.

## Quick Setup

### 1. Enable Debug Console in Main App
```dart
// In main.dart or your main app widget
import 'package:x_pro_delivery_app/core/common/widgets/app_with_debug_console.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ... your app configuration
    ).withDebugConsole(enabled: true); // Add this line
  }
}
```

### 2. Alternative: Manual Integration
```dart
// Wrap your MaterialApp with debug console
AppWithDebugConsole(
  showDebugConsole: true, // Set to false for production
  child: MaterialApp.router(
    // ... your app configuration
  ),
)
```

## Usage Examples

### Authentication Logging
```dart
// In auth_screen_view.dart or auth_bloc.dart
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';

// When login starts
AppDebugLogger.instance.logAuthStart(email);

// When login succeeds
AppDebugLogger.instance.logAuthSuccess(userId, userRole);

// When login fails
AppDebugLogger.instance.logAuthError(errorMessage);

// Set user context for future logs
AppDebugLogger.instance.setUserContext(userId: userId, tripId: tripId);
```

### Navigation Logging
```dart
// Log navigation events
AppDebugLogger.instance.logNavigation('/login', '/homepage', reason: 'Authentication successful');

// Log navigation errors
AppDebugLogger.instance.logNavigationError('/protected-route', 'Unauthorized access');
```

### BLoC Event & State Logging
```dart
// In any BLoC
import 'package:x_pro_delivery_app/core/common/widgets/app_with_debug_console.dart';

// Log BLoC events
AppLogger.logBlocEvent('DeliveryDataBloc', 'GetDeliveryDataByIdEvent', 
  params: {'customerId': customerId});

// Log BLoC states
AppLogger.logBlocState('DeliveryDataBloc', 'DeliveryDataLoaded', 
  data: {'itemCount': deliveryData.length});

// Log BLoC errors
AppDebugLogger.instance.logBlocError('DeliveryDataBloc', errorMessage);
```

### Data Loading Logging
```dart
// When starting data load
AppLogger.logDataLoad('InvoiceItems', 'GetInvoiceItemsByInvoiceId');

// When data load completes
AppLogger.logDataLoadComplete('InvoiceItems', itemsCount);

// When data load fails
AppDebugLogger.instance.logDataLoadError('InvoiceItems', errorMessage);
```

### API Call Logging
```dart
// Before API call
AppLogger.logApiCall('/api/deliveries', 'GET', params: {'tripId': tripId});

// After successful API call
AppLogger.logApiSuccess('/api/deliveries', 200, responseData: data);

// After API error
AppLogger.logApiError('/api/deliveries', errorMessage, statusCode: 500);
```

### Delivery Process Logging
```dart
// Status updates
AppDebugLogger.instance.logDeliveryStatusUpdate(customerId, 'Pending', 'In Transit');

// Arrival confirmation
AppDebugLogger.instance.logDeliveryArrival(customerId, 'Customer Location');

// Delivery completion
AppDebugLogger.instance.logDeliveryCompletion(customerId, customerName, totalAmount);

// Delivery errors
AppDebugLogger.instance.logDeliveryError(customerId, errorMessage);
```

### Trip Management Logging
```dart
// Trip acceptance
AppDebugLogger.instance.logTripAcceptStart(tripId, qrCode);
AppDebugLogger.instance.logTripAcceptSuccess(tripId, tripNumber);

// Trip completion
AppDebugLogger.instance.logTripEnd(tripId, deliveriesCount);

// Trip errors
AppDebugLogger.instance.logTripError(errorMessage, tripId: tripId);
```

### General Purpose Logging
```dart
// Info messages
AppDebugLogger.instance.logInfo('Operation started', details: 'Additional context');

// Success messages
AppDebugLogger.instance.logSuccess('Operation completed successfully');

// Warnings
AppDebugLogger.instance.logWarning('Potential issue detected', details: 'Details here');

// Errors
AppDebugLogger.instance.logError('Operation failed', details: errorDetails, stackTrace: stackTrace);

// Debug messages
AppDebugLogger.instance.logDebug('Debug information', details: debugData);
```

### Performance Logging
```dart
// Track operation performance
final stopwatch = Stopwatch()..start();
// ... your operation
stopwatch.stop();
AppDebugLogger.instance.logPerformance('Data Load', stopwatch.elapsed, 
  details: 'Loaded ${items.length} items');
```

### User Action Logging
```dart
// Log user interactions
AppLogger.logUserAction('Button Clicked', details: 'Confirm Order button');
AppLogger.logUserAction('Screen Swipe', details: 'Swiped to next customer');
```

## Using with State Management

### In StatefulWidget
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with WidgetLogging {
  @override
  void initState() {
    super.initState();
    logger.logInfo('Screen initialized: MyScreen');
  }

  void _handleButtonPress() {
    logger.logUserAction('Button pressed', details: 'My custom button');
  }
}
```

### In Any Class
```dart
class MyService with ClassLogging {
  void performOperation() {
    logger.logInfo('Service operation started');
    try {
      // ... operation logic
      logger.logSuccess('Service operation completed');
    } catch (e) {
      logger.logError('Service operation failed', details: e.toString());
    }
  }
}
```

## Debug Console Features

### Console Controls
- **Refresh**: Reload latest logs
- **Clear**: Clear all logs
- **Bottom**: Scroll to latest logs
- **Expand/Collapse**: Show/hide console

### Log Display
- **Color-coded by level**: Success (green), Error (red), Warning (orange), Info (blue)
- **Timestamps**: Precise timing for each log entry
- **Details**: Expandable details for complex operations
- **Real-time updates**: Logs appear immediately as they happen

### Log Levels
- 🟢 **Success**: Completed operations
- 🔴 **Error**: Failed operations, exceptions
- 🟡 **Warning**: Potential issues, deprecated usage
- 🔵 **Info**: General information, process steps
- 🟣 **Debug**: Development debugging information

## Integration Points

### High-Value Logging Locations
1. **Authentication flow**: Login, logout, token refresh
2. **Data loading**: API calls, local storage, caching
3. **Navigation**: Route changes, deep links, redirects
4. **BLoC events**: State changes, event processing
5. **User interactions**: Button clicks, form submissions
6. **Error handling**: Try-catch blocks, validation failures
7. **Performance**: Slow operations, memory usage
8. **Sync operations**: Background sync, conflict resolution

### Production Considerations
- Set `showDebugConsole: false` for production builds
- Logs are still captured and can be exported as PDF
- Minimal performance impact when console is hidden
- Full logging history maintained for troubleshooting

## Advanced Usage

### Custom Log Categories
```dart
// Create custom logging methods for specific features
extension DeliveryLogging on AppDebugLogger {
  void logCustomerSelection(String customerId, String customerName) {
    logInfo('👤 Customer selected: $customerName', details: 'ID: $customerId');
  }
  
  void logInvoiceProcessing(String invoiceId, int itemCount, double amount) {
    logInfo('📋 Processing invoice: $invoiceId', 
      details: 'Items: $itemCount, Amount: ₱${amount.toStringAsFixed(2)}');
  }
}
```

### Conditional Logging
```dart
// Only log in debug mode
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  AppDebugLogger.instance.logDebug('Debug-only information');
}
```

This system provides comprehensive debugging capabilities similar to VS Code's debug console, helping track the entire app flow and identify issues quickly.
