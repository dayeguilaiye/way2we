import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

bool _licensesRegistered = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!_licensesRegistered) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'Noto Serif SC',
      ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    });
    _licensesRegistered = true;
  }
  runApp(const ProviderScope(child: Way2WeApp()));
}
