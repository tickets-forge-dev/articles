# A measured positive Jev use case: account-closure intent

## Defensible claim

In this tested integration, Jev classified a batch of ten customer queries **14.46× faster than the GPT-5.6-Luna implementation and 16.67× faster than the GPT-5.6-Sol implementation**, with the same observed exact-label accuracy. Its published API-price-equivalent cost was **86.64% lower than Luna and 99.32% lower than Sol** using actual reported usage and cache hits.

The useful task is small: **does the customer want to close their banking account?** A positive label flags a request for a human support queue. It does not authorize or execute account closure, answer the customer, or replace a general coding/reasoning model.

This is not evidence that Jev improved the earlier 40-file coding workflow. The article, images, reading preview and upload bundle were not changed during these experiments. After the experiments passed, the user requested a final publication version using the account-closure result; that later rewrite does not change the frozen data, predictions or protocols.

## Comparison table

| Classifier implementation | Correct evaluation decisions | Unique held-out queries | Median ten-query batch | API-price-equivalent / 100 queries |
| --- | ---: | ---: | ---: | ---: |
| Jev 1.13.0, TypeSafe HTTP API | 180 / 180 | 60 | **0.3014 s** | **$0.00110453** |
| GPT-5.6-Luna, persistent minimal Codex adapter | 180 / 180 | 60 | 4.3574 s | $0.00826793 |
| GPT-5.6-Sol, persistent minimal Codex adapter | 180 / 180 | 60 | 5.0237 s | $0.16199067 |

The sixty queries were evaluated three times per model for timing variability and consistency. **180 repeated decisions are not 180 independent queries.** Every model also classified all forty calibration queries correctly. No human fallback was needed in this sampled evaluation.

Observed ten-query batch ranges were Jev 0.2791–0.4437 s, Luna 2.9580–7.5236 s, and Sol 3.8032–10.0286 s. These are descriptive timings in the measured setup, not a universal speed guarantee.

## Actual data, not a fabricated customer story

Source: [PolyAI BANKING77](https://github.com/PolyAI-LDN/task-specific-datasets), from Casanueva et al., [Efficient Intent Detection with Dual Sentence Encoders](https://arxiv.org/abs/2003.04807), 2020. License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See the [dataset card](https://huggingface.co/datasets/PolyAI/banking77/raw/main/README.md).

The unchanged public query text and original intent label were retained. Our documented adaptation maps `terminate_account` to `closure_request` and every other published intent to `not_closure`. This is binary recommendation accuracy, **not a full 77-intent benchmark score**. Pretraining exposure to this public benchmark is unknown for every model.

- Calibration: forty queries from the official training split, twenty positive and twenty negative.
- Evaluation: sixty previously unused queries from the official test split, thirty positive and thirty negative.
- Two-thirds of negatives were sampled from cancellation/card/access hard-negative intents; the remainder from other non-closure intents.
- Fixed seeds, original CSV row IDs and expected labels were frozen before these predictions. Exact text duplicates were excluded across calibration/evaluation.
- Every query previously transmitted in the unsuccessful coarse-routing experiment was excluded from this new cohort. The cohort was not selected by looking for successful model answers.

The source files contain 10,003 training and 3,080 test rows; exact downloaded CSV snapshots and SHA-256 values were retained. Raw label checks confirmed that the original texts and labels were unchanged.

## Same job and same semantic evidence

Each measured request classifies ten queries. Both LLMs and Jev receive the same ten texts and the same two answer descriptions:

- `closure_request`: the customer wants to close, delete, terminate or deactivate their banking/service account, or asks how to do so.
- `not_closure`: no account-closure request. Cancelling a transfer/payment, blocking/reactivating a card, recovering a passcode, deleting an app, requesting a refund or having a rejected transaction is not account closure.

Jev uses ten Choice questions over one shared state, with each question explicitly pointing to its own query. The LLM receives the same texts/descriptions and a JSON schema mapping each query ID to one label. Neither receives source intent labels, expected answers, or calibration examples in the inference request. No model tools or banking actions were allowed.

The predeclared calibration procedure selects the greatest automatic coverage with at least 95% observed calibration precision, from a fixed confidence grid. All forty calibration predictions were correct; the frozen selected cutoff was **0.0**, meaning ordinary top-choice classification for this low-risk recommendation task. The held-out cohort was evaluated only afterward. This is not a production confidence guarantee and does not justify lowering the earlier file-screening threshold on that task.

All six execution orders of the three implementations were used, repeated three times across the six evaluation batches. Each model occupies each execution position equally. Requests are sequential between implementations, not raced against each other.

## Timing and the LLM adapter limitation

The LLMs were called through an authenticated, persistent Codex app-server 0.146.0 connection, with an isolated temporary configuration, minimal classification instructions, low reasoning, requested default service tier, and unrelated tool/plugin/memory features disabled. CLI startup, authentication setup and calibration are **outside the measured evaluation calls**. Each LLM call uses a fresh ephemeral thread.

The clock covers the classification request and returned structured answer. Median server-emitted turn durations were 4.3500 s for Luna and 5.0165 s for Sol—almost identical to their total measured calls. The latency difference is not simply charging the LLM for launching a new CLI on every request.

However, Codex still supplies framework/system context. Measured LLM input includes it. We did **not** measure a bare OpenAI API request with a minimal standalone classifier prompt. These timings and dollar equivalents must be attributed to the **tested integrations**, not presented as pure-model inference measurements or universal Jev-versus-LLM performance.

The returned Jev model was `jev-1.13.0`. The LLM adapter reported the requested model family identifiers, not immutable backend snapshots. Actual billing/service tier was not returned; default tier was requested. Future models, queueing and implementation choices can change these results.

## Price accounting and cache controls

The existing Codex authentication uses a ChatGPT subscription. No LLM API invoice was measured. **Every dollar figure is a standard API-price equivalent, not actual paid spend, not a lower ChatGPT subscription bill, and not a claim of marginal subscription savings.** Jev's price estimate also uses reported token usage and the published rate, not an invoice.

Verified public rates per million tokens:

| Model | Input | Cached input | Cache writes | Output |
| --- | ---: | ---: | ---: | ---: |
| Jev 1.13.0 | $0.042 | Not assumed | Not assumed | Free |
| GPT-5.6-Luna | $0.20 | $0.02 | $0.25 | $1.20 |
| GPT-5.6-Sol | $4.00 | $0.40 | $5.00 | $20.00 |

Sources: [TypeSafe models](https://docs.typesafe.ai/models), [OpenAI pricing](https://developers.openai.com/api/docs/pricing). All requests are short context. Actual cached-input counts are retained; no cache reset/isolation was claimed. No cache-write tokens were reported. Output charges include reported reasoning output where present, rather than counting only visible JSON.

The cost formula is `(uncached input × input rate + cached input × cached rate + cache writes × write rate + output × output rate) / 1,000,000`. Jev costs `reported input × 0.042 / 1,000,000`.

Normalized /100-query equivalents use the total actual costs divided by the total scored decisions, multiplied by 100. Calibration calls are not included in steady-state evaluation costs.

The result survives two explicit cache sensitivity calculations:

| Input-cache scenario | Jev estimate /100 | Luna estimate /100 | Sol estimate /100 |
| --- | ---: | ---: | ---: |
| Recorded cache hits | $0.00110453 | $0.00826793 | $0.16199067 |
| No LLM input cached | $0.00110453 | $0.01105833 | $0.27104667 |
| All LLM input cached | $0.00110453 | $0.00201123 | $0.04078467 |

With **all** LLM input treated as cached, Jev's equivalent cost remains **45.08% lower than Luna and 97.29% lower than Sol in this adapter**. These cache scenarios are modeled from the measured token counts, not additional measured cache conditions.

A stronger sensitivity bound exists for the expensive Sol baseline: even charging **zero for every Sol input token**, its measured output tokens alone have a $0.01520 /100-query price equivalent, above Jev's complete $0.00110453 estimate. That cost advantage cannot be explained away solely by extra LLM input/framework context. This output-only bound does not hold for Luna, and the report does not pretend it does.

## Deterministic control and negative experiments

An exploratory, untuned keyword control (`account` plus a closure/cancellation verb) got **55 / 60** held-out queries correct. Its errors were simple wording/plural misses; extending it might solve this sampled cohort. This is not evidence that Jev is necessary or that all deterministic methods are inferior. The primary result compares three model-based implementations, not an optimized deterministic classifier.

Earlier negative results are retained, not hidden:

1. `../benchmark-2026-10-04/`: conservative Jev file screening retained all forty files and did not improve median complete-workflow speed.
2. `../routing-comparison-2026-10-04/`: the broad five-queue mapping failed its quality gates. It also exposed a bad label-to-queue assumption: sampled `get_physical_card` queries ask for a PIN, not card shipping. No positive claim is taken from that experiment.

The new binary task and cohort were frozen separately before its model predictions. The positive account-closure result must not be retroactively credited to those earlier tasks.

## Additional boundary smoke

After the primary run, thirty authored cases tested negation, account versus card/app cancellation, quoted requests, past closure, reopening, and cancelling a scheduled closure. The same rubric and previously selected cutoff of 0.0 were retained. No calibration or threshold tuning occurred.

All three models returned the expected label on all thirty cases in all three passes: **90 / 90 decisions per model**. Raw predictions, equal semantic inputs, token usage, costs and the unchanged article digest were independently checked. Median ten-query batches were Jev **0.3212 s**, Luna **5.0911 s**, and Sol **5.0441 s**.

These are **synthetic boundary examples**, not real customer records, and their timing/usage is not pooled into the primary BANKING77 table. They reduce concern about obvious lexical confusion in the tested examples; they do not establish production reliability. Full evidence is retained in `../account-closure-boundaries-2026-10-04/`.

## Raw proof and reproduction

- `dataset.json`: frozen calibration/evaluation cases, original intent/row IDs, criteria, seed description and source hashes.
- `protocol.json`: request contract, models, confidence grid, quality/performance gates, pricing assumptions, and original article SHA-256.
- `calibration.json`: all cutoff candidates and the frozen selected policy.
- `results.json`: all sixty-six real classification calls, raw Jev responses, LLM event streams, token/cache usage, elapsed time and label decisions. No failed/incorrect call was excluded.
- `summary.json`: exact aggregates and passing gates against both named LLM baselines.
- `verification.json`: independent source/label, input parity, price-accounting, cohort isolation and unchanged-article checks.
- `keyword-control.json`: every exploratory keyword-control decision.
- `run.log`: sequential call transcript.
- `exploration-provenance.json`: reason for the new task and preserved earlier attempts.

The harness is `scripts/benchmark-jev-routing.py`. Copy this experiment's `dataset.json` to a new output directory, set `TYPESAFE_API_KEY` privately, authenticate Codex and run the harness from the article workspace. It does not edit the article. Temporary OAuth copies are permission-restricted and removed when the adapter exits; credentials are not stored in the evidence.

## What the article can now say

**Use Jev for a small semantic decision—not as a replacement for an LLM's reasoning or writing.** In this bounded recommendation task, all three classifiers produced the same correct decisions, but Jev completed the tested request much faster and used a lower published API-price-equivalent budget.

The final article is “Jev vs. an LLM for Intent Classification,” using this account-closure case with its explicit integration/billing limits. The earlier forty-file savings story is no longer the article's claim. Raw experiment protocols and audits retain the original article digest from measurement time; a later publication manifest records the intentionally rewritten article.
