> 后续组合扩展：本页有限词表/范围及86项结果描述 f884dd0 阶段。当前源码分支另支持组合与重复，见 [COMPOSED_PROSE](COMPOSED_PROSE_20261030.md)；旧测试数不冒充新结果。

# 数值终结符与显式 prose 绑定：源码分支增量

本源码分支在左递归与空语言修复基础上扩展；未发布新的 Mooncakes 版本，原默认分支及旧提交包不由此覆盖。此前文档中的“仅字节/不支持 prose 执行”描述仍适用于旧入口及旧包，不代表本页新增入口。新增功能需使用本目录源码及锁定 SDK 0.10.18。

## 三种边界分清

| 入口 | 数值终结符域 | 用途 |
|---|---|---|
| `parse` / `compile` | 0..255 | 保持 Bytes 原入口；原 `compile` 仍拒绝 prose |
| `parse_numeric` | 0..2147483647（Int32 表示上限） | 编码无关的公开 AST；允许 `%x110000`，不声称它是 Unicode；更大整数是实现上限，不是 ABNF 语法错误结论 |
| `compile_scalar` | Unicode scalar 值 | 显式应用域，返回独立 `ScalarProgram`；不是 RFC 唯一外部编码，也不读取任意 UTF 编码 |

依据：[RFC 5234 §2.4](https://www.rfc-editor.org/rfc/rfc5234#section-2.4) 将外部编码与 ABNF 分开；[Unicode §3.9](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/#G7404) 定义 scalar 域。这里数值输入为 `Array[Int]`，每个元素是一项 scalar，范围 0..10FFFF，排除 D800..DFFF。负数、surrogate code unit、110000 均返回 `Err(InvalidScalar(index, value))`；UTF-16 代理对不被合并，UTF-8字节也不被解码。未分配码点与 noncharacter 仍是 scalar，可匹配。没有 Unicode normalization 或 Unicode 大小写折叠。

`%xD7FF-E000` 表示此区间与 scalar 域的交集，可以匹配 D7FF/E000；输入 surrogate 仍报错。完全落在 surrogate 区的范围/单值在 scalar 编译阶段报 `symbol-domain`。区间跨 surrogate 时两侧有效值保留。

Quoted strings 仍是 RFC ASCII 语义，默认/`%i` 仅折叠 ASCII A..Z，`%s` 敏感。核心规则仍是原 ASCII/字节数值定义，`OCTET` 不被扩成“任意 Unicode”。

## prose：显式有限语言，不猜自然语言

`compile_with_prose(source, bindings)` 返回 Bytes `Program`；`compile_scalar(source, bindings=...)` 返回 scalar 程序。

绑定类型 `ProseBinding { name, predicate }`：name 是 `<...>` 内原文，大小写与空格精确匹配；空名对应合法 `<>`。name 只允许 prose 可表达的 ASCII 文本，不允许 `>`、换行或非 ASCII。未绑定 `prose-unbound`，重复名 `duplicate-prose-binding`。有效但未使用的绑定允许，未使用的非法绑定也报错，避免静默掩盖错误。

`ProsePredicate` 是**声明式、可预算的有限语言/范围谓词**，不是通用可执行回调：

- `Words([[65,66], [67]])`：精确匹配 AB 或 C，区分大小写，保留所有不同终点；无最长词优先假设。
- `Words([])`：空语言，不等于 epsilon。
- `Words([[]])`：epsilon；可与递归和有下界重复组合。
- `SymbolRange(lo,hi)`：恰好匹配一个域内数值，闭区间，不匹配 epsilon。

绑定被编译成 Choice/Sequence/Range AST；所有展开受编译 work 与 nodes 上限约束；编译后的程序不保留调用者词表数组。修改外层绑定数组、内层 word/words 不改变既有程序。绑定使用位置的 `source_offset` 保持 `<` 的文法字节位置；树显示降级结构，不伪造自然语言解析依据。

[ RFC 5234 §4 ](https://www.rfc-editor.org/rfc/rfc5234#section-4) 为 prose 提供文本语法，不替应用定义执行解释。未来若增加通用 predicate callback，必须另设计可证明的终点集合、nullable 声明、一致性与失效契约，以及不可抢占调用的时间边界；本实现**没有**该能力，不能用“每次计步”假装可限制任意回调运行时间。

## 匹配、预算与树

字节和 scalar 共用同一有限固定点/递归下降识别及树引擎，prose 展开后参与相同 nullable/productive/左递归分析，空语言不被当成 epsilon。

ScalarMatchLimits 用 `max_input_scalars`，其余 work/states/depth 与现有引擎一致。输入校验先按每元素计1 work；超过上限返回 `BudgetExceeded`，不判断未检查后缀为有效。非法限额先返回 InvalidLimits，超输入长度先返回 input-scalars，不先遍历输入。方法同步执行、不调用用户回调、不复制或保留输入数组；没有不计费的整段拷贝。编译节点预算包括绑定定义、每次使用的展开副本和原文法节点，因此绑定复制较多时需要明确提高 `ParseLimits.max_nodes`，不能无限展开。

`ScalarProgram.recognize` 返回 `Result[MatchReport, ScalarInputError]`；`parse_input` 返回 `Result[ScalarInputTreeReport, ScalarInputError]`。所有输入 offset、start/end、span 都以 **scalar 索引**计；文法 source_offset/Diagnostic 仍按源文本 **字节**计。树采用单独 `ScalarInputTree`，其 `extract(Array[Int], id)` 不接受 Bytes。提取是独立辅助操作，会复制指定范围，不纳入已经结束的匹配预算；调用者应传入同一输入。匹配失败/预算耗尽不返回部分树。

没有新增 scalar 失败期待列表 API（旧诊断仍是字节型）。完整性限于支持的整数表示、所选域、有限绑定及预算内执行；不声称任意 ABNF/任意外部编码/任意自然语言 prose 可执行。

## 直接运行

```sh
# 先将 MOON_HOME 设为已有的 0.10.18+6c83a7f62 项目隔离 SDK 目录
test -n "$MOON_HOME"
export PATH="$MOON_HOME/bin:$PATH"
moon run examples/scalar_prose --target native
moon test --target native
```

`examples/scalar_prose/main.mbt` 是公开API调用者：中文问候词表 + emoji 范围 + 左递归，识别并提取三个 scalar。源文法是自制，不复制规范示例。

## 验证范围

`scalar_prose_test.mbt` 全部使用公开包API：Int32数字边界、Bytes兼容、emoji/中文、跨surrogate范围、非法scalar/误UTF16、ASCII折叠、精确名称/空名/重复/未使用/未绑定、嵌套词表变异、epsilon与空语言、歧义终点、树结构和精确预算。实现者另编写121个三符号输入与独立算法的状态扫描器对照递归绑定语言，此项不是另一agent的独立审查。独立AI agent另添加3组公开API反例（nullable范围递归、恰好耗尽校验预算、Kelvin符号ASCII折叠隔离与最大整数），四后端最终各86/86；实施阶段原始日志83/83保留不改。通过这些有限测试不等于数学上的无缺陷证明。完整原始命令回执保存在私有交付材料中，未随本公开树提供；本页是范围说明，不把作者记录冒充本分支远程 CI。公开测试源码可按上述命令复现，旧回执不冒充此次运行。

## CI固定工具链

三份CI流程均从TOOLCHAIN.lock读取本项目官方SDK/core URL和SHA256，经双哈希校验后只安装到新的项目内.toolchains目录，不运行latest或全局安装器。锁中校验和是此前核验的官方字节记录，不冒充供应商签名。离线安装器防护单测不等于GitHub上的真实安装/远程CI通过；此次未重复下载SDK。旧0.10.14性能数据只保留为历史。
