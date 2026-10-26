# 输入树 API：最短可复现路径

这是未发布候选的用法。公开0.1.0不含该API；不要用旧版本安装结果验证以下功能。
本轮捕获/URI/Cookie 示例、准确输入约束和演示见 [捕获契约与复用](https://github.com/sundaysebasidian-byte/MoonABNF/blob/de59153173eeb3124bda8923859c6c6026261c4f/docs/QUALITY_20261020.zh-CN.md)。

## 从交付归档开始

先解压最外层交付包，再解压其中的 `source.zip` 到一个新目录，进入包含 `moon.mod` 的源码根目录。核对交付清单中的源码SHA；不要直接在只含补丁和日志的外层目录执行 `moon`。历史交付的源码归档可能有不同文件名，以该交付清单为准。

```sh
unzip source.zip -d moonabnf-candidate
cd moonabnf-candidate
export MOON_HOME=/absolute/path/to/trusted-sdk
export PATH="$MOON_HOME/bin:$PATH"
moon version --all
moon run examples/input_tree --target js -j 1 -d
```

这些命令明确选择已有可信SDK。锁定版本见 `TOOLCHAIN.lock`；本轮实际环境及限制见捕获契约文档和交付日志，不要把历史不同SDK的证据混入本轮。源码包保留原有脚本执行位；部分解压工具会移除执行位，必要时运行 `chmod +x scripts/*.sh`。

## 运行公共接口示例

使用已有可信SDK，在源码根目录运行：

```sh
export MOON_HOME=/absolute/path/to/trusted-sdk
export PATH="$MOON_HOME/bin:$PATH"
moon run examples/input_tree --target js -j 1 -d
```

预期输出：

```text
matched: value bytes=[4,6)
no-match: byte=4
indeterminate: tree-nodes
```

完整可运行源码见 `examples/input_tree/main.mbt`。文法定义独立的 `record`、`key`、`value` 规则；库没有为这个记录格式写专用解析逻辑。

## 调用顺序和状态处理

1. `compile(grammar)` 返回 `Result[Program, Diagnostic]`。先处理文法错误；文法文本要求CRLF，包括最后一行。
2. 复用 `Program`，每次传入入口规则和原始 `Bytes` 调用 `parse_input`。
3. 仅在 `Matched` 分支读取 `report.tree`。匹配必须覆盖完整输入；尾随字节也会导致失败。
4. `NoMatch` 表示在预算内确认不匹配。`BudgetExceeded` 表示未判定；此前某条分支成功也不能把最终预算失败当作成功。
5. `UnknownRule` 和 `InvalidLimits` 是调用配置错误，示例单独处理。

节点的 `[start,end)` 是字节区间，可用原输入切片取值。不要把它当字符下标；空字段允许 `start == end`。孩子是平坦数组中的ID；不要依赖某次解析的偶然节点编号，优先查找 `RuleNode("value")` 等命名节点。

同一端点保留首次遇到的派生，其他端点继续探索。这能保留后续拼接可能成功的路径，但不会输出全部歧义树。`source_offset` 是文法表达式的位置；隐式core规则使用合成位置0。

## 规范字段示例

```sh
moon run examples/http_etag/cmd --target js -j 1 -d
```

预期为 `HTTP ETag: weak=true value-bytes=[3,13)`。`extract` 只接受该示例文法下成功解析的 `entity-tag` 树；不要传入任意手工构造的树。ETag内容保持原始字节，不进行反斜杠反转义。

## 验证本地候选

```sh
python3 scripts/downstream.py --moon "$MOON_HOME/bin/moon" --output /absolute/new-empty-evidence
```

脚本实际打包、绑定源码哈希、在隔离工作区引用公共API，并运行四个后端。证据目录必须为空。`--moon`明确选择SDK，结果应记录其版本；默认入口仍使用 `TOOLCHAIN.lock` 的旧SDK门禁。

注册表消费者是另一个步骤，要求明确的已批准发布版本；不会从本地0.1.0元数据推断“新API已经发布”。本包不执行发布。

## 边界回归与偏移的准确含义

`input_tree_test.mbt` 新增两组组合回归，使用公共接口：

- 文法 `s = (%xC3 / %xC3.A9) %x21` 把输入当原始字节。`C3 21` 与 `C3 A9 21` 都可匹配不同分支；这不要求第一个输入构成合法UTF-8。
- `C3 A8 21` 在字节1失败；截断的 `C3 A9` 到达字节2；完整前缀 `C3 A9 21` 后再有NUL，整段不匹配，最远到达字节3。所有失败均无输入树。
- 两条规则都可产生空串时，空输入返回一个真实零宽派生；实际两次空重复保留两个孩子。NUL输入不能被该空文法完整匹配。
- 对空输入构树耗尽节点预算后，下一次使用默认预算仍得到相同树；每次调用的状态和预算互相独立。

失败偏移是“最远尝试或到达的字节位置”，不是Unicode字符位置，也不保证唯一解释错误原因。`BudgetExceeded` 仍是未判定，不能归入不匹配。回归没有改变歧义选择、递归限制或预算契约。
