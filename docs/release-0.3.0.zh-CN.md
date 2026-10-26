# MoonABNF 0.3.0 发布回执

状态核对：2026-10-26。0.3.0 已于 2026-10-25 正式发布。

```sh
moon add sundaysebasidian-byte/moonabnf@0.3.0
```

- [Mooncakes 精确版本](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/)；[registry manifest](https://mooncakes.io/api/v0/manifest/sundaysebasidian-byte/moonabnf@0.3.0)。
- [版本 PR #7](https://github.com/sundaysebasidian-byte/MoonABNF/pull/7) 已合并。
- 测试 head：`e60205271b5dccdef67974c1dfe3e0a025f0afa8`。
- 发布合并提交：[4fc9981cce43cfa0c24874193562f252c761d20f](https://github.com/sundaysebasidian-byte/MoonABNF/commit/4fc9981cce43cfa0c24874193562f252c761d20f)。
- 官方 CLI 退出 0；manifest HTTP 200、build_status 为 success。[官方 ZIP](https://download.mooncakes.io/user/sundaysebasidian-byte/moonabnf/0.3.0.zip) 的 SHA256 与 metadata 一致，138 个发布文件与审计后的合并源码及安装文件一致：

```text
ba46dfba24eaf680adb66b76906c78abc4f01276320249947f9335e7eae2deb0
```

## 版本内容

相对 0.2.1 新增独立的 `Program::diagnose_input`、有界局部失败解释及显式 JSON 序列化，配套 CLI 与可复制的 JS 协议诊断模板。原识别/构树接受集合、预算和 API 保留。解释是最远失败分支的局部信息，不是唯一修复；成功与预算未判定不产生失败解释。新增公共入口采用 minor 版本 0.3.0。

输入树、`rule_nodes_in`、`span`、`extract` 属于公共库 API。JSON 协议适配器是需复制的集成示例，不是根包导出；原模板兼容 0.2.1，诊断扩展需要 0.3.0。见[协议案例](PROTOCOL_RECORD_CASE.zh-CN.md)及[诊断示例固定源码](https://github.com/sundaysebasidian-byte/MoonABNF/blob/4fc9981cce43cfa0c24874193562f252c761d20f/examples/diagnostics/main.mbt)。

## 已执行的验证

| 证据 | 适用提交或版本 | 结果与边界 |
| --- | --- | --- |
| [精确 head 核心 CI](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959109) | `e602052…` | 四后端验收、CLI/诊断、示例、差分与源码绑定 JS 协议步骤成功 |
| [精确 head fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959146) | `e602052…` | pinned/latest SDK 成功 |
| [合后核心 CI](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40221161751) / [fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40221161767) | `4fc9981…` | 成功，不是本次文档分支的新 CI |
| 发布后干净 registry 消费（本地发布回执） | 精确 `0.3.0`，无 workspace/path 覆盖 | 核心/输入树及诊断在 JS、Wasm、Wasm GC、native 均通过；JS 协议 JSON 黄金、退出 0/1/3/2 与诊断扩展通过 |

完整本机发布/消费者日志保留私有；上表的本地结果是发布轮记录，不冒充公开 CI 附件或本次重新运行。发布后的文档修订不改变已发布归档中的旧文档。

## 限制

左递归拒绝、按字节解析、歧义返回一个确定派生见证，`BudgetExceeded` 为未判定。规范例子和自编负例不等于生产流量；JSON 适配器只验 JS。五个独立进程的性能数据仍属于原日期的本地测量，不是 0.3.0 新基准，不推 p95 或跨实现性能领先。评审问题映射见[证据索引](REVIEW_EVIDENCE_INDEX.zh-CN.md)；没有比赛提交或获奖承诺。
