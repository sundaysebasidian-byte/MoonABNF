# 源码分支证据与复现入口

本分支是源码修订，不是新的 Mooncakes 发布包。

- [逐条回应](REVIEW_RESPONSE_20261030.md)
- [scalar/prose 契约与示例](SCALAR_PROSE_EXTENSION_20261030.md)
- [左递归算法与边界](LEFT_RECURSION_REVIEW_20261030.md)
- [公开 API 消费示例](../examples/scalar_prose/main.mbt)
- [SDK 固定来源、版本和校验和](../TOOLCHAIN.lock)
- [完整验收脚本](../scripts/acceptance.py)

新增入口实施测试为83组，另一独立代理追加3组公共API反例后四后端各86/86；四后端严格编译与示例也有本地成功回执。121输入状态扫描器由实现者编写，不能称为另一个代理的独立审查。完整原始日志、前序73组历史回执保存在私有交付包，不随本公开树发布；不能引用不存在的仓库路径，也不把本地回执称为远程CI。

可在固定工具链下执行 `moon test --target native`（以及js、wasm、wasm-gc）和 `moon run examples/scalar_prose --target native`。有限测试不等于全部标准条款认证；当前公开源码、文档与未来CI应以同一提交绑定。
