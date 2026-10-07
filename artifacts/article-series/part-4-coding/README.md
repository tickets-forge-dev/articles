# Part 4: reproducible account-closure experiment

The final article is [Jev vs. an LLM for Intent Classification](../../../content/drafts/08-retrieval-pipeline.md). The authoritative measured report is [the account-closure evidence document](account-closure-comparison-2026-10-04/evidence.md).

## Inspect the evidence

- [Frozen primary cases, criteria, source hashes and selection](account-closure-comparison-2026-10-04/dataset.json)
- [Predeclared protocol, timing scope, rates and gates](account-closure-comparison-2026-10-04/protocol.json)
- [Calibration and frozen selected cutoff](account-closure-comparison-2026-10-04/calibration.json)
- [Every primary classification call and its response/usage](account-closure-comparison-2026-10-04/results.json)
- [Exact primary aggregates and comparisons](account-closure-comparison-2026-10-04/summary.json)
- [Independent source/data/accounting audit](account-closure-comparison-2026-10-04/verification.json)
- [Separate authored boundary cases](account-closure-boundaries-2026-10-04/dataset.json) and [all boundary results](account-closure-boundaries-2026-10-04/results.json)
- [Untuned keyword control](account-closure-comparison-2026-10-04/keyword-control.json)
- [Earlier failed coarse-routing experiment](routing-comparison-2026-10-04/summary.json)
- [Earlier unsuccessful coding-file screening experiment](benchmark-2026-10-04/evidence.md)
- [Measurement-time article snapshot](publication-final-2026-10-04/measurement-time-article.md)

The directory also retains each individual measured request/response and the sequential run logs, not only aggregate summaries. No incorrect classification, failed measured call, timing outlier, or cheap baseline was removed to produce a positive result. The account-closure claim does not retroactively validate the earlier tasks.

## Privacy of this public export

The public records omit unrelated `account/*` transport notifications and transient absolute `cwd` fields from Codex envelopes. These expose account or machine metadata, not classification evidence. **Queries, label definitions, expected labels, predictions, confidence, token/cache usage, timestamps, elapsed times and measured costs remain unchanged.** All measured call records remain present.

[The export manifest](public-export-manifest.json) lists the exact original/public hashes of changed files and the fields/event classes omitted. Frozen datasets, protocols, calibration and summaries retain their original bytes and hashes. Some frozen provenance strings retain measurement-time paths; they are not credentials or required runtime locations. Original private captures remain with the author. No authentication file or API key is distributed.

The historical publication manifest describes the local finalization stage, before this public privacy export; it is not a claim that redacted transport files still match their private original hashes.

## Verify without paid requests

From the repository root:

```sh
python3 scripts/check-part4.py
```

This recomputes decisions, repeated-case coverage, quality/performance gates and cache-aware price equivalents from recorded provider output. It also checks original CSV hashes and source labels, cohort isolation, semantic input parity and inherited boundary policy. It does not call a model API or pin article wording.

## Reproduce with real models

Use Python 3.9 or newer and the Codex CLI. The measured connection used Codex 0.146.0. Authenticate using your own account, configure `TYPESAFE_API_KEY` privately, and check availability of the named model families. Do not substitute another model and retain the original model claim.

Create a fresh output directory and copy the primary `dataset.json` into it. Then run:

```sh
python3 scripts/benchmark-jev-routing.py --output /tmp/jev-account-closure-reproduction
```

This makes real requests and can incur charges. Setup/calibration is outside the reported steady-state evaluation clock. The harness preserves call failures and does not edit the article. Existing local Codex OAuth is copied into an isolated permission-restricted temporary directory, then removed on exit; it is never committed here.

## Claim and dataset limits

The task recommends a human support queue; no banking action was executed. Sixty unique held-out BANKING77 queries were each evaluated three times per model; these are not 180 independent examples. The sample is balanced, small and public. Pretraining exposure is unknown. Thirty authored boundary examples are separate synthetic validation, not production records or added public benchmark cases.

The LLMs used persistent minimal Codex, not bare OpenAI API inference. Framework context remains. Dollar figures are published standard API-price equivalents, not invoices or lower ChatGPT subscription bills. Immutable backend snapshots and actual billing tier were not returned. See the full report for all cache scenarios and baseline limitations.

BANKING77 attribution: PolyAI / Casanueva et al. (2020), [Efficient Intent Detection with Dual Sentence Encoders](https://arxiv.org/abs/2003.04807), [source dataset](https://github.com/PolyAI-LDN/task-specific-datasets), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Original query text and intent labels are unchanged; adaptation is binary mapping and fixed-seed subset selection.
