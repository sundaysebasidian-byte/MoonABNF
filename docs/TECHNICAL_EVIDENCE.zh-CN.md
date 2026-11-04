# 当前源码的证据与复现入口

当前源码与已发布的 Mooncakes 0.3.0 分开验收。左递归、Unicode scalar 和组合 prose 的源码实现说明不应被当作旧包能力；`moon.mod` 的版本号也不证明已发布新版。

## 实现与边界

- [逐条回应](REVIEW_RESPONSE_20261030.md)
- [scalar / prose 契约与示例](SCALAR_PROSE_EXTENSION_20261030.md)
- [组合 prose](COMPOSED_PROSE_20261030.md)
- [左递归算法与边界](LEFT_RECURSION_REVIEW_20261030.md)
- [公开 API 消费示例](../examples/scalar_prose/main.mbt)
- [SDK 固定来源、版本和校验和](../TOOLCHAIN.lock)

上述历史说明中的 73、83、86、90、93 组测试数对应不同开发阶段，不代表当前源码全部验收完成。121 输入扫描器由实现者编写，不称为另一个审查者的独立审查。当前检出必须重新运行下面的检查并核对证据身份；有限测试不是全部 RFC 条款认证。

## 可复现检查

先按 [README](../README.md#当前源码快速开始) 设置 `MOONABNF_SDK`，使用锁定的 `moonc 0.10.18+6c83a7f62`。以下为 POSIX 环境；未声称 Windows 原生验证。

```sh
scripts/moon-local.sh version --all
python3 scripts/acceptance.py --output /tmp/moonabnf-acceptance-new-run
python3 scripts/protocol_record_test.py --diagnostics --output /tmp/moonabnf-protocol-new-run
```

- [完整验收](../scripts/acceptance.py)：Wasm、JS、native 的 check / build / test，Wasm GC 测试，格式、示例、CLI、正则 oracle 差分、源码包下游消费和运行器回归。不要把 Wasm GC 测试写成独立执行了该后端的所有 check / build 阶段。
- [源码绑定协议消费者](../scripts/protocol_record_test.py)：实际打包、源码逐文件哈希绑定、隔离消费与 JSON 适配器正反例。`--diagnostics` 仅针对当前源码扩展；不是 Mooncakes registry 安装。
- 运行器保存原始 stdout / stderr，不将截断 UTF-8 当作日志读取失败。超时及残留任务子进程会使该阶段失败；监控或 Git 元数据失败也会保留失败状态。
- 验收前后分别记录源码 SHA-256，内容新增、移除或改变，以及源码读取失败，都会使整体状态失败并保留摘要。实际输出目录不参与源码哈希，即使自定义路径位于源码内。前后快照不是文件系统锁或原子快照，不能检测两次快照之间修改后又恢复的内容；仍应在无并发写入的隔离副本运行。
- acceptance 输出目录必须尚不存在。每次运行使用新路径，失败证据也保留；退出非零不代表其他已完成阶段没有证据。

## 读取结果

完整验收的 `summary.json` 包含整体状态、逐阶段退出码 / 原因、Git HEAD、本地改动状态、前后源码 SHA-256、差异 / 读取错误与未验证项；`SHA256.json` 绑定该目录中的摘要和原始日志。只有最终候选的全部适用阶段成功且文件身份吻合，才能引用为该候选的通过证据。

部分内部历史日志保存在私人交付材料，未随公开树提供，不能引用不存在的仓库路径；本地结果也不是远程 CI。当前 CI 配置未上传日志 artifact，因此复核时应保留本地原始日志，或检查精确提交的 Actions 日志和 summary，不假设存在可下载 artifact。

仍需单独验证：新版本发布回执、精确 registry 安装、Windows 原生执行、完整第三方 ABNF 实现差分、未覆盖的应用域。源码包消费、CI 绿色或初审通过均不代替这些结果。
