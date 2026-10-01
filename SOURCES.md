# 来源与许可清单

| 来源 | 链接/位置 | 用途与参考范围 | 许可/处理 |
|---|---|---|---|
| RFC 5234, D. Crocker / P. Overell, January 2008 | https://www.rfc-editor.org/info/rfc5234/ | 完整阅读；规则名、操作符、CRLF/c-wsp、数值终端、core 语义 | IETF Trust / BCP 78；自己的算法实现，不打包 RFC 原文或抽取的 ABNF 文本 |
| RFC 7405, P. Kyzivat, December 2014 | https://www.rfc-editor.org/info/rfc7405/ | 完整阅读；%s/%i 与默认字符串匹配语义 | IETF Trust；不把 RFC 原文作为 MIT 重新分发 |
| IETF Trust Legal Provisions | https://trustee.ietf.org/documents/trust-legal-provisions/tlp-5/ | 核对文本引用与 Code Components；旧 RFC 适用其发布日期条款 | 若未来抽取 RFC grammar/Code Components，须单独保留归属及适用 BSD 文本，不默认整体 MIT |
| MoonBit core bundled with locked SDK | https://github.com/moonbitlang/core | builtin、debug、env、json 等 API；读取 API/FFI 形状，不移植标准库源码 | Apache-2.0 及 NOTICE；原样保留在 licenses/ |
| MoonBit package documentation | https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html | JS 专用 CLI、CommonJS link 配置 | API 文档参考，无复制正文 |
| Python standard library re | https://docs.python.org/3/library/re.html | 独立字节正则 oracle；无第三方 Python ABNF 包 | Python 自身许可，无 Python 源码打包 |
| Mooncakes module search | https://mooncakes.io/ | 2026-09-30 abnf、bnf 两次有界站内核查 | abnf 仅返回 marianoguerra/uri@0.1.2 字符编码表；bnf 无结果；不是全生态穷尽证明 |
| marianoguerra/uri | https://mooncakes.io/docs/marianoguerra/uri@0.1.2/enc | 只读摘要对比范围 | 未复制代码，未作为依赖或 fixture 来源 |
| 用户先前 LogLens CI | 本机只读既有配置 | 核实已经使用的官方固定版安装参数与 SDK 来源 | 未修改 LogLens，未复制其功能或 fixtures |
| 本项目 fixtures 与例子 | fixtures/、examples/、scripts/differential.py | AI 辅助自制协议/配置/二进制例子，无真实业务或个人数据 | 本项目 MIT，未抽取第三方测试集 |

标准语义的功能重实现与第三方原文抽取有区别。这里不附 RFC 原文、标准示例长段落或
第三方 ABNF fixtures；不是其他 ABNF 库的源码移植。发布二进制时继续携带标准库及依赖
许可证/NOTICE，并核对最终构建组件；当前交付为源码及自制材料。
