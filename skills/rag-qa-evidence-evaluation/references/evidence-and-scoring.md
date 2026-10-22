# Evidence, scoring, and diagnosis

## Evidence unit

Treat one platform's first response to one fixed question as the atomic observation. Link every observation to:

1. question record and gold-answer source;
2. platform, version, corpus condition, and configuration snapshot;
3. isolated session ID or URL and timestamp;
4. raw first response;
5. retrieval candidates, selected context, citations, chunks, or knowledge points where exposed;
6. source-page evidence;
7. visual evidence required by the batch screenshot policy;
8. verdict and failure diagnosis.

Every observation still needs a raw first answer and session identity. Under `decisive`, screenshots are required only for material differences, failures, partial or disputed results, presentation examples, and visual evidence used to diagnose a cause. Under `exhaustive`, capture the declared screenshots for every observation. Do not use a cropped screenshot that hides the question, platform identity, or decisive part of the answer. Multiple screenshots are acceptable when one image cannot show the complete evidence.

## Evidence status

- `captured`: the artifact exists and is linked.
- `not-required`: the declared `decisive` policy does not require this screenshot for the observation.
- `not-exposed`: the platform does not expose that evidence in the tested interface.
- `capture-blocked`: the evidence exists in the UI but tooling could not capture it.
- `not-applicable`: the evidence type does not apply.
- `missing`: expected evidence has neither an artifact nor an adequate explanation.

For `capture-blocked`, record the exact page/session to open, the UI element that must be visible, and the required framing. API output can support a provisional finding but does not substitute for a required UI image. Do not label an intentionally omitted ordinary-pass screenshot as blocked or missing.

## Scoring views

Always preserve two views when the gold answer contains atomic facts:

### Key-fact hit rate

`correct required facts / total required facts`

This shows partial knowledge and makes omissions visible.

### Unreserved full-pass rate

A question passes only when all required facts are correct and no unsupported qualification, contradiction, or high-risk addition changes the answer.

Use verdicts:

- `pass`;
- `partial`;
- `fail`;
- `core-pass-extra-risk`;
- `gold-answer-pending`.

Score citation separately as `correct`, `partial`, `wrong`, `missing`, or `not-exposed`.

Do not impose universal weights. Define batch-specific aggregation before execution and retain per-question evidence even when an overall score is requested.

## Failure-layer taxonomy

| Layer | Supported conclusion | Required evidence |
|---|---|---|
| Parsing/extraction | Decisive source content is absent or materially corrupted in processed content | Source page plus processed chunks/knowledge points or parser output |
| Retrieval candidate generation | Correct processed content exists but is absent from retrieved candidates | Chunk existence plus retrieval trace |
| Ranking/filtering | Correct content is a candidate but excluded from selected context | Candidate ranking and selected-context trace |
| Generation/evidence use | Correct evidence reaches answer context but the answer omits, contradicts, or refuses it | Selected context/citation plus final answer |
| Citation | Answer may be correct but citation is absent, points to the wrong place, or cannot be verified | Answer, citation target, and source anchor |
| Cache/session | A previous observation affects a nominally new run | Session history, repeated response pattern, or platform trace |
| Gold answer | The expected answer or source anchor is ambiguous, unsupported, or disputed | Source review and reviewer decision |

When a trace is unavailable, use cautious language such as “failure occurred between processed content and selected context” and list the missing evidence needed for a narrower diagnosis.

## Claim discipline

Permitted claims must match scope:

- One question supports a case finding, not a universal platform ranking.
- One document format supports that format and corpus condition only.
- A correct answer without verifiable retrieval evidence does not prove the platform used the knowledge base correctly.
- Better aggregate accuracy does not automatically prove better parsing, retrieval, citation, governance, or production fitness.
- A platform can answer correctly while citing incorrectly, or retrieve correctly while generating incorrectly; report these separately.
