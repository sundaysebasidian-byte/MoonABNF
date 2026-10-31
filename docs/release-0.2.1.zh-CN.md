# MoonABNF 0.2.1

0.2.1 是保持 0.2.0 公共 API 的补丁版本：可复现的精确 registry JS 协议消费者、模板和黄金快照绑定、workspace 替换防护、五次独立进程测量工具及准确评审材料。没有新增解析算法或 JSON 根包 API。

```sh
moon add sundaysebasidian-byte/moonabnf@0.2.1
```

核心输入派生树、字节 span、字段提取与预算语义保持不变。JSON 协议记录是复制 integration/protocol_consumer 模板的 JS 应用适配；实际消费可用 `scripts/registry_protocol_record_test.py --release-version 0.2.1 --output /new/external/evidence` 复现，不使用 workspace/path 依赖。CI 在发布前继续检查已有 0.2.0；新版本 registry 消费必须在正式发布后单独核验。

五进程数字来自固定 Mac 的本地测量，缓存为暖，不能改称远端 CI 性能、p95 或跨实现优势。AI 复审不是外部人类认可。历史 0.2.0 发布证据和初次失败保留原日期，不冒充本次发布回执。

## 已完成的发布核验（2026-10-25）

[版本 PR #6](https://github.com/sundaysebasidian-byte/MoonABNF/pull/6) 已合并，发布提交为 `5287ea18e897447add87b3032370c8434617cfad`。该提交的[核心验收](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40166229117)及[Fresh clone](https://github.com/sundaysebasidian-byte/MoonABNF/actions/runs/40166229123)成功。官方 CLI 发布退出0并返回HTTP 200，registry metadata为0.2.1、build_status为success；[精确版本页面](https://mooncakes.io/docs/sundaysebasidian-byte/moonabnf@0.2.1/)。

官方ZIP SHA256：`4c4612298fc05674caadcaeb4c5dcc22457f983d11184a5fb58b0b98f4a289ff`。全新消费者使用registry依赖、没有workspace/path覆盖，安装的130个包文件与ZIP一致；核心四后端及JS协议记录黄金、拒绝/预算/配置退出0/1/3/2通过。后者是复制的应用示例，不是根包JSON API。这些是已完成发布轮的回执，不表示本地开发分支获得新远端CI。

后续开发的`diagnose_input`、CLI诊断及扩展模板**不在0.2.1**；源码用法见[README](../README.md#未发布源码有界输入失败解释)。旧草稿、0.2.0消费者和性能数据保留原提交/日期；不能把它们改记为新版本实测。
