# MoonABNF 中文验收矩阵

记录日期：2026-10-01。这是 AI 辅助工程核对材料，不是赛事组验收结论、人工最终申报书或奖励保证。
赛事要求依据完整阅读的 [官网](https://moonbitlang.github.io/Hackathon2026/) 与
[章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)。核查快照日期9/30；冲突及报名门禁见 RULES.md。

## 初审准备

| 项目 | 实际材料与证据 | 状态 |
|---|---|---|
| 独立初始化和生态价值 | sundaysebasidian-byte/moonabnf，独立Git；通用ABNF→AST→诊断→有界识别；TECHNICAL_FACTS.md | 本地已完成；最终选题审核未做 |
| 避免高度同类 | 9/30 Mooncakes有界站内abnf、bnf核查；只见URI字符表；SOURCES.md记录范围 | 未见高度同类；非全生态穷尽证明；报名时需复核 |
| 至少3完整场景 | 协议字段、配置输入、二进制批量fixture；REUSE_REVIEW.zh-CN.md列完整输入/API/输出/断言；独立消费者四后端运行 | 本机可复现通过；不声称真实第三方采用 |
| 开发与MVP历史 | 公开基线18个非空非merge提交，按用户明确的北京时间口径均在10/1；完整真实历史随源码包交付 | 未造空提交、未回填日期；每次贡献有效性仍由主办认定 |
| Proposal本人撰写 | 只交AI辅助技术事实、理解资料与来源 | 待用户本人撰写；不提供伪装人工的最终申报书 |
| 赛期有效贡献 | 用户已明确采用北京时间；公开基线18个真实提交均落在10/1，不改写Git时间 | 时区不再作为待确认阻塞；赛期贡献有效性待赛事审核 |

## 终验九条

| # | 章程要求 | 本项目证据 | 状态/缺口 |
|---|---|---|---|
| 1 | MoonBit主要实现语言 | parser/types/core/compiler/analysis/recognizer、CLI参数处理与examples均MoonBit；JS仅文件/退出码适配，Python仅验收与oracle | 本地实现符合声明；不据此替代赛事审查 |
| 2 | 公开可访问仓库，清晰提交历史 | https://github.com/sundaysebasidian-byte/MoonABNF ，原历史正常推送；0.1.0源码SHA见PUBLICATION.md | 已公开；不等于赛事认可历史贡献 |
| 3 | 结构清晰，实现声明核心功能 | AST、规则合并与诊断、明确拒绝左递归、全输入识别与预算、check/match/batch CLI | 声明范围内本地测试通过；未声称支持全部ABNF编码与所有文法 |
| 4 | README目标、安装、用法、可复现例子 | README.md、TOOLCHAIN.lock、SDK路径覆盖、examples与自制fixtures、验收脚本；正式namespace与registry安装已实测 | 已公开版本可复现；本轮边界说明已获用户核准纳入现有GitHub |
| 5 | CI覆盖check/build/test | .github/workflows/ci.yml固定编译器；准确0.1.0源码提交2f32fdc的运行36832382024成功，原始summary同SHA、工作树干净 | Linux远端check/build/test及完整验收通过；准确链接见PUBLICATION.md |
| 6 | 至少一个可运行例子 | examples/main.mbt的协议/配置/二进制三个例子；CLI fixtures | 本机运行通过，原始输出已存 |
| 7 | 完整测试覆盖核心路径 | 当前本地候选四后端各22组、24项CLI、5,440差分；公开0.1.0基线各18组/20项 | 本地候选范围通过，新增回归远端CI按准确收尾SHA另核；有限测试不是完整标准认证 |
| 8 | 发布Mooncakes | https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.1.0/ ；publish200、view验证版本与MIT；独立正式消费者source.kind=registry | 0.1.0已正式发布；三个场景/API断言四后端通过；无本地workspace替代 |
| 9 | OSI许可与参考依赖合规 | MIT；SOURCES.md；AI_USAGE.md；自制fixtures；licenses/保留core Apache-2.0与NOTICE；不打包RFC原文 | 已准备来源与许可清单；最终公开/二进制发行前仍需检查实际依赖与署名 |

## 本机实际结果

本轮收尾源码最终文档冻结后重新执行完整串行验收；命令、stdout/stderr及源码SHA256见审查 ZIP 的 `verification/summary.json`。
公开0.1.0基线的18组/20项历史证据在 `evidence/final-20261001/` 与 `evidence/reuse-20261001/`，更早16组在 `evidence/acceptance/`。
第一轮边界补充运行后曾修改文档，旧summary的BOUNDARIES哈希因此与随后文档不同；旧证据原样保留，本轮重跑生成新的最终快照，不将旧结果哈希改写成新文档。

| 验证项 | 结果 | 边界 |
|---|---|---|
| 格式、Wasm/JS/native check与build | 本地与准确发布提交Linux CI全部退出0，编译警告作为错误 | macOS arm64与Linux x86_64实际运行通过；Windows未测 |
| Wasm/Wasm GC/JS/native测试 | 当前本地候选每后端22组通过，0失败；公开0.1.0基线18组 | 组内含多项断言；不把测试组数误写成输入个数；新增回归远端结果随准确SHA发布后证据保存 |
| 三场景可运行例子 | 预期匹配与拒绝均出现 | 格式校验，不验证真实协议业务/认证 |
| 独立下游候选包复用 | 实际moon package ZIP、隔离解压、独立消费者模块、四后端全部断言与11行输出逐字核对通过；依赖树与包源码哈希一致 | 不读私有API、不引用主工程路径；该验证是本地候选路径，正式注册表消费另记；不证明真实第三方采用或完整业务集成 |
| 正式版本独立注册表消费 | moon update后在独立模块build安装0.1.0；依赖树确认registry、非workspace；三场景及AST/诊断/预算独立性断言四后端通过 | 初次本地索引未更新的失败保留；不证明真实第三方采用、broker或办公软件互操作 |
| CLI真实进程检查 | 当前候选macOS24项通过；公开0.1.0基线20项 | 含缺失文件、目录、FIFO、空输入、NUL/FF、混合batch、超限与非法预算；Windows FIFO未测 |
| 独立实现差分 | 固定seed20260930；80随机文法，5,440比较，0差异 | Python标准库bytes正则全匹配；只正则子集；没有第三方完整ABNF parser差分 |
| 解析与编译诊断 | 未定义、重复基定义、增量无基、prose、非生产/可空前缀左递归、数值/预算超限均有测试 | 只首个诊断，无恢复；全规则都验证，包括未选入口 |
| 资源上限 | 超长输入、工作量、累积端点、调用深度、文法节点/字节/规则/嵌套/分析预算均测 | 操作预算不是墙钟超时；高复杂度有效文法可返回未判定 |
| 未使用组件 | Artemis、LibreOffice未安装/运行 | 不声明相应互操作或兼容性 |

## 尚未完成与需要本人处理

公开仓库、准确发布提交远端CI、Mooncakes 0.1.0发布与正式版本独立consumer检查已完成。
本人申报、身份与诚信材料未完成；发布不等于初审/终验通过或获奖。
正式提交前，用户须本人撰写一页申报，确认最终命名空间/署名及赛期资格，亲自处理
电话、身份证、银行卡/分行、学籍/学历资料和诚信承诺。10/31官网与10/24旧章程冲突
仍在记录中；内部按10/24前准备，不把最终时刻说成已确认。150+350元支持均有审核条件。

不保证一次验收。当前0个已知最终流程失败；未测项不是“通过”。后续若测试发现问题，修实现并保留回归，不降低断言或隐瞒失败。

复用补审保留失败记录：消费脚本第一轮tree参数不支持、第二轮消费者编译声明/方法错误，
均未运行场景断言；修正后完整复验通过，无核心功能扩张、无断言放宽。另保留首次源码解压移除执行位的测试未启动记录。
LogLens两次退回原因据用户已核邮件只用于改进MVP与通用价值证据，不改写为测试/许可证退回。
详见 REUSE_REVIEW.zh-CN.md；此矩阵仍是AI辅助工程事实，不是人工最终申报或官方验收结论。
