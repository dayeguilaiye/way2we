# 项目开发入口

- 文档采用正向叙事，直接描述当前方案。移除的内容及相关说明一并删除；需要解释取舍时简要记录原因。
- 业务术语见 [CONTEXT.md](CONTEXT.md)，规则与验收场景见 `docs/product/`，工程方案与编码规范见 [工程规范目录](docs/engineering/README.md)。
- 界面实现参考 [DESIGN.md](DESIGN.md)、`docs/design/` 和已采纳的 `prototype/`；技术取舍记录在 `docs/adr/`。
- 开发任务按可演示的用户行为推进，保持客户端、服务端、业务检查和文档同步。
- 编写 Go 或 Flutter 代码前，读取对应语言规范；跨端操作同时遵循接口、日志与检查规范。新增依赖时同步记录用途、实际版本和验证方式。
- 本地运行与检查见 [README.md](README.md)，工具版本、T00 实现边界和验证证据见 [工程基础](docs/engineering/foundation.md)。使用根目录 Makefile 入口并保持依赖锁文件同步。
