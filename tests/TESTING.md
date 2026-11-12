# Testing

With Python 3.11 or newer and Typst installed, run:

```sh
python3 tools/test.py
```

The runner compiles all test fixtures and examples, checks their assertions and expected-error diagnostics, and tests the local package import against this checkout. It also compares each successful PDF's SHA-256 hash with `tests/pdf-hashes.json`. New, changed, or removed PDFs require review and give a nonzero exit code. Expected-error fixtures have no PDF baseline.

PDFs use a fixed creation timestamp and only Typst's embedded fonts. The baseline records the exact compiler version; changing it requires reviewing all PDF baselines together. Dependencies use Typst's normal package cache. Use `--typst /path/to/typst` to select a compiler, or `--compile-only` to check compilation and diagnostics without comparing or updating hashes.

When a hash changes, open `build/pdf-review/review.md` and inspect the linked PDFs. The implementing agent can do this review using the task's intended behavior and the test source. Explain why each output change is expected before accepting it; do not accept solely because the implementation changed. A hash detects a difference, but does not establish that either output is correct.

Accept only the fixtures you have reviewed, using repository-relative paths:

```sh
python3 tools/test.py --accept tests/calculate.typ examples/all-functions.typ
python3 tools/test.py
```

Acceptance copies hashes from the last completed review, without recompiling. It checks that the baseline and retained PDFs have not changed and refuses runs with compilation or diagnostic failures. The review is consumed after acceptance; run the tests again before accepting further changes. If source files changed after the review, the next test run checks their new output against the accepted hashes.

For the initial baseline or an intentional compiler upgrade, inspect all outputs and use `python3 tools/test.py --accept all`. This is an explicit acceptance step, never part of a normal test run. The initial baseline captures existing output; it does not certify every example's visual or mathematical correctness.

Only hashes are tracked in Git. PDFs are cached by hash under the ignored `build/pdf-review/pdfs/` directory, so subsequent reviews can link both old and new output without storing reference images. On a fresh checkout, an old PDF may be unavailable: run the tests in a separate checkout of the baseline's Git revision with its recorded compiler version to reproduce it, and verify its hash before comparing. Keep that checkout until the review is complete. Deleting `build/pdf-review/` removes this local cache and pending review, but not the tracked baseline.

Run the test runner's own regression tests with `python3 -B -m unittest discover -s tools/tests -v`. These exercise hash acceptance, retained PDFs, additions and removals, failures, timeouts, and compiler changes in temporary projects. A real PDF smoke test also runs when Typst is available.

## Compile speed

```sh
python3 tools/speed-test.py
```

This generates documents of several lengths and compiles each one twice: once with math-once, and once as plain Typst math with the same equations and precomputed results. It prints both times, how many times slower math-once is, and the added time per calculation. Use `--sections 1 5 20 50 100` to choose the sizes; each section has 10 calculations. The documents and `results.json` are kept in `build/speed-test/`.

Use `--baseline path/to/older/math-once.typ` to time an earlier version next to the current one; the output then has before and after columns and how many times faster or slower the current version is. `--max-seconds 7.5` makes the command exit with status 1 when a math-once document takes longer than that, and `--summary FILE` writes the table as Markdown.

Timings depend on the machine, so this is not part of `tools/test.py`. The `Speed test` GitHub Actions workflow runs it on every pull request with the target branch as the baseline, posts the table as a comment on the pull request, and fails when a document exceeds the limit set by `MAX_SECONDS` in `.github/workflows/speed-test.yml`. It measures full compiles; `tools/benchmark-incremental.py` measures edits in a running `typst watch`.


Use `--workload mixed` to add a stored vector-valued function and a matrix product to each section. Each mixed section has 14 builder calls and checks the product's components. `--initial-values 100` seeds the builder with 100 unused variables to measure the cost of a large initial state. For example:

```sh
python3 tools/speed-test.py --workload mixed --initial-values 100 --sections 5 20 --runs 5
```

Cold-compile `results.json` also retains individual samples under `samples_seconds`. A timeout in an empty, import-only, or plain document marks the benchmark incomplete and fails the command. The report retains available timings and leaves unavailable ratios blank.

For edits in a persistent watch process, run:

```sh
python3 tools/benchmark-incremental.py --workload chain --runs 5 --output build/watch-chain
python3 tools/benchmark-incremental.py --workload chain --result-only --runs 5 --output build/watch-results
```

The default workload uses independent assignments. `--workload chain` makes every assignment depend on the preceding result, so changing the first value must update the entire chain. Every section checks all its stored values after each edit. `--result-only` also applies to the assignments themselves.

Each run starts a fresh watch process and retains sources, logs, timings, and compiler metadata under `run-N/`. The top-level `results.json` contains the samples and median for each edit. The default is three runs. For a before/after comparison, pass `--implementation path/to/older/math-once.typ` and use separate output directories. On a busy machine, alternate before/after runs to reduce bias from changing load. Compiler traces from `--timings` add overhead; use them to investigate work done rather than to claim normal compile speed.
