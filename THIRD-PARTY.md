# Third-party software

## typCAS

math-once imports `@preview/typcas:0.2.3` for symbolic algebra. The dependency
is fetched and cached by Typst's package system and is not vendored in this
repository.

- Project: [typCAS](https://github.com/sihooleebd/typCAS)
- Author and copyright: Copyright (c) 2026 Benjamin Lee
- License: [MIT](https://github.com/sihooleebd/typCAS/blob/main/LICENSE)

The dependency's own source distribution contains its complete license notice.

## Typst codex

The generated symbol-name and Unicode-value catalog embedded in
`math-once.typ` is derived from Typst codex 0.2.0's `src/modules/sym.txt`.
The generator changes the source data into Typst dictionaries and excludes
deprecated bindings.

- Project: [typst/codex](https://github.com/typst/codex)
- Source version: [codex 0.2.0 sym.txt](https://github.com/typst/codex/blob/v0.2.0/src/modules/sym.txt)
- License: Apache License 2.0
- License copy: [LICENSE-APACHE-2.0](LICENSE-APACHE-2.0)
