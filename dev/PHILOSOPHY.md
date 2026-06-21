# Code philosophy

Design philosophy for the control-toolbox ecosystem, written **abstractly**: the
principles apply to all packages, but the examples and templates stay **generic**
(no package-specific symbols). For *tools and procedures* (tests, docs, git), see
[`RULES.md`](RULES.md).

The detail files referenced below live in the [`philosophy/`](philosophy/) directory.

## The tenets on one page

1. **One module per responsibility.** Each submodule has a single role, its own
   directory, its own manifest. The package manifest exports **nothing**.
   → [`modules.md`](philosophy/modules.md)

2. **Everything is qualified.** Import modules, not their symbols; call
   `Module.symbol` everywhere. Explicit origin, safe refactors, no shadowing.
   → [`modules.md`](philosophy/modules.md)

3. **One abstract type per *noun*, one trait-parameter per *adjective*.** Conceptual
   variants ("is it an X or a Y") are types; orthogonal axes (autonomous?, in-place?, …)
   are traits in a type parameter. Dispatch by extracting the trait.
   → [`types-traits-interfaces.md`](philosophy/types-traits-interfaces.md)

4. **Program against abstractions.** Methods live on abstract types as much as
   possible; contracts are `NotImplemented` stubs; subtypes honor the contract (LSP).
   → [`types-traits-interfaces.md`](philosophy/types-traits-interfaces.md)

5. **SOLID, DRY, KISS, YAGNI.** Single responsibility, open/closed via dispatch, no
   duplication, the simplest thing that works, nothing speculative.
   → [`types-traits-interfaces.md`](philosophy/types-traits-interfaces.md)

6. **Structured errors.** Seven typed exceptions; sharp rule: single-argument value →
   `IncorrectArgument`; relation/state/composition → `PreconditionError`; unimplemented
   contract → `NotImplemented`; optional dependency → `ExtensionError`.
   → [`exceptions.md`](philosophy/exceptions.md)

7. **Type stability by default.** Parametric types, no `Any` in hot paths, function
   barriers, verified with `@inferred`.
   → [`types-traits-interfaces.md`](types-traits-interfaces.md#type-stability)

8. **Everything is documented.** A docstring on every symbol, fixed templates,
   cross-references `@ref`/`@extref`, safe and reproducible examples.
   → [`docstrings.md`](philosophy/docstrings.md)

9. **Tests: module + callable function + everything qualified.** Each test file is a
   module with an entry function redefined in the outer scope; fakes at module
   top-level; categories unit / integration / contract / error.
   → [`testing.md`](philosophy/testing.md)

10. **Auto-generated API docs, public *and* private; guides separate.** Users reach
    internals via qualified paths, so both are documented.
    → [`documentation.md`](philosophy/documentation.md)

## Index

| File | Content |
| --- | --- |
| [`modules.md`](philosophy/modules.md) | Submodule organization, imports/qualification, DAG, exports |
| [`types-traits-interfaces.md`](philosophy/types-traits-interfaces.md) | Types vs traits, interfaces/contracts, SOLID/DRY/YAGNI, type stability |
| [`exceptions.md`](philosophy/exceptions.md) | The 7 exceptions and the choice rule |
| [`docstrings.md`](philosophy/docstrings.md) | Docstring templates, cross-references, example safety |
| [`testing.md`](philosophy/testing.md) | Categories, fakes/stubs, **module + callable function template** |
| [`documentation.md`](philosophy/documentation.md) | API generation, guides, draft workflow |
