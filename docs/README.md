# docs/

Documentation site for CTBase.jl, built with
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl).

Build (from the package root):

```bash
julia --project=. docs/make.jl
```

Preview after build: `npx serve docs/build/1 --listen 5173`

Documentation conventions and build workflow:
[control-toolbox Handbook](https://github.com/control-toolbox/Handbook).

## `@repl` vs `@example` — ANSI color rule

Before `DocumenterVitepress` **v0.3.5**, ANSI-colored output from `@repl` could be rendered as raw
escape sequences. This was fixed in v0.3.5 ([#373](https://github.com/LuxDL/DocumenterVitepress.jl/pull/373)):
colored `@repl` output is now rendered correctly while the input remains Julia syntax-highlighted.

**Rules for v0.3.5 and later:**

- Use **`@repl`** for interactive examples, including output from custom ANSI-colored `show`
  methods (strategy instances, `StrategyOptions`, `StrategyMetadata`, `StrategyRegistry`, …).
- Use **`@example`** for regular evaluated examples when REPL formatting is not needed; keep existing
  blocks whose output already renders correctly.
- Use **`@ansi`** when explicitly demonstrating terminal styling or raw ANSI output.
- Use **`@repl`** with a direct expression that raises an exception when demonstrating native REPL
  error handling; `@repl` captures the exception as output instead of failing the documentation build.

For versions before v0.3.5, use `@example` or `@ansi` for colored output, or use an explicit
`try/catch` and `showerror(IOContext(stdout, :color => false), e)` when a colorless output is required.
