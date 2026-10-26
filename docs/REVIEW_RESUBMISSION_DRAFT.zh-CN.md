# MoonABNF 技术补审草稿（0.3.0）

2026-10-26，供用户审阅改写；未发送、未提交。本文仅整理技术事实，不是申请人的个人说明或诚信声明。历史版本和测试日期见[旧草稿](QUARTER_REVIEW_DRAFT.zh-CN.md)，AI 辅助范围见 [AI_USAGE.md](../AI_USAGE.md)。

## 对原问题的回应

原反馈指出项目偏向文法校验，要求输入解析树、真实协议案例与通用性。当前发布的 MoonABNF 0.3.0 已提供调用者自定义 ABNF → `compile` → 可复用 Program → `parse_input` → 输入派生树 → 字段提取的完整路径。`parse` 返回文法 AST；`parse_input` 返回某次输入的派生见证，两者用途不同。`rule_nodes_in`、`span`、`extract` 让调用者按规则定位并取回原输入字节。

协议场景使用 RFC 3986 URI、RFC 6265 Cookie、ETag 与 HTTP 请求行文法，经公共 API 解析；没有把协议算法硬编码到库。JS 协议记录示例将 URI/Cookie 字段及字节跨度输出为 JSON，区分接受、拒绝、预算未判定与配置错误；拒绝或预算不足时不导出部分成功字段。它是可复制的应用层集成示例，不是根包直接导出的 JSON 协议 API。

0.3.0 另有有界失败诊断：局部最远失败字节、实际字节或 EOF、有限期望及可确定的文法位置。URI `%GG`、非法 Cookie 空格、截断及尾随垃圾示例展示如何定位后人工修订，再重新解析。诊断不自动修改输入、不保证唯一修复，也不把预算未判定解释为拒绝。

## 可安装版本与证据

```sh
moon add sundaysebasidian-byte/moonabnf@0.3.0
```

[0.3.0 官方版本](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/)已发布；[PR #7](https://github.com/sundaysebasidian-byte/MoonABNF/pull/7)已合并，发布提交为 `4fc9981cce43cfa0c24874193562f252c761d20f`。[精确 head CI](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959109)与[fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959146)成功，合后检查另列于[发布回执](release-0.3.0.zh-CN.md)。发布后本地干净 registry 消费验证核心/输入树及诊断的四后端，以及 JS JSON 适配与诊断扩展；没有 workspace/path 替代。官方包 checksum、固定源码与逐条问题映射见[证据索引](REVIEW_EVIDENCE_INDEX.zh-CN.md)。

## 保留的限制

输入按字节处理，拒绝左递归，歧义返回一个确定见证而非全部解析树；计算受预算限制。规范公开样例与自编负例不是生产流量，JSON 适配器仅有 JS 证据，不是完整 HTTP 实现。五次独立进程测量保留原日期和本地环境，不能改称本版本新基准或推导 p95、跨实现性能领先。独立 AI 复审不是外部人类认可；尚无真实采用、生产部署或评委复审结论。本稿不承诺初审或季度奖结果。
