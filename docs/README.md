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

DocumenterVitepress processes code block output differently depending on how it is produced:

| Block type | Output fence | ANSI codes | Result |
| --- | --- | --- | --- |
| `@example` | ` ```ansi ` | processed by Shiki | **colors render correctly** |
| `@repl` | ` ```julia ` | parsed as Julia syntax | **raw escape sequences — ugly** |

**Rules:**

- Use **`@example`** when the output comes from a `show` method that uses ANSI colors
  (strategy instances, `StrategyOptions`, `StrategyMetadata`, `StrategyRegistry`, …).
- Use **`@repl`** only when the output is a plain scalar value with no custom colored `show`
  (integers, booleans, symbols, plain strings, tuples of symbols, types).
- Use **`@repl` + `try/catch # hide` + `showerror(IOContext(stdout, :color => false), e) # hide`**
  to display exceptions — the `showerror` call produces plain text that renders cleanly inside a
  `julia`-fenced block.
