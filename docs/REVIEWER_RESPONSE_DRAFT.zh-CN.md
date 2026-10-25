# MoonABNF 0.2.0 评审补充说明

> 历史快照提示（2026-10-25更新）：下方正文保留原阶段事实、日期和失败记录，不是当前发布状态。两库正式版本现为0.2.1，ABNF #6与STOMP #8均已合并；本库发布提交、checksum、消费验证和边界见[0.2.1说明](release-0.2.1.zh-CN.md)。`diagnose_input`及诊断扩展仍仅在未公开开发源码，见[README](../README.md)，不属于0.2.1。“本轮”“未推送”“Draft”等下文表述只描述当时阶段；本轮未向评审发送或提交比赛。

供用户审阅的修正草稿，未发送、未提交。事实核对日期：2026 年 10 月 24 日。

## 当前结论

MoonABNF 0.2.0 已在 Mooncakes 正式发布。输入派生树与字段提取不再仅存在于本地候选；评审可从 registry 安装实际版本核验。核心 API 与 JS 协议记录适配器的范围分别说明。

```sh
moon add sundaysebasidian-byte/moonabnf@0.2.0
```

- [包页面](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf)
- 发布提交：`d3773eca760437a1b0a50b75f4449bf20e89c574`
- 本稿固定文档提交：`5a410cc9c1aabec49a72a93161118e6a4eebe076`
- [版本 PR #4](https://github.com/sundaysebasidian-byte/MoonABNF/pull/4)

## 针对评审关切的补充

仓库既有草稿记载，评审建议增强通用解析能力，增加输入解析树生成和真实协议场景验证。本稿沿用该草稿所记反馈，不新增评审意见，不表示评审已认可下列结果。

### 通用解析能力

调用方可提供自己的 ABNF 文法，使用 `compile(Bytes)` 得到可复用 `Program`，再以 `parse_input(入口规则名, 输入字节)` 解析输入。完整匹配返回输入派生树，保留命名规则、终端、分支、重复和字节区间。`parse(Bytes)` 返回文法 AST；`parse_input` 返回某次输入的派生结构。

核心按字节处理输入，拒绝左递归；歧义时返回一个确定的派生见证，不枚举全部树。运行受预算约束，`BudgetExceeded` 表示预算内未判定，不是 `NoMatch`。

### 输入树与字段提取

`InputTreeReport`、`InputNode`、`rule_nodes_in`、`span` 和 `extract` 支持定位字段并取回原输入字节。`examples/input_tree` 用调用方定义的记录文法演示 `Age:42` 中 `value` 的半开区间 `[4,6)`，同时展示不匹配和预算耗尽。`extract` 必须配合对应原输入使用。

发布后，全新 registry 消费者四后端核心及输入树 API 检查通过，没有 workspace/path 覆盖。这证明所测配置下的实际可消费性，不是所有系统与工具链组合的兼容承诺。

### 真实规范场景

ETag、URI、Cookie 案例通过同一公共接口完成规范字段解析与提取。ETag 覆盖弱标签、空值、字节边界和非法输入；协议记录示例将 URI 与 Cookie 组织为 JSON，区分匹配、拒绝、预算耗尽和配置错误。

发布后独立 JS 消费者的黄金输出、拒绝、预算、配置错误检查通过。JSON 适配器是可复制的集成示例，不是根包导出 API；目前只具有 JS 验证证据。核心四后端成功不能替代适配器跨后端测试。这些案例使用真实规范和测试输入，不声称接入真实下游生产系统、完整 HTTP 实现或线上部署。

## 验证证据与复现

0.2.0 由 CLI 成功回执、registry 版本/metadata 和下载包 checksum 一致性确认，不仅是 GitHub 合并。版本 PR #4、文档 PR #5 已合并；上述文档 SHA 的核心及锁定/最新 SDK fresh-clone 通过：

- [核心验收](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40113025799)
- [Fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40113025784)
- [固定 SHA 协议记录说明](https://github.com/sundaysebasidian-byte/MoonABNF/blob/5a410cc9c1aabec49a72a93161118e6a4eebe076/docs/PROTOCOL_RECORD_CASE.zh-CN.md)

公共接口、示例与来源按该固定 SHA 检查，避免混入未来变更。上述是发布轮证据；本轮私有补丁、本地命令和未执行 CI 另行记录，不借既有主分支 CI 背书。

## 边界与后续方向

正则差分仅覆盖受限子集，不是完整 ABNF 第三方 oracle。树重放是见证检查，不等于完整规范认证。已有部分工作负载基准；本稿不提供未执行的新成对成本数字，不声称优于其他实现。

下一步是独立 JS 适配器 CI，以及同输入、预算、SDK 下的识别/构树对照。这些计划未计入上述发布轮已完成结果。本轮准备和实测结果另存命令证据，不把五组自适应 bench 当独立五轮或 p95，不把节点数当 RSS。没有把 AI 辅助自测写成人类独立试用、采用或获奖依据。

本文供用户审阅改写，未向评审发送、未代填表单。发布与测试通过不等于初审或获奖。[修正前草稿原文](https://github.com/sundaysebasidian-byte/MoonABNF/blob/5a410cc9c1aabec49a72a93161118e6a4eebe076/docs/REVIEWER_RESPONSE_DRAFT.zh-CN.md) 保留当时 SDK、候选和未发布口径，旧实测不改记为本轮测试。
