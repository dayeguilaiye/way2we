"""校验 OpenAPI、项目共同约定与静态交换示例。"""
from pathlib import Path
import json
import re

import yaml
from jsonschema import Draft202012Validator, FormatChecker
from openapi_spec_validator import validate_spec


ROOT = Path(__file__).resolve().parents[1]
spec = yaml.safe_load((ROOT / "api/openapi.yaml").read_text())
validate_spec(spec)


def resolve(value):
    if isinstance(value, list):
        return [resolve(item) for item in value]
    if not isinstance(value, dict):
        return value
    if "$ref" in value:
        reference = value["$ref"]
        assert reference.startswith("#/"), reference
        target = spec
        for part in reference[2:].split("/"):
            target = target[part.replace("~1", "/").replace("~0", "~")]
        return {**resolve(target), **resolve({k: v for k, v in value.items() if k != "$ref"})}
    return {key: resolve(item) for key, item in value.items()}


def validator(schema):
    return Draft202012Validator(resolve(schema), format_checker=FormatChecker())


operations = {}
public_or_readonly_mutations = {
    "requestEmailCode", "createSession", "deleteCurrentSession", "previewInvitation"
}
for path, methods in spec["paths"].items():
    for method, operation in methods.items():
        operation_id = operation["operationId"]
        assert operation_id not in operations, operation_id
        operations[operation_id] = operation
        assert operation.get("x-access-rule"), operation_id
        parameters = [resolve(p) for p in operation.get("parameters", [])]
        assert set(re.findall(r"{([^}]+)}", path)) == {
            p["name"] for p in parameters if p["in"] == "path"
        }, path
        if method in {"post", "put", "patch", "delete"} and operation_id not in public_or_readonly_mutations:
            assert any(p["name"] == "Idempotency-Key" and p["required"] for p in parameters), operation_id
        for status, response in operation["responses"].items():
            response = resolve(response)
            assert "X-Request-ID" in response["headers"], (operation_id, status)
            if status == "429":
                assert "Retry-After" in response["headers"], operation_id
            for media in response.get("content", {}).values():
                if "example" in media:
                    validator(media["schema"]).validate(media["example"])

fixtures = json.loads((ROOT / "api/examples/core-flow.json").read_text())
for exchange in fixtures["exchanges"]:
    operation = operations[exchange["operation_id"]]
    if "request" in exchange:
        validator(operation["requestBody"]["content"]["application/json"]["schema"]).validate(exchange["request"])
    response = resolve(operation["responses"][str(exchange["response_status"])])
    validator(response["content"]["application/json"]["schema"]).validate(exchange["response"])
    if operation.get("x-idempotency") == "required":
        validator(spec["components"]["parameters"]["IdempotencyKey"]["schema"]).validate(exchange["idempotency_key"])
    if exchange["operation_id"] == "getOperation":
        result = exchange["response"]
        original = resolve(operations[result["operation_id"]]["responses"][str(result["original_http_status"])])
        validator(original["content"]["application/json"]["schema"]).validate(result["result"])

for invalid in fixtures["invalid_requests"]:
    operation = operations[invalid["operation_id"]]
    schema = operation["requestBody"]["content"]["application/json"]["schema"]
    assert not validator(schema).is_valid(invalid["request"]), invalid["reason"]

print(f"OK: {len(operations)} operations, {len(fixtures['exchanges'])} exchanges, "
      f"{len(fixtures['invalid_requests'])} invalid request cases. Static contract validation only.")
