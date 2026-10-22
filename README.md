# RAG QA Evidence Evaluation

让知识库问答评估的结论能追溯到原始问题、标准答案、首次回答、引用和检索证据的 Codex skill。

A Codex skill for evidence-backed RAG and knowledge-base QA evaluations across one or more platforms. Includes report templates and optional Windows PowerShell helpers.

## 适合什么任务

- 设计一组正式测试问题，明确标准答案和评分规则。
- 在相同文档和声明的配置条件下比较不同平台，或评估单个平台。
- 分别分析答案正确性、引用质量、检索与文档处理问题。
- 保留首次回答，整理汇报版和详细证据版报告。

它不是自动评分服务，不包含平台账号、连接器或浏览器。是否能直接执行测试，取决于当前 Codex 可用的工具和平台权限。无法访问平台时，可以先设计测试或整理已有导出记录。日常问答、文档摘要、部署和服务器排错不属于本 skill 的用途。

## 安装

在支持技能安装的 Codex 中输入：

> 请用 skill-installer 安装 GitHub 仓库 2950126474/rag-qa-evidence-evaluation 中的 skills/rag-qa-evidence-evaluation。

也可以把该文件夹复制到 `$CODEX_HOME/skills/`；未设置 CODEX_HOME 时使用 `~/.codex/skills/`。已有同名 skill 时先比较、备份，不要直接覆盖自己的修改。安装后新开一个对话。

这是独立公开副本，不会自动同步作者的自用版本。

## 怎么用

设计测试：

> 用 $rag-qa-evidence-evaluation 帮我设计知识库问答评估。我们有两个平台、相同的产品手册，先选 5 个问题，给出标准答案、出处和评分规则，供我确认。

分析已有记录：

> 这是两个平台的首次回答和引用记录。请检查哪些结论有证据支持，哪些只能作为猜测，并整理详细报告。不要重新执行测试。

执行已确认的批次：

> 问题集和评分规则已经确认。请先完成一个代表性问题的测试和证据记录；沿用现有知识库，不上传或替换文档。

正式评估包含问题与公平性审阅、一个问题的试跑、最终异常和结论审阅。已经批准的批次不需要逐题重复确认。脚本创建的文件只是草稿，不代表平台测试已经完成。

## 证据策略

默认 `decisive`：保存每次原始回答和会话标识，仅对失败、部分正确、有争议、显著差异、用于汇报的案例等保留必要截图。

`exhaustive`：辅助校验器要求每个观察记录的答案、检索、来源三类截图。平台不提供其中某类界面时，不能声称满足此完整截图要求；应如实保留缺口。不要用 API 输出伪造 UI 截图。

标准答案、评分和截图必要性需要人工或模型结合源文档审阅。单个案例不能证明某个平台普遍更好。

## 可选辅助脚本（Windows）

脚本目前面向 Windows PowerShell / PowerShell on Windows；本次在 Windows 上验证。其他系统可以使用同样的 Markdown 模板手动保存记录，尚未承诺脚本跨平台兼容。

在仓库根目录的 PowerShell 中执行：

```powershell
& ./skills/rag-qa-evidence-evaluation/scripts/initialize-evaluation-batch.ps1 `
  -OutputRoot ./evaluation-work `
  -BatchName pilot-01 `
  -Platforms platform-a,platform-b `
  -QuestionIds Q01,Q02 `
  -CorpusCondition original-only

& ./skills/rag-qa-evidence-evaluation/scripts/validate-evidence-batch.ps1 `
  -BatchRoot ./evaluation-work/pilot-01 -Json
```

初始化脚本只创建本地目录、清单和模板，不联系平台；已有同名批次时会拒绝覆盖。平台与问题标识用英文字母或数字开头，其后可包含字母、数字、点、下划线和连字符。

填写 `batch-manifest.json` 中的目标、评分与配置，完善 `questions/` 的标准答案和出处，把实际回答及证据保存到 `evidence/`，最后从同一份证据生成 `reports/` 中的两份报告。证据路径相对于批次根目录；记录文件使用 UTF-8。

校验结果应这样理解：

| 字段 | 含义 |
|---|---|
| `valid` | 已实现的记录检查没有发现错误；草稿也可能为 true |
| `validation_scope` | 当前执行的是结构检查，还是最终证据检查 |
| `evidence_complete` | 批次声明为 evidence-complete/reported，且通过已实现的最终检查 |

校验器检查部分必填字段、文件存在性、状态和截图要求，**不验证答案正确性、图片内容、记录真实性，也不会自动判断所有该截图的案例**。该字段不能替代证据审阅。错误时退出码为 1；无错误时为 0。格式损坏或缺少结构字段时可能直接抛出错误，而非返回 JSON。

## 验证与限制

仓库包含仅使用临时合成记录的回归测试，不调用真实平台：

```powershell
python -m unittest discover -s tests -v
```

默认使用 `pwsh`。若使用其他 PowerShell 可执行文件，将其完整路径设置到 `SKILL_TEST_PWSH` 环境变量。测试所需 Python 仅使用标准库；技能本身不依赖 Python。

发布前检查技能格式、初始化与校验脚本，以及草稿/未执行/缺失回答/待定标准答案/截图缺口等场景。触发与非触发边界经过规则审阅，未进行独立模型行为评测，也未以这个公开副本完成真实平台端到端评估。

## 反馈与许可

欢迎在 [Issues](https://github.com/2950126474/rag-qa-evidence-evaluation/issues) 分享问题和改进建议。请使用脱敏的最小案例，不上传私有知识库、账号凭据或带访问令牌的会话链接。

[MIT License](LICENSE)
