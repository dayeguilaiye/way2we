# 首轮接口契约

[openapi.yaml](openapi.yaml) 使用 OpenAPI 3.1，覆盖登录、空间和邀请、约定与记分、小卖部与购买、退出恢复、通知及商品图片。每个操作声明访问规则、请求、响应、错误及幂等要求。

通用语义见[API 规范](../docs/engineering/api.md)，事务与表关系见[数据模型](../docs/engineering/data-model.md)。修改契约时同步修改两端实现和受影响示例。

## 校验

在仓库根目录使用独立 Python 环境：

```sh
python3 -m venv .venv-contract
.venv-contract/bin/python -m pip install -r tools/contract-requirements.txt
.venv-contract/bin/python tools/check_contract.py
```

虚拟环境目录属于本机工具缓存。校验使用维护方的 [openapi-spec-validator](https://openapi-spec-validator.readthedocs.io/en/latest/) 和 JSON Schema 校验器，检查规范结构、本地引用、权限标注、操作唯一性、幂等请求头、请求编号以及 JSON 示例。

[完整流程示例](examples/core-flow.json) 包含 17 次请求／响应：邮箱登录、建立空间、分享邀请、加入、约定、两次记分、上架早餐、购买两份、超时重试、完成、取消、重复取消、余额不足、核对结果及撤销记分。示例另列三种应拒绝的输入。

示例中的余额是实施后的预期值，静态校验只验证字段与结构。真实权限、并发、扣分和退款在 Go 与 PostgreSQL 建成后按[检查规范](../docs/engineering/quality.md)验证。

## 服务端运行检查

启动根目录 `make dev` 后执行 `make check-runtime`，检查健康响应、开发数量校验及标准错误；真实错误响应使用主契约的 Error schema 校验。开发验证端点和启用范围见[工程基础](../docs/engineering/foundation.md#开发-http-检查)。业务端点按 T01—T07 实现。
