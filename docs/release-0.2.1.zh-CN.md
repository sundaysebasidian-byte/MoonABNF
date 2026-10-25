# MoonABNF 0.2.1

0.2.1 是保持 0.2.0 公共 API 的补丁版本：可复现的精确 registry JS 协议消费者、模板和黄金快照绑定、workspace 替换防护、五次独立进程测量工具及准确评审材料。没有新增解析算法或 JSON 根包 API。

```sh
moon add sundaysebasidian-byte/moonabnf@0.2.1
```

核心输入派生树、字节 span、字段提取与预算语义保持不变。JSON 协议记录是复制 integration/protocol_consumer 模板的 JS 应用适配；实际消费可用 `scripts/registry_protocol_record_test.py --release-version 0.2.1 --output /new/external/evidence` 复现，不使用 workspace/path 依赖。CI 在发布前继续检查已有 0.2.0；新版本 registry 消费必须在正式发布后单独核验。

五进程数字来自固定 Mac 的本地测量，缓存为暖，不能改称远端 CI 性能、p95 或跨实现优势。AI 复审不是外部人类认可。历史 0.2.0 发布证据和初次失败保留原日期，不冒充本次发布回执。

版本 PR 为 [#6](https://github.com/sundaysebasidian-byte/MoonABNF/pull/6)。准确 head、合并记录及远端检查以该 PR 和 Actions 实际回执为准；正式包版本与 checksum 以 [Mooncakes](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf) 为准。本说明不代替 registry 上传及全新消费者回执，不包含比赛提交或获奖承诺。
