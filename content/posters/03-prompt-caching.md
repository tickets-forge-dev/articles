# Part 3 — A Timestamp Can Break Your Prompt Cache

**Asset:** [Download the 1600×2000 PNG](03-prompt-caching.png)

**Alt text:** Before: a changing timestamp precedes shared instructions, so an early prefix mismatch prevents reuse of the later instruction state. After: the shared instructions come first, with a cache boundary before the timestamp; the user question remains separate. This exposes eligible reuse, not a guaranteed hit. Preserve message roles, test behavior, and measure results.

**Caption:** The same information, a different cache boundary. Stable content first can enable prefix reuse—when the provider’s eligibility, configuration, and availability requirements are met.

**Use:** Standalone 4:5 explanatory poster for the approved publication Part 3. Not a seventh image in the article. Examples are schematic, not measured cache hits or a latency/cost benchmark. Reordering is conditional on application correctness; explicit boundaries depend on the provider. The smallest decorative series badge is not essential to understanding the diagram.

**Article source:** `content/drafts/09-prefix-caching.md` (original storage number 09, publication Part 3).

**Sources:** [OpenAI prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching), [Claude prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching), [vLLM prefix caching](https://docs.vllm.ai/en/latest/design/prefix_caching/).

**Rebuild:** `python3 scripts/part3-assets.py artifacts/article-series/part-3/staged` stages the poster, hero and four diagrams without changing installed content. Actual 375px previews are in the staging directory’s `mobile/` subdirectory.
