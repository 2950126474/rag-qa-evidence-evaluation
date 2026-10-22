# Review gates

Use review to expose decisions that require human judgment without turning every execution step into an approval request.

## Gate 1: question and fairness packet

The user reviews:

- objective and intended audience;
- exact questions and why each is tested;
- gold answers, key facts, and source anchors;
- included/excluded questions;
- platform and corpus conditions, including supplements;
- scoring and citation rules;
- configuration differences that may affect fairness;
- cost, data, and external-mutation boundaries.

After acceptance, label the set `fixed-for-this-batch`. Do not call it frozen before acceptance.

## Gate 2: pilot evidence unit

The user reviews one completed cross-platform question:

- whether the screenshots make the result understandable;
- whether the source and chunk/retrieval evidence explain the cause;
- whether the simple report is presentation-ready;
- whether the detailed report preserves enough technical evidence;
- whether missing screenshots produce clear acquisition instructions.

After acceptance, apply the same layout to the remaining approved batch without per-question approval.

## Gate 3: exceptions and claims

The user reviews:

- disputed gold answers;
- results affected by changed conditions, retries, or cache;
- missing UI evidence;
- high-risk unsupported additions;
- provisional failure-layer diagnoses;
- comparative conclusions and wording intended for management.

Do not finalize a claim that depends on an unresolved exception.

## Continue without asking

Within an already approved batch, continue through ordinary question execution, evidence capture, scoring under the accepted rubric, report updates, and safe troubleshooting that does not change test meaning.

## Pause for a new decision

Pause when the next action would:

- upload, delete, replace, or reprocess source data beyond the accepted condition;
- change prompts, models, retrieval settings, supplements, or scoring after execution began;
- create paid retries beyond the agreed boundary;
- use a new account, credential, permission scope, or external recipient;
- overwrite first-response evidence;
- treat a disputed gold answer as final;
- weaken screenshot or provenance requirements;
- turn a case finding into a broader platform claim.

Browser or network trouble alone is not a review gate unless the user has asked to stop. Preserve progress, try safe alternatives, and report only when the issue changes evidence quality or prevents completion.
