# Repository instructions

- Every implementation change must include a corresponding entry in `CHANGELOG.md`.
- Do not create a commit or release unless the user explicitly asks for it.

## Linked worktree demos

- When running in a linked Git worktree, always prepare implementation changes as a demo based on the current package version. A linked worktree can be identified by resolving `git rev-parse --git-dir` and `git rev-parse --git-common-dir`; they point to different directories.
- Replace the first line of `math-once.typ` with a short description of the demo followed by the base version in parentheses, for example `// Better CAS integration (0.38.0)`. Do not put a new version number in that line.
- Keep the base version unchanged in `typst.toml`, the local-package import example in `README.md`, and `tests/package-import.typ`.
- Add the changelog entry under a descriptive demo heading that names the base version, for example `## Better CAS integration demo (based on 0.38.0)`.
- When preparing a worktree branch for a pull request, make the comment directly below the demo label in `math-once.typ` link to the public GitHub issue for the work. Put the easy-to-test raw-file link for the exact branch in the issue or pull-request comment instead, using `https://raw.githubusercontent.com/kjullu/math-once/refs/heads/<branch>/math-once.typ`.
- Do not use Send MCP, Tailscale, LAN, or other private links in a pull request. The test-file link must work through the public repository after the branch is pushed.
- Do not create a Git tag for a worktree demo.

## Versioned delivery outside linked worktrees

- Bump the version in the first line of `math-once.typ` whenever implementation changes are prepared for delivery outside a linked worktree.
- Keep that version synchronized with `typst.toml`, the local-package import example in `README.md`, and `tests/package-import.typ`.
- Whenever a new version is prepared, create a Git tag with the exact same version, for example `0.38.0`.
