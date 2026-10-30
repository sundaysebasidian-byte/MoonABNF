# MoonABNF 复审逐条回应与兼容目标

状态：AI辅助起草，供本人理解、核对并人工最终定稿；未提交。依据官方意见“拒绝合法左递归文法，不符合标准完整兼容目标；需补充兼容目标或详细说明”，不扩写为官方承诺。

## 1. 关于拒绝合法左递归

原版本的递归下降实现在编译阶段拒绝直接、间接和可空前缀左递归。这是实现限制，不是ABNF对合法文法的限制；原申报将其作为终点不准确。新候选使用有限输入上的单调最小不动点，按规则与起点积累终点直到稳定，不要求使用者手工消除左递归。输入树保留一个有限见证，按出现次数展开，避免可空见证复用产生多父节点。无有限终结推导的闭合规则作为空语言接受，而非判非法。

## 2. 关于标准兼容目标及新增实际实现

目标是依据 RFC5234/RFC7405 支持闭合ABNF文法的语法和匹配语义，不把预算/表示限制作为标准合法性的结论。

- 原 `parse` / `compile` / Bytes API保留0..255域及现有调用契约。
- 新 `parse_numeric` 能保留非字节数值终结符（0..2147483647，Int32表示上限）；它是编码无关AST，不将所有数值当成Unicode。
- 新 `compile_scalar` 返回独立ScalarProgram，识别显式Unicode scalar数组并生成ScalarInputTree，跨度按scalar计。拒绝surrogate、负数、超10FFFF输入；范围跨surrogate时只匹配有效scalar。没有自动UTF解码/归一化。
- 新 `compile_with_prose` / `compile_scalar(..., bindings=...)` 提供精确命名的有限词表与单符号范围谓词绑定，并支持Concat/Alternative/Repetition的语言组合（详见COMPOSED_PROSE_20261030.md）。未绑定、重复绑定、非法值显式报错；epsilon与空语言区分；编译拷贝并计展开预算。绑定参与同一可空/生产性/左递归固定点，不猜自然语言。

这些已实现内容不是通用可执行predicate callback：任意外部编码、无限整数、任意自然语言prose解释仍未提供。RFC5234将外部编码与语法分开，Unicode scalar仅是本实现明确选择的一个应用域。完整契约及运行例子见[增量说明](SCALAR_PROSE_EXTENSION_20261030.md)。

## 3. 验证与保留限制

当前组合prose候选四后端 native/js/wasm/wasm-gc 各 **90/90**，独立native/JS加3组反例后各 **93/93**。前序scalar/prose阶段各 **86/86**。实施阶段83组之后，另一独立AI agent追加3组反例并重新运行四后端；完整日志与原始审查回执保存在私有交付材料，不是公开仓库中的相对路径；这些本地结果不等于远程CI。实施者另写121输入状态扫描器对照（不是另一agent的独立审查）。四后端 `moon check --deny-warn` 及公开API示例实际运行均通过。

左递归前序候选的73组及干净副本73组属于历史证据；前序独立审查含1,364个等价文法输入与127个括号语言输入，并通过AST回放检查树。曾发现可空见证共享破坏树结构，已修复并回归。前序结果不冒充新增scalar/prose验证；有限测试不等于完整标准认证。

预算耗尽返回未判定，不伪称无匹配。左递归失败的局部期待解释尚未实现，scalar也未提供期待列表诊断；不枚举全部歧义树、不提供流式识别。全局左递归标志仍可能使不可达左递归影响路径、预算和解释能力。实现不是高性能通用Earley/GLL的证明，不保证任意大输入预算内完成。

## 4. 版本绑定与复现

公开基线 `7daa6aa1c523c74a906a87b1bc1271892bccd02e`；已验证功能源码基线为 `c89f80421b9591cb9117e1494e150e87370314fa`；本次仅文档与清单修订，新能力属于当前源码候选，非Mooncakes0.3.0。旧冻结包保留，不覆盖；文件哈希见根目录 `FINAL_CONTENT_SHA256.json`（明确排除清单自身，不作自引用），包哈希由交付回执另列，避免自引用。

本次确有算法/API/测试增量；使用已批准隔离SDK **0.10.18+6c83a7f62**。设置MOON_HOME/PATH后执行 `moon check --target native --deny-warn`、`moon test --target native`、`moon run examples/scalar_prose --target native`；其余目标替换为js、wasm、wasm-gc。无需新增库依赖。

来源：[RFC5234](https://www.rfc-editor.org/rfc/rfc5234.html)、[RFC7405](https://www.rfc-editor.org/rfc/rfc7405.html)、[Unicode scalar定义](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/)。是否接受修订由评审决定。
