# Your Coding Agent Read 40 Files to Change One Line

*Use Jev to screen files and cut coding-model input.*

![AI Engineering Fundamentals Part 4: Your Coding Agent Read 40 Files to Change One Line. A bold title sits beside Idan’s small circular portrait.](../images/08-retrieval-pipeline/hero.png)

**When to use this:** Your coding agent reads too much before making a small fix.

[Jev](https://docs.typesafe.ai/introduction) is TypeSafe’s AI model for focused decisions. Instead of writing code or long replies, it answers questions using options you define—such as `keep`, `skip`, or `unsure`. Here, it will help screen files before they reach the coding model.

## A one-line fix with a reading problem

Imagine asking a coding agent:

> “On the web login screen, invalid credentials should show ‘Email or password is incorrect,’ not ‘Something went wrong.’”

It searches the monorepo. Forty files mention authentication, errors, or login. Eventually, it changes one message in the web login error mapper.

The patch is tiny. The reading assignment was not.

This scenario is fictional. Below, a live synthetic experiment tests the idea—not a production agent.

## Step 1 — don’t make the expensive model read everything

A search match is a candidate, not an instruction to paste a whole file into the coding model.

Start with path filters, symbol search, imports, and the failing test. If those identify the code, stop: you do not need Jev.

For a remaining noisy shortlist, compare **the same candidates**: open everything versus screen first, then open retained files and dependencies. Do not credit a better search query to Jev.

![Forty candidate files flow directly into the coding model. The diagram labels this as an imagined broad-read baseline rather than a measured run.](../images/08-retrieval-pipeline/step-1.png)

*Baseline: every candidate becomes a full-file read by the coding model.*

## Step 2 — make the token budget visible

**Illustration, not a benchmark:** assume 2,000 tokens per file and five retained files, including tests and dependencies. Count file contents for one request, excluding shared instructions and chat history:

- **Before:** 40 × 2,000 = **80,000 input tokens**.
- **After:** 5 × 2,000 = **10,000 input tokens**.
- **Difference:** **70,000 fewer tokens—87.5% less file context**.

Jev’s screening, request overhead, and rereads are extra. Different tokenizers and prices matter: less coding-model context does not establish lower total cost.

![An explicitly illustrative budget compares 80,000 versus 10,000 coding-model input tokens, or 87.5 percent less file context. Jev screening is extra and no measured savings are claimed.](../images/08-retrieval-pipeline/step-2.png)

*Screening can shrink the main model’s input; account for the screening stage separately.*

## Step 3 — give Jev a small, specific job

For each candidate, supply the task, file path, and an informative excerpt as its **state**. Ask a **Choice** question:

> “Should the coding agent inspect this file to fix the web login error message?”

Define three options:

- `keep`: evidence connects it to the handler, message mapping, or relevant test.
- `skip`: evidence establishes that it is unrelated to this task.
- `unsure`: the excerpt is insufficient or ambiguous.

For example:

    Task: fix the web login error message
    File: apps/web/LoginForm.tsx
    Excerpt: setError(loginMessage(error.code))
    Expected choice: keep

The expected choice is illustrative, not an API result. Inspect unfamiliar imported mappers rather than guessing from filenames.

Send only approved source. Treat file contents as untrusted data; enforce paths and secret filtering in code.

![Task, candidate path and excerpt go to Jev. Choice labels are keep, skip and unsure. The coding model still performs the actual investigation and fix.](../images/08-retrieval-pipeline/step-3.png)

*Jev screens supplied evidence; it does not magically inspect unseen files or write the patch.*

## Step 4 — never optimize away the crucial file

Pin required tests and dependencies independently of the classifier. For authorized candidates, a conservative reading decision is:

    def should_read(choice=None, *, required=False, confidence_ok=False):
        return (required is not False
                or confidence_ok is not True
                or choice != "skip")

Missing answers, errors, `unsure`, or insufficient confidence keep the file readable. Evaluate thresholds on your tasks; even confident skips can be wrong. Expand the search when evidence or tests disagree.

The coding model then reads the real implementation. In our fictional mapper, the one-line change is:

    // Before: INVALID_CREDENTIALS branch
    return "Something went wrong";
    // After: same branch
    return "Email or password is incorrect";

Run the relevant tests; a shorter context is not proof of a correct fix.

![Required files and unsure or failed checks remain readable. Only a non-required confident skip omits a candidate. Compare end-to-end time, total cost and successful fixes.](../images/08-retrieval-pipeline/step-4.png)

*Add a conservative fallback, then evaluate the complete workflow rather than token count alone.*

## What happened when I measured it?

On October 4, 2026, I ran **one synthetic login task six times per approach**, rotating all six execution orders. Jev 1.13.0 screened snippets; GPT-5.6-Sol returned a fixed-context patch. Each patch was applied and acceptance-tested.

- **Read all 40:** 59,821 coding input tokens; **7.48 s** median.
- **Jev, then code:** still 59,821 tokens and 40 files; **8.69 s** median.
- **Code-only import filtering:** 15,011 tokens and five files; **6.56 s** median.

All 18 fixes passed. Timing includes selection, coding, patch application, and tests—not just Jev response time.

**Jev did not save context or improve median speed here.** It chose `skip` for 35 files, but none met the predeclared 0.95 confidence threshold, so the conservative fallback retained them. Screening added about **$0.00152 per run**, estimated from actual usage and published pricing.

Cache usage differed across runs; lower observed cost estimates cannot establish Jev savings. These coding inputs include CLI instructions, unlike the illustration. Six repeats of one generated task do not establish production accuracy or general speed effects.

[Method and raw-run evidence](../../artifacts/article-series/preview/part-4-benchmark.html).

**Measure before adding a model.** Ordinary import filtering solved this fixture without Jev. Evaluate screening where deterministic tools leave genuine uncertainty; keep it only when the complete workflow improves.

If your team needs help making coding agents faster without sacrificing correctness, [email me](mailto:bar.idan@gmail.com) about a monthly programming-contractor retainer.

## Sources

- [TypeSafe: System One](https://docs.typesafe.ai/concepts/system-one)
- [TypeSafe: State](https://docs.typesafe.ai/concepts/state)
- [TypeSafe: Choice](https://docs.typesafe.ai/primitives/choice)
- [TypeSafe: Confidence](https://docs.typesafe.ai/confidence)
- [OpenAI: Latency optimization](https://developers.openai.com/api/docs/guides/latency-optimization)
- [TypeSafe: Models and pricing](https://docs.typesafe.ai/models)
- [OpenAI: Pricing](https://developers.openai.com/api/docs/pricing)
