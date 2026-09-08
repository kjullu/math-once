# Repository instructions

- Every implementation change must include a corresponding entry in `CHANGELOG.md`.
- Bump the version in the first line of `math-once.typ` whenever implementation changes are prepared for delivery.
- Keep that version synchronized with `typst.toml`, the local-package import example in `README.md`, and `tests/package-import.typ`.
- Whenever a new version is prepared, create a Git tag with the exact same version (for example, `0.38.0`).
- Do not create a commit or release unless the user explicitly asks for it.
