import 'package:flutter/widgets.dart';

/// True when running under a Flutter test binding (widget or integration tests).
/// Used to keep system dialogs and global error hooks out of automated runs.
bool get runningUnderTest =>
    WidgetsBinding.instance.runtimeType.toString().contains('Test');
