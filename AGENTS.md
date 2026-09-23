# Repository instructions

- Every implementation change must include a corresponding entry in `CHANGELOG.md`.
- Do not create a commit or release unless the user explicitly asks for it.

## PDF hash review

- Run `python3 tools/test.py` after implementation changes. A `REVIEW` result means the generated PDF or compiler environment differs from the stored baseline.
- Before accepting changed hashes, inspect the retained PDFs linked from `build/pdf-review/review.md`, the affected test sources, and the task's intended behavior. Compare with the previous PDFs when needed; the report links cached copies or explains how to reproduce missing ones.
- The implementing agent can perform this review. Explain why the output changes are intentional before running `python3 tools/test.py --accept <fixture paths>`. Never accept hashes just to make the tests pass.
- Run the tests again after acceptance. Keep hash updates limited to reviewed fixtures; use `--accept all` only when every pending change has been reviewed.
- `--compile-only` checks assertions and diagnostics but does not establish that PDF output matches the baseline.

## Linked worktree demos

- When running in a linked Git worktree, always prepare implementation changes as a demo based on the current package version. A linked worktree can be identified by resolving `git rev-parse --git-dir` and `git rev-parse --git-common-dir`; they point to different directories.
- Replace the first line of `math-once.typ` with a short description of the demo followed by the base version in parentheses, for example `// Better CAS integration (0.38.0)`. Do not put a new version number in that line.
- Keep the base version unchanged in `typst.toml`, the local-package import example in `README.md`, and `tests/package-import.typ`.
- Add the changelog entry under a descriptive demo heading that names the base version, for example `## Better CAS integration demo (based on 0.38.0)`.
- Do not create a Git tag for a worktree demo.

## Versioned delivery outside linked worktrees

- Bump the version in the first line of `math-once.typ` whenever implementation changes are prepared for delivery outside a linked worktree.
- Keep that version synchronized with `typst.toml`, the local-package import example in `README.md`, and `tests/package-import.typ`.
- Whenever a new version is prepared, create a Git tag with the exact same version, for example `0.38.0`.

