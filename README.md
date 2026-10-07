# AI Engineering Fundamentals — Parts 1–4

This repository contains only publication Parts 1–4 and their images, posters, rendering tools and Part 4 experiment evidence. Publication order comes from `content/publication-order.json`; draft filename prefixes are storage identities, not release positions. Unreleased articles, standalone guides and their assets are not included, including in Git history.

| Part | Article |
| --- | --- |
| 1 | [What Happens Between a Prompt and an Answer?](content/drafts/01-prompt-to-answer.md) |
| 2 | [Tokens, Context, and Attention](content/drafts/02-tokens-context-attention.md) |
| 3 | [A Timestamp Can Break Your Prompt Cache](content/drafts/09-prefix-caching.md) |
| 4 | [Jev vs. an LLM for Intent Classification](content/drafts/08-retrieval-pipeline.md) |

## Part 4 evidence

- [Experiment report and limitations](artifacts/article-series/part-4-coding/account-closure-comparison-2026-10-04/evidence.md)
- [Recorded calls, datasets, privacy disclosure and reproduction](artifacts/article-series/part-4-coding/README.md)
- [Download the privacy-safe evidence archive](downloads/part-4-evidence.zip)
- [Machine-readable comparison](downloads/comparison.csv)
- [Part 4 publication DOCX](downloads/part-4-article.docx)
- [Complete Part 4 publication package](downloads/part-4-publication.zip)
- [Companion experiment report DOCX](downloads/experiment-report.docx)

The account-closure experiment used sixty unique held-out BANKING77 queries repeated three times per classifier. All three implementations returned 180/180 correct evaluation decisions. Median ten-query batches: Jev 0.3014 s; GPT-5.6-Luna 4.3574 s; GPT-5.6-Sol 5.0237 s. This compares the tested Jev HTTP and persistent minimal Codex integrations, not bare OpenAI API inference. Costs are published API-price equivalents from reported usage/cache counts, not invoices or subscription savings. Synthetic boundary cases and earlier unsuccessful experiments remain separate. No bank account action was executed.

Verify recorded evidence without credentials or paid requests:

```sh
python3 scripts/check-part4.py
```

The public export omits unrelated account notifications and temporary transport working directories, not classification queries, predictions, token/cache usage or measured timing. Original private captures are not distributed.

## Reading previews and graphics

With `uv` installed, render any of the four parts:

```sh
uv run --with markdown==3.9 --no-project python scripts/preview-article.py 4
```

Output is a self-contained local preview under `artifacts/article-series/preview/`; it is not a live Medium publication.

On macOS with Swift/AppKit:

```sh
python3 scripts/check-draft-layout.py
python3 scripts/part3-assets.py /tmp/articles-part3-render
python3 scripts/part4-assets.py /tmp/articles-part4-render
```

The asset commands stage files without installing them. Hero/card tools retain their documented snapshot CLI and accept the four released drafts. Renderers use the approved `content/portrait.png` crop; no private planning files are required. Separate social posters are under `content/posters/`.

## Dataset attribution

BANKING77: PolyAI / Casanueva et al. (2020), [Efficient Intent Detection with Dual Sentence Encoders](https://arxiv.org/abs/2003.04807), [source dataset](https://github.com/PolyAI-LDN/task-specific-datasets), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Query text and original labels are unchanged; adaptation is binary mapping and fixed-seed subset selection. The TypeSafe mark is third-party branding, not an endorsement. Other technical sources are cited in the articles.

No repository-wide relicensing of original articles, code or artwork is supplied. Dataset-specific terms remain separate.
