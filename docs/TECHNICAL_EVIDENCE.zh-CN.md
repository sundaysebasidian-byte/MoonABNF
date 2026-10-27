# MoonABNF 技术证据索引

核对日期：2026-10-27。当前安装版 **0.3.0**。这里对应“从文法校验走向通用解析”的复审问题。

| 项目 | 内容与证据 |
| --- | --- |
| 旧基线 | 0.1.0 的文法 AST 与识别不能替代输入解析树。旧候选说明保留在历史提交，当前契约见[边界](BOUNDARIES.zh-CN.md)。 |
| 本期贡献 | 调用方自定义文法 → 可复用 Program → 输入派生树 → 命名字段与字节区间；0.3.0 增加有界局部失败诊断。[输入树上手](INPUT_TREE_QUICKSTART.zh-CN.md)、[URI/Cookie → JSON](PROTOCOL_RECORD_CASE.zh-CN.md)。 |
| 当前安装版 | `moon add sundaysebasidian-byte/moonabnf@0.3.0`；[官方包](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.3.0/)、[发布提交 4fc9981](https://github.com/sundaysebasidian-byte/MoonABNF/commit/4fc9981cce43cfa0c24874193562f252c761d20f)。 |
| 复现 | 源码示例：`moon run examples/input_tree --target js -j 1`、`moon run examples/diagnostics --target js -j 1`。独立安装：`python3 scripts/registry_consumer.py --release-version 0.3.0 --moon /path/to/moon --output /new/empty/evidence`。协议 JSON 步骤见案例文档。 |
| CI | 发布 head：[核心](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959109)、[fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40220959146)。文档修订前主干 `3af4866`：[核心](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40288660270)、[fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40288659917)。 |

发布轮干净 registry 消费验证核心、输入树与诊断四后端；JSON 适配器只验 JS。它是需复制的集成示例，不是根包导出。包内 README 保留发布时旧文字，版本和功能以 manifest/API 与[发布回执](release-0.3.0.zh-CN.md)为准；当前文档不改写不可变归档。

基准 CPU 为 **AMD EPYC 9V45 96-Core Processor，4 个逻辑 CPU**，moonc 0.10.14。[固定 job](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40287620677/job/121454911195)是 README 表格来源；更正型号不改变数值。自适应分组均值不能称作五次独立进程或 p95。

剩余边界：按字节解析，拒绝左递归，只返回一个确定派生见证；预算耗尽为未判定。URI/Cookie/ETag 使用规范语料与测试输入，尚无外部用户采用证据。来源与辅助工具使用见 [SOURCES](../SOURCES.md)、[AI_USAGE](../AI_USAGE.md)。

外部规范安装版用例：[RFC3339 字段提取](RFC3339_REGISTRY_CASE.zh-CN.md)，两条官方样例和一条自编负例已通过；日期语义另行校验。

2026-10-27 文档修订：[PR #13](https://github.com/sundaysebasidian-byte/MoonABNF/pull/13)（合并提交 [c3e6793](https://github.com/sundaysebasidian-byte/MoonABNF/commit/c3e6793a50d4fc2848089d1e665b47f6f78ccee4)）。各项测试记录仍按对应运行提交引用。
