# MoonABNF 技术补审草稿（0.3.0）

2026-10-26，供审阅，未提交。本文整理项目技术事实，不含申请人的个人说明或诚信声明。历史测试见[旧草稿](QUARTER_REVIEW_DRAFT.zh-CN.md)，AI 辅助范围见 [AI_USAGE.md](../AI_USAGE.md)。

## 通用解析与字段提取

原反馈要求补充输入解析树和真实协议案例。MoonABNF 0.3.0 接收调用方提供的 ABNF 文法：`compile` 生成可复用的 Program，`parse_input` 解析输入，`rule_nodes_in`、`span`、`extract` 按规则定位并提取原字节。`parse` 返回文法 AST；`parse_input` 返回某次输入的派生树。

URI、Cookie、ETag 和 HTTP 请求行案例使用同一组公共 API。JS 协议记录示例把 URI/Cookie 字段和字节跨度输出为 JSON，分别报告接受、拒绝、预算未判定和配置错误。拒绝或预算不足时不导出部分字段。文法来源和许可证保留在仓库；JSON 适配器是需复制的集成示例，不是根包导出。

0.3.0 新增有界失败诊断，报告局部最远失败字节、实际字节或 EOF、有限期望和可确定的文法位置。URI `%GG`、非法 Cookie 空格、截断和尾随垃圾示例展示定位及人工修订后重新解析。诊断不自动修改输入，也不保证唯一修复。

## 发布与复现

```sh
moon add sundaysebasidian-byte/moonabnf@0.3.0
```

[官方 0.3.0](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/)已发布，[PR #7](https://github.com/sundaysebasidian-byte/MoonABNF/pull/7)已合并。发布提交为 `4fc9981cce43cfa0c24874193562f252c761d20f`；[候选 head 验收](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959109)和[fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959146)通过。合后检查和包 checksum 见[发布回执](release-0.3.0.zh-CN.md)。

发布后在本地新目录从 registry 精确安装，未使用 workspace/path 覆盖。核心、输入树及诊断在四后端通过；协议 JSON 和诊断扩展在 JS 通过。[证据索引](REVIEW_EVIDENCE_INDEX.zh-CN.md)列出固定源码和各项验证范围。

## 限制

库按字节处理输入，拒绝左递归，歧义只返回一个确定见证；`BudgetExceeded` 表示预算内未判定。协议案例使用规范样例和自编负例，没有生产流量证据，也不是完整 HTTP 实现。JSON 适配器目前只验证 JS。

五次独立进程测量保留原日期、机器和缓存条件，不是 0.3.0 新基准；样本不足以报告 p95，也未作跨实现速度比较。已有独立 AI 复审，尚无外部人类审查、真实采用或评委复审结论。
