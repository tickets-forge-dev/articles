# Part 4: live synthetic coding-context experiment

## Finding

This configuration did **not** demonstrate Jev context savings or faster median completion. Jev returned `skip` for the 35 distractors, but all skip confidences were below the predeclared 0.95 cutoff (observed range 0.47–0.88). The conservative fallback retained all 40 candidates. Static import filtering independently selected five files and required no model.

This is one generated task, repeated six times per arm—not six independent tasks, a production benchmark, or proof that Jev never helps. The benchmark ran on October 4, 2026. No production repository source was transmitted.

## Measurements

| Approach | Runs / successful fixes | Retained files | Coding input tokens per run | Median complete workflow | Observed range |
| --- | --- | --- | --- | --- | --- |
| Broad fixed context | 6 / 6 | 40 | 59,821 | 7.4764 s | 6.1670–8.0978 s |
| Code-only static import closure | 6 / 6 | 5 | 15,011 | 6.5562 s | 5.8321–11.0048 s |
| Jev screening, conservative retention, then coding | 6 / 6 | 40 | 59,821 | 8.6950 s | 7.7149–9.2402 s |

Jev's median complete-workflow latency was 16.30% higher than broad context; Jev was faster in only one of the six paired repetitions. These are descriptive sample statistics, not significance claims. Code-only filtering had a lower median but overlapping observed ranges; no general latency effect is established.

The median Jev screening stage was 1.6817 s for 40 requests with eight concurrent workers. Each screening run reported 36,099 Jev input tokens. At the documented $0.042 per million input tokens, the additional screening cost estimate is **$0.001516158 per run**. Jev output tokens are documented as free.

All 18 returned patches were applied to separate fresh fixture copies. Acceptance ran real Node code and checked the new invalid-credentials text, unchanged blocked/network/unknown web errors, unchanged mobile text, and the existing visible login tests. Only the intended web message file changed. The unchanged fixture failed the new-message acceptance assertion before the experiment.

## Protocol and controls

The saved [protocol](protocol.json) and [fixture](fixture.json) were written before the measured runs. The reproducible harness is [scripts/benchmark-part4.py](../../../../scripts/benchmark-part4.py).

- Task: change the web invalid-credentials message to “Email or password is incorrect”; preserve all other web errors and non-web behavior.
- Forty fixed candidates in a seeded, shuffled order: five connected web modules/tests and 35 generated, executable error-map distractors for mobile, API auth, admin, checkout, password reset, OAuth, and CLI paths. Distractor comments explicitly identify their non-web scope. This is an easy, artificial relevance problem—not representative repository retrieval.
- Full source bodies were generated, not copied from a production project. The candidate set is supplied by the harness: search discovery time and search quality were not benchmarked. Broad reading is deliberately inefficient and is not claimed to represent an optimized coding agent.
- Broad and Jev arms start from exactly the same 40 candidates. Jev sees the task, path, first 1,600 characters, and whether the excerpt is complete. Each request uses the same `keep` / `skip` / `unsure` Choice rubric.
- Two application-controlled roots—the web entry point and visible test—are pinned. Retention then expands relative JavaScript imports. This static dependency graph guarantees essential-file retention for this fixture independently of Jev. Zero missed essential files is **not evidence of Jev classifier recall**.
- Jev only drops an unpinned file for a `skip` with confidence at least 0.95. This threshold was set before measuring and was not calibrated as a production safety guarantee. Errors, uncertainty, and lower-confidence skips retain the file. No threshold was lowered after observing the negative result.
- The code-only arm uses the same static import closure from the known roots. It is an explicit alternative, not an improvement secretly credited to Jev. It finds all five connected files immediately; this task does not need a semantic classifier.
- Screening uses 40 HTTPS requests with concurrency eight, no harness retries, and real Jev responses. All 240 screening requests succeeded. Returned Jev model ID was `jev-1.13.0`.
- Coding uses authenticated Codex CLI 0.146.0, requested `gpt-5.6-sol`, low reasoning, requested default service tier, ignored user configuration/rules, ephemeral read-only sessions, and the same JSON replacement schema. Coding receives fixed source context and returns a replacement. It is not an autonomous search/edit loop. No model tool calls occurred. The CLI events do not identify a versioned backend snapshot or report actual billing/service tier.
- Six repetitions use all six permutations of the three arms, balanced so each arm occurs twice in each position. Calls run sequentially between arms; screening alone is concurrent. This reduces fixed-order effects but does not remove queueing, cache effects, or time-varying service conditions.
- The clock starts before selection and stops after coding CLI output, patch application, and Node acceptance. Timings include process launch and authentication overhead. They are neither Jev-only latency nor time-to-first-token. Synthetic fixture construction and initial failing acceptance are outside the timed region.

## Cost and caching: do not claim causal savings

Codex ran through an existing ChatGPT subscription, not an invoiced OpenAI API key. All dollar values are **public standard-rate equivalents from measured token usage**, not actual billed amounts or subscription savings.

Verified pricing references:

- [TypeSafe models](https://docs.typesafe.ai/models): Jev 1.13.0, $0.042/M input, output free.
- [OpenAI pricing](https://developers.openai.com/api/docs/pricing): GPT-5.6-Sol standard short context, $4/M uncached input, $0.40/M cached input, $5/M cache writes, $20/M output. All observed requests are below the documented 272K-input long-context boundary. No cache-write tokens were reported.

The harness calculates:

`((input − cached − cache_writes) × 4 + cached × 0.4 + cache_writes × 5 + output × 20 + Jev_input × 0.042) / 1,000,000`.

Observed-cache median estimates (including Jev where used) were broad **$0.2167528**, code-only **$0.061284**, and Jev **$0.134673758**. The smaller Jev median is **not a demonstrated screening saving**: its coding prompt remained identical to broad context, but it received more cache hits. Broad had two near-full prompt cache hits; Jev had three. Neither cache reset nor isolation was attempted, and repeated identical broad/Jev prompts could reuse each other's cached work. Do not turn these medians into a percentage-savings headline.

Coding input tokens include the CLI's system context and formatting. They are not the article's illustrative file-only 80,000→10,000 budget. Jev's tokenizer is separate; its 36,099 input tokens cannot be treated as coding-model tokens.

## Inspectable raw evidence

- [Summary](summary.json): medians, ranges, cache counts, paired latency direction, and cost caveat.
- [Complete results](results.json): all 18 runs, actual coding usage, patch/acceptance output, retained paths, timing, all 240 screening request bodies/responses, and errors. No run was excluded.
- [Run transcript](run.log): sequential per-run results.
- [Failing-before acceptance](before-acceptance.json): actual failure for the original invalid-credentials message.
- Each `NN-ARM-result.json` contains one measured workflow; corresponding `NN-ARM-events.jsonl`, `NN-ARM-prompt.txt`, and `NN-ARM-stderr.txt` preserve the coding request, event stream, and diagnostics.
- [Fixture](fixture.json) and [protocol](protocol.json) preserve source, candidate ordering, roots, ground truth, criteria parameters, requested models/tier, concurrency, and pricing assumptions. Ground truth is not sent as a classifier label.

Credentials are supplied in process environment only and are absent from the evidence files. The user's API key is not saved in the harness or report.

## Reproduce

Set `TYPESAFE_API_KEY` privately in the shell environment. Ensure `codex` is authenticated and supports the selected model, and Node is installed. From the article workspace:

```sh
python3 scripts/benchmark-part4.py --output /path/to/new-evidence-directory
```

Use a new output directory to preserve this dated run. Model access, service load, caching, and future pricing may change the results. The harness asserts complete successful runs but writes individual raw results before its final assertion; inspect failures rather than discarding them.

## Article decision

Retain the 80,000→10,000 diagram strictly as hypothetical arithmetic. Add the measured negative result alongside its method. Recommend deterministic filtering first, and assess Jev only where that leaves genuine uncertainty. Do not claim demonstrated Jev monetary savings, production accuracy, or general speedup from this experiment.
