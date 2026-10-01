# MoonABNF 中文验收矩阵

记录日期：2026-10-01。这是 AI 辅助工程核对材料，不是赛事组验收结论、人工最终申报书或奖励保证。
赛事要求依据完整阅读的 [官网](https://moonbitlang.github.io/Hackathon2026/) 与
[章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)。核查快照日期9/30；冲突及报名门禁见 RULES.md。

## 初审准备

| 项目 | 实际材料与证据 | 状态 |
|---|---|---|
| 独立初始化和生态价值 | local/moonabnf，独立Git；通用ABNF→AST→诊断→有界识别；TECHNICAL_FACTS.md | 本地已完成；最终选题审核未做 |
| 避免高度同类 | 9/30 Mooncakes有界站内abnf、bnf核查；只见URI字符表；SOURCES.md记录范围 | 未见高度同类；非全生态穷尽证明；报名时需复核 |
| 至少3完整场景 | 协议字段、配置输入、二进制批量fixture；三份文法/成对输入、examples/main.mbt、scenarios_test.mbt | 本机可复现通过 |
| 至少10有效提交 | 9/30已有11个阶段提交，10/1增加FIFO修复与文档整理；完整历史随源码包交付 | 有实质历史；未造空提交、未回填日期；不保证赛事采认 |
| Proposal本人撰写 | 只交AI辅助技术事实、理解资料与来源 | 待用户本人撰写；不提供伪装人工的最终申报书 |
| 赛期有效贡献 | 开发始于9/30，10/1续修；历史日期真实保留 | 十月资格及新增贡献认定待赛事确认 |

## 终验九条

| # | 章程要求 | 本项目证据 | 状态/缺口 |
|---|---|---|---|
| 1 | MoonBit主要实现语言 | parser/types/core/compiler/analysis/recognizer、CLI参数处理与examples均MoonBit；JS仅文件/退出码适配，Python仅验收与oracle | 本地实现符合声明；不据此替代赛事审查 |
| 2 | 公开可访问仓库，清晰提交历史 | 独立本地Git与完整bundle，连续实质阶段提交 | **公开仓库待用户批准**；无远端、未push |
| 3 | 结构清晰，实现声明核心功能 | AST、规则合并与诊断、明确拒绝左递归、全输入识别与预算、check/match/batch CLI | 声明范围内本地测试通过；未声称支持全部ABNF编码与所有文法 |
| 4 | README目标、安装、用法、可复现例子 | README.md、TOOLCHAIN.lock、SDK路径覆盖、examples与自制fixtures、验收脚本 | 本机复现通过；包内本地模块名非已发布安装地址 |
| 5 | CI覆盖check/build/test | .github/workflows/ci.yml固定编译器，调用同一低并发验收脚本并保留失败日志 | 配置完成；**远端CI未执行**，本地check/build/test通过 |
| 6 | 至少一个可运行例子 | examples/main.mbt的协议/配置/二进制三个例子；CLI fixtures | 本机运行通过，原始输出已存 |
| 7 | 完整测试覆盖核心路径 | 四后端各18测试组、20项CLI进程检查、5,440差分；正常/错误/字节边界/空匹配/重复/折行/预算/循环等 | 已列范围通过；有限测试不是“全部正确”或完整标准认证 |
| 8 | 发布Mooncakes | 发布所需工程结构、license、metadata、API已本地准备 | **待用户批准**；正式命名空间未定，未发布/未验证registry consumer |
| 9 | OSI许可与参考依赖合规 | MIT；SOURCES.md；AI_USAGE.md；自制fixtures；licenses/保留core Apache-2.0与NOTICE；不打包RFC原文 | 已准备来源与许可清单；最终公开/二进制发行前仍需检查实际依赖与署名 |

## 本机实际结果

最终串行命令见 `evidence/final-20261001/summary.json`，各命令stdout/stderr及SHA256独立存档。
旧16组验证快照仍保留在 `evidence/acceptance/`，最新18组结果在 final-20261001。

| 验证项 | 结果 | 边界 |
|---|---|---|
| 格式、Wasm/JS/native check与build | 全部退出0，编译警告作为错误 | macOS arm64；没有Linux/Windows实机验证 |
| Wasm/Wasm GC/JS/native测试 | 每后端18组，18 passed，0 failed | 分组内含256字节多core断言，不把“18组”误写成18个输入 |
| 三场景可运行例子 | 预期匹配与拒绝均出现 | 格式校验，不验证真实协议业务/认证 |
| CLI真实进程检查 | macOS20项通过 | 含缺失文件、目录、FIFO、空输入、NUL/FF、混合batch、超限与非法预算；Windows FIFO未测 |
| 独立实现差分 | 固定seed20260930；80随机文法，5,440比较，0差异 | Python标准库bytes正则全匹配；只正则子集；没有第三方完整ABNF parser差分 |
| 解析与编译诊断 | 未定义、重复基定义、增量无基、prose、非生产/可空前缀左递归、数值/预算超限均有测试 | 只首个诊断，无恢复；全规则都验证，包括未选入口 |
| 资源上限 | 超长输入、工作量、累积端点、调用深度、文法节点/字节/规则/嵌套/分析预算均测 | 操作预算不是墙钟超时；高复杂度有效文法可返回未判定 |
| 未使用组件 | Artemis、LibreOffice未安装/运行 | 不声明相应互操作或兼容性 |

## 尚未完成与需要本人处理

公开仓库/远端CI、Mooncakes发布与发布后consumer检查、本人申报、身份与诚信材料未完成。
正式提交前，用户须本人撰写一页申报，确认最终命名空间/署名及赛期资格，亲自处理
电话、身份证、银行卡/分行、学籍/学历资料和诚信承诺。10/31官网与10/24旧章程冲突
仍在记录中；内部按10/24前准备，不把最终时刻说成已确认。150+350元支持均有审核条件。

不保证一次验收。当前0个已知最终流程失败；未测项不是“通过”。后续若测试发现问题，修实现并保留回归，不降低断言或隐瞒失败。
