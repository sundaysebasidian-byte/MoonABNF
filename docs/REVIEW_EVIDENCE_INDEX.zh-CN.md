# MoonABNF 评审问题证据索引

核对日期 2026-10-26。供用户审阅和改写，未向评审发送或提交比赛；AI 辅助范围见 [AI_USAGE.md](../AI_USAGE.md)。是否解决评委顾虑由评委重新审核，本页不提供获奖概率。

当前已发布 **0.3.0**：[精确安装、提交、checksum 与验证范围](release-0.3.0.zh-CN.md)。以下源码链接固定到发布提交 `4fc9981cce43cfa0c24874193562f252c761d20f`，CI 固定到测试 head 或合并提交，不把历史徽章当成本次文档验证。

| 原始顾虑 | 已有证据与复现入口 | 仍有边界 |
| --- | --- | --- |
| 只是文法校验库，缺少通用解析能力 | 调用者自定义文法经 `compile` 得到可复用 Program；`parse_input` 返回某次输入的派生树，与 `parse` 的文法 AST 区分。[公共接口](https://github.com/sundaysebasidian-byte/MoonABNF/blob/4fc9981cce43cfa0c24874193562f252c761d20f/pkg.generated.mbti)；[输入树示例](https://github.com/sundaysebasidian-byte/MoonABNF/blob/4fc9981cce43cfa0c24874193562f252c761d20f/examples/input_tree/main.mbt) | 字节级、有预算、拒绝左递归，歧义只给一个确定见证；不是完整规范认证 |
| 需要输入解析树与字段提取 | `rule_nodes_in`、`span`、`extract` 提取原输入半开字节区间；发布后 registry 核心/树 API 在四后端通过，见版本回执 | extract 必须配合对应原输入；不替调用方做 URI 解码、业务校验 |
| 需要真实协议场景及通用性验证 | RFC URI/Cookie、ETag、请求行经同一公共 API；[JS JSON 协议记录示例](https://github.com/sundaysebasidian-byte/MoonABNF/blob/4fc9981cce43cfa0c24874193562f252c761d20f/integration/protocol_consumer/main.mbt.in)；[来源与许可](https://github.com/sundaysebasidian-byte/MoonABNF/blob/4fc9981cce43cfa0c24874193562f252c761d20f/fixtures/protocols/SOURCES.md)；[复现说明](PROTOCOL_RECORD_CASE.zh-CN.md) | 规范公开样例和自编负例，不是生产流量；JSON 是需复制的 JS 示例，不是根包导出或完整 HTTP 栈 |
| 失败时是否能帮助调用者定位 | 0.3.0 `diagnose_input` 给出局部最远失败字节、实际字节/EOF、有限期望及可确定的文法位置；[四个协议失败示例](https://github.com/sundaysebasidian-byte/MoonABNF/blob/4fc9981cce43cfa0c24874193562f252c761d20f/examples/diagnostics/main.mbt) | 此项是额外应用改进，不冒充新增评语；不自动修复，不把 `BudgetExceeded` 当拒绝 |
| 能否实际安装和复现 | [PR #7](https://github.com/sundaysebasidian-byte/MoonABNF/pull/7)、[精确 head 验收](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959109)、[fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959146)；实际 registry 核心/诊断四后端及 JS 协议扩展通过 | registry 消费是本地发布轮回执，不冒充 CI；完整本机日志未公开上传 |

## 历史与未完成项

[旧矩阵](REVIEW_CONCERNS_MATRIX.zh-CN.md)、[旧复审草稿](QUARTER_REVIEW_DRAFT.zh-CN.md)保留原日期、版本和失败；其中“仅本地/未发布”只描述当时阶段。发布后的文档修订不回写历史归档；后续提交须核验其自身状态。

[五进程测量](FIVE_PROCESS_BENCHMARK.zh-CN.md)保留原机器、工具链、输入、暖构建和原始数据身份；不改为 0.3.0 新实测，不从五个均值推 p95，不宣称比其他实现快。已有独立 AI 复审不是外部人类 review；真实采用、外部评审认可、生产部署与季度奖结论均未取得。
