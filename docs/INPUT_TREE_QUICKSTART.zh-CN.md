# 输入树 API：从 0.3.0 安装开始

输入派生树与字段提取已发布。0.1.0 只有文法 AST 与识别，不能运行本页接口。

## 独立消费者

在新的空目录中安装，不需要仓库 workspace 或本地路径依赖：

```sh
mkdir moonabnf-input-tree
cd moonabnf-input-tree
printf 'name = "local/input-tree-demo"\nversion = "0.1.0"\n' > moon.mod
moon add sundaysebasidian-byte/moonabnf@0.3.0
```

创建 `moon.pkg`：

```moonbit
import { "sundaysebasidian-byte/moonabnf" @abnf }
options(is_main: true)
```

创建 `main.mbt`：

```moonbit
fn main raise {
  let grammar = b"record = key \":\" value\r\nkey = 1*ALPHA\r\nvalue = 1*DIGIT\r\n"
  let program = match @abnf.compile(grammar) {
    Ok(program) => program
    Err(d) => fail("grammar error \{d.code} at byte \{d.offset}")
  }
  let input = b"Age:42"
  let report = program.parse_input("record", input)
  assert_eq(report.status, @abnf.Matched)
  for node in report.tree.unwrap().nodes {
    if node.kind is @abnf.RuleNode("value") {
      assert_eq(input[node.start:node.end].to_owned(), b"42")
      println("value bytes=[\{node.start},\{node.end})")
    }
  }
}
```

```sh
moon run . --target js
# value bytes=[4,6)
```

完整状态处理见[固定发布源码示例](https://github.com/sundaysebasidian-byte/MoonABNF/blob/4fc9981cce43cfa0c24874193562f252c761d20f/examples/input_tree/main.mbt)。该例还验证 `Age:` 不匹配及节点预算耗尽。

## 读取结果

- `compile` 解析调用方文法；文法要求 CRLF，包括最后一行。`parse` 返回文法 AST，`parse_input` 返回某次输入的派生树。
- 仅在 `Matched` 时读取树；匹配覆盖全部输入。`NoMatch` 是预算内确认拒绝，`BudgetExceeded` 是未判定。`UnknownRule`、`InvalidLimits` 属于调用配置错误。
- `[start,end)` 是原输入的半开字节区间，空字段可为零宽。`rule_nodes_in`、`span`、`extract` 可定位和提取字段；`extract` 必须配合对应原输入。
- 同端点保留首次派生，其他端点继续探索，不枚举全部歧义树。每次调用独立计预算；耗尽后仍可复用 `Program`。
- `diagnose_input` 可补充局部失败期望；它不改变接受集合，也不把预算耗尽解释成语法错误。

## 协议案例与复现

[ETag 示例](../examples/http_etag/cmd/main.mbt)提取弱标签与原始字节；[URI/Cookie 协议记录](PROTOCOL_RECORD_CASE.zh-CN.md)将字段组织为 JSON，区分匹配、拒绝、预算及配置错误。JSON 适配器是可复制的 JS 集成示例，不是根包导出。

检出仓库后，可运行 `moon run examples/input_tree --target js -j 1` 或 `moon run examples/http_etag/cmd --target js -j 1`。源码绑定验证与 registry 安装验证分开：

```sh
python3 scripts/registry_consumer.py --release-version 0.3.0 --moon /path/to/moon --output /new/empty/evidence
```

脚本拒绝非空证据目录，安装后检查精确版本及 registry 来源，再在四后端运行公共接口断言。已有发布结果与工具链见[技术证据索引](TECHNICAL_EVIDENCE.zh-CN.md)；边界见[失败契约](BOUNDARIES.zh-CN.md)。
