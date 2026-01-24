---
trigger: always_on
description: Backend best practices that are often overlooked
---

# Backend Best Practices (Overlooked)

> **Note**: This document does NOT cover common best practices like "validate input", "use transactions", "log errors", etc. Those are expected knowledge. This file specifically records patterns that have been missed or forgotten in past development. AI agents should proactively think about best practices themselves.

## Error Handling

- **Return structured error codes, not raw messages**: Always return a machine-readable `code` field (e.g., `ERR_NICKNAME_TOO_LONG`). Frontend maps codes to localized text.
- **Never expose stack traces in production**: Wrap internal errors with user-safe messages before returning. Log the original error internally.

## Configuration

- **Externalize all environment-specific values**: Base URLs, secrets, feature flags should come from config files or environment variables. Never inline in source code.