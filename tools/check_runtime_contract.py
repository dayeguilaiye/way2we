"""Validate actual local foundation responses against the shared error contract."""
import json
import os
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from urllib.parse import urlparse

from check_contract import spec, validator

base = os.environ.get("API_BASE_URL", "http://127.0.0.1:8080")
assert urlparse(base).hostname in {"127.0.0.1", "localhost"}, "Use the local diagnostics server"
seen = set()
for method, path, data, expected in [
    ("GET", "/health/live", None, 200),
    ("GET", "/health/ready", None, 200),
    ("POST", "/dev/validate", {"quantity": 2}, 200),
    ("POST", "/dev/validate", {"quantity": 0}, 422),
    ("GET", "/dev/missing", None, 404),
]:
    request = Request(base + path, method=method,
                      data=json.dumps(data).encode() if data is not None else None,
                      headers={"Content-Type": "application/json"})
    try:
        response = urlopen(request, timeout=5)
    except HTTPError as error:
        response = error
    with response:
        assert response.status == expected, (path, response.status)
        request_id = response.headers["X-Request-ID"]
        assert request_id and request_id not in seen
        seen.add(request_id)
        body = json.load(response)
        if expected >= 400:
            validator(spec["components"]["schemas"]["Error"]).validate(body)
            assert body["request_id"] == request_id
        elif path.startswith("/health/"):
            assert body == {"status": "ok"}
        else:
            assert body == {"quantity": 2}
print("OK: 5 real HTTP exchanges; shared error schema and fresh request IDs validated.")
