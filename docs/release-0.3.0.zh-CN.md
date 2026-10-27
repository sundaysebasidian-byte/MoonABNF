# MoonABNF 0.3.0

发布日期：**2026-10-25**。[Mooncakes 精确版本](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/)。

```sh
moon add sundaysebasidian-byte/moonabnf@0.3.0
```

## 本次更新

相对 0.2.1，新增 `Program::diagnose_input`、有界局部失败解释和显式 JSON 序列化，配套 CLI 与 JS 协议诊断模板。诊断使用独立预算，不改变原 `MatchReport`、识别/构树接受集合或匹配预算；`BudgetExceeded` 为未判定，不能当作 `NoMatch`。解释来自局部最远失败分支，不是唯一修复。

输入树和字段提取仍用 `parse_input`、`rule_nodes_in`、`span`、`extract`。协议 JSON 适配器是 [integration/protocol_consumer](../integration/protocol_consumer) 下可复制的 JS 示例，不是根包导出。[输入树上手](INPUT_TREE_QUICKSTART.zh-CN.md)、[协议案例](PROTOCOL_RECORD_CASE.zh-CN.md)及[公开接口](../pkg.generated.mbti)提供复现入口。

## 已执行验证

以下均为原发布轮结果，本次文档整理没有重跑这些测试。

- 测试 head `e60205271b5dccdef67974c1dfe3e0a025f0afa8`：[核心 CI](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959109)、[fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959146)通过。
- [PR #7](https://github.com/sundaysebasidian-byte/MoonABNF/pull/7) 合并为 [4fc9981](https://github.com/sundaysebasidian-byte/MoonABNF/commit/4fc9981cce43cfa0c24874193562f252c761d20f)：[合后核心](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40221161751)、[fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40221161767)通过。
- 官方 CLI 退出 0；registry metadata 为 success，ZIP checksum 一致。全新 registry 消费者无 workspace/path 覆盖：核心、输入树及诊断在 JS、Wasm、Wasm GC、native 均通过；协议 JSON 黄金、退出 0/1/3/2 与诊断扩展仅验 JS。

## 使用范围

输入与 span 按字节处理，拒绝左递归；歧义返回一个确定派生见证，不枚举全部解析树。`extract` 必须配合对应原输入。URI/Cookie 等案例验证格式，不替代完整协议语义或生产流量。[边界说明](BOUNDARIES.zh-CN.md)列出预算及失败契约。

## 完整回执

[原发布页完整快照](development-history/release-0.3.0.zh-CN-through-2026-10-27.md)保留 checksum、原命令身份、验证范围及固定证据链接。更晚的文档修订不改变已发布归档；性能记录保留各自日期和方法，不推为 p95 或跨实现领先。
