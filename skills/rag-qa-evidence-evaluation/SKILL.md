---
name: rag-qa-evidence-evaluation
description: Design, execute, audit, and report evidence-backed knowledge-base or RAG question-answer evaluations across one or more platforms. Use for formal QA test sets, fair cross-platform comparisons, answer/retrieval/citation/chunk analysis, screenshot evidence collection, failure-layer diagnosis, or presentation and detailed evaluation reports. Do not use for deployment, upgrades, server troubleshooting, permissions/SSO/backup governance, casual one-off questions, or document summarization.
---

# RAG QA Evidence Evaluation

Use this skill to make every comparative conclusion traceable from question to source, platform response, and the evidence needed for that conclusion. Do not confuse traceability with taking a screenshot of every ordinary result.

## Establish the evaluation contract

Before a formal batch, record:

- platforms and versions;
- corpus condition and whether supplements are present;
- question-set version and included/excluded questions;
- configuration snapshot relevant to retrieval and generation;
- isolated-session, cache, retry, and first-result policy;
- scoring rule, cost boundary, and authorized operations.
- screenshot policy: `decisive` or `exhaustive`.

Keep changing facts in the batch records, not in this skill. Hold declared conditions stable within one batch. If a material condition changes, create a new batch or label the result non-comparable.

Use status language precisely: `draft`, `ready-for-review`, `fixed-for-this-batch`, `executed`, `evidence-complete`, and `reported`. Call a set “frozen” only after the user has reviewed and accepted it. Prefer “本轮固定” in nontechnical reports.

Read [formal-evaluation-protocol.md](references/formal-evaluation-protocol.md) when designing or executing a formal batch.

## Pass three review gates

1. Review the questions, gold answers, source anchors, fairness conditions, and scoring rule.
2. Complete one representative question end to end and review its evidence layout and both report formats.
3. Review exceptions, missing evidence, disputed gold answers, and claims before final reporting.

Once the user approves a whole batch, do not request approval for every question. Pause only when a decision would materially change comparability, meaning, cost, permissions, or data safety. Read [review-gates.md](references/review-gates.md) when deciding what the user must review.

## Preserve independent first results

- Use a new isolated session for every platform-question formal observation.
- Preserve the first complete response and its session identifier or URL.
- Do not overwrite a first response with a retry or follow-up.
- Record cold-start, cached, retried, and repaired results as different observations.
- Do not silently change prompts, models, retrieval settings, corpora, or supplements inside a batch.

External authorization remains scoped: permission to run a batch does not authorize uploads, deletions, account changes, configuration changes, or paid retries beyond the accepted boundary.

## Build one evidence unit per question and platform

Always preserve the traceable core:

- exact question and gold answer with source anchor;
- raw first answer, session ID or URL, timestamp, and elapsed time when available;
- retrieved passages, ranking, citations, chunks or knowledge points when exposed;
- source-page evidence;
- verdict, key-fact hits, citation status, failure layer, and permitted conclusion.

Choose and record one visual-evidence policy for the batch:

- `decisive` (default): require answer screenshots for failures, partial results, disputed or surprising outcomes, material cross-platform differences, and examples used in a presentation or management claim. Require retrieval/chunk screenshots only when they support a failure-layer diagnosis or a processing difference. Equivalent ordinary passes may rely on preserved raw answers and session links. Reuse one source-page screenshot across questions and platforms that share the same anchor.
- `exhaustive`: require the declared screenshots for every platform-question observation when audit, acceptance, regulation, or the user explicitly requires full visual coverage.

Mark every screenshot field as `captured`, `not-required`, `not-exposed`, `capture-blocked`, or `missing`. `not-required` is valid only under the declared `decisive` policy. For required UI evidence that cannot be captured, record the exact reason and acquisition instruction.

API evidence does not become a fabricated UI screenshot. If required UI capture is unavailable, preserve the API response, mark the field `not-exposed` or `capture-blocked` as appropriate, and tell the user exactly which page to open and what must be visible when acquisition is possible.

Read [evidence-and-scoring.md](references/evidence-and-scoring.md) before scoring, diagnosing failures, or claiming one platform is better.

## Diagnose without overclaiming

Separate these outcomes:

- parsing or extraction loss;
- correct content absent from retrieval candidates;
- correct candidate excluded by ranking or filtering;
- correct evidence present but answer generation fails to use it;
- answer correct but citation missing, wrong, or unverifiable;
- cache or session contamination;
- ambiguous or unsupported gold answer.

State the narrowest layer supported by evidence. When internal traces are unavailable, report the supported range of causes and the missing observation needed to distinguish them.

## Produce two linked reports

- **Presentation report:** why the question was tested, correct answer, results for each evaluated platform, only the decisive screenshots, plain-language cause, and one-line conclusion.
- **Detailed report:** batch contract, full raw evidence and session links for every observation, required visual evidence under the declared policy, retrieval/chunk evidence, source anchors, scoring, failure diagnosis, gaps, and claim limits.

Every comparative claim must point to the evidence unit and relevant images. A table is an index, not a substitute for evidence. Use the templates in `assets/` rather than inventing a new structure for each batch.

## Optional deterministic helpers

The bundled PowerShell helpers currently target Windows. They are optional: on other operating systems use the Markdown templates and preserve the same records manually. They neither connect to RAG platforms nor execute questions or score answer correctness. No specific browser or connector is required; use available authorized tools, or collect user-provided exports when platform access is unavailable.

- Run `scripts/initialize-evaluation-batch.ps1` to create a neutral batch structure and evidence manifests. It creates local files only and never contacts a platform.
- Run `scripts/validate-evidence-batch.ps1` before reporting. It reads the batch screenshot policy. Use `-RequireScreenshots` only as an explicit compatibility override for exhaustive visual coverage.

Interpret `valid` with `validation_scope`: a draft can pass structural checks while observations remain unrun. Only `evidence_complete: true` indicates that the final-evidence checks passed for an `evidence-complete` or `reported` batch. It does not verify scientific correctness of the answers, screenshot contents, authenticity of evidence, or whether every decisive case was correctly marked as requiring a screenshot. Those require review; the boolean reports only the implemented checks. Final batches must reject unrun observations, unfinished question placeholders, missing objective/scoring rules, pending gold answers and unavailable required screenshots. An `executed` batch may still have evidence gaps but cannot contain unrun observations.

Do not store API keys, tokens, cookies, passwords, current platform IDs, live URLs containing secrets, or transient scores in this skill.
