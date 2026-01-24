---
trigger: always_on
description: Frontend best practices that are often overlooked
---

# Frontend Best Practices (Overlooked)

> **Note**: This document does NOT cover common best practices like "use meaningful variable names", "avoid magic numbers", "write unit tests", etc. Those are expected knowledge. This file specifically records patterns that have been missed or forgotten in past development. AI agents should proactively think about best practices themselves.

## Environment & Configuration

- **Never hardcode URLs**: Use `--dart-define` or environment config. Create `AppConfig` class with `String.fromEnvironment('API_BASE_URL', defaultValue: '...')`.
- **Single Dio instance**: Create once in `bootstrap.dart` with all interceptors (token, logger). Inject via `get_it` or `Provider`. Never `new Dio()` in pages.

## State Management (BLoC)

- **Use sealed classes for State**: Distinguish `LoadSuccess` vs `UpdateSuccess` vs `DeleteSuccess`. Don't use a single success state with flags—it's error-prone and hard to extend.
- **Listener vs Builder separation**: `BlocListener` for side effects (SnackBar, navigation). `BlocBuilder` for UI rendering. Use `listenWhen`/`buildWhen` to avoid unnecessary triggers.
- **Never show success messages on initial load**: Differentiate "data loaded" from "user action succeeded" by using distinct state classes.

## Error Handling

- **Map backend error codes to localized strings**: Don't display raw API error messages. Create an error code → l10n key mapping. Show user-friendly messages.