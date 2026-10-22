# Formal evaluation protocol

Use this protocol for a batch whose results may enter a comparison, decision, presentation, or durable project record.

## 1. Declare the batch

Record the following before execution:

| Field | Required decision |
|---|---|
| Objective | What capability or failure mode the batch tests |
| Platforms | Product, deployment, and version where known |
| Corpus | Exact documents, formats, revisions, checksums where practical |
| Corpus condition | Original-only, normalized, supplemented, OCR-enhanced, or another declared condition |
| Questions | Version, IDs, inclusions, exclusions, and reason for exclusions |
| Configuration | Parser, chunking, embedding, reranker, Top N, thresholds, model, prompt, and other exposed settings |
| Sessions | New-session and cache policy |
| Result policy | Preserve first result; define allowed retries and how repeats are labeled |
| Scoring | Gold-answer status, key facts, pass rule, citation rule, and risk handling |
| Screenshot policy | `decisive` for material differences and claims, or `exhaustive` for every observation |
| Boundaries | Authorized uploads/configuration changes, cost ceiling, stop conditions |

If a platform hides a setting, record `not exposed` rather than guessing.

## 2. Prepare question records

Each question record contains:

- stable question ID;
- exact user wording;
- why the question is diagnostic;
- gold answer and its review status;
- atomic key facts;
- exact source anchor: document, page, table/figure/section, and nearby text where useful;
- pass, partial, and fail conditions;
- citation expectation;
- safety or interpretation risk.

Do not score a disputed gold answer as final. Mark it `gold-answer-pending` and route it to Review Gate 3.

## 3. Establish comparability

Prefer the same source documents and semantically equivalent question wording. Do not describe results as a fair platform comparison when one platform has a structured supplement and another has only the original document, unless the batch objective is specifically to test that enhancement.

When parser or chunking behavior is part of the evaluation, record each platform's actual processing rather than forcing identical chunks. Fairness means equivalent inputs and declared conditions, not identical internal implementation.

## 4. Run a pilot evidence unit

Complete one representative question across all platforms before a large batch. Capture answers, retrieval/citations/chunks, source evidence, screenshots required by the declared policy, and preliminary diagnosis. Review the presentation and detailed layouts. The pilot validates the evidence workflow, not platform performance.

## 5. Execute formal observations

For every platform-question pair:

1. Start a new isolated session.
2. Submit the exact fixed question.
3. Wait for the first complete response.
4. Preserve raw answer and session identity before any follow-up.
5. Preserve the answer page URL or session identity for every observation.
6. Capture answer UI evidence when required by the batch screenshot policy.
7. Preserve retrieval, citation, chunk, or knowledge-point data exposed by the platform; capture its UI when needed to explain a diagnosis or when exhaustive coverage is declared.
8. Mark non-required and unavailable visual fields explicitly; create a precise acquisition task only for required evidence that is blocked.
9. Do not repair the answer inside the formal observation.

A retry is a new observation. A corrected answer after a follow-up does not replace the first result.

## 6. Diagnose and score

Score key facts and unreserved correctness separately. Check citation correctness separately from answer correctness. Then locate the narrowest supported failure layer using the evidence chain.

Do not infer parsing loss merely because an answer is wrong. First check whether the source content appears in the platform's chunks, retrieval candidates, selected context, or citations.

## 7. Complete evidence and report

Run the evidence validator. Resolve all errors before calling the batch `evidence-complete`. Under `decisive`, intentionally omitted screenshots for equivalent ordinary passes are not evidence gaps when marked `not-required`. Required but blocked screenshots may remain in an executed batch only when clearly labeled, linked to preserved raw evidence, and assigned as acquisition tasks.

Generate the presentation and detailed reports from the same evidence units. The presentation report may simplify language, but it may not strengthen conclusions or omit exceptions that change meaning.
