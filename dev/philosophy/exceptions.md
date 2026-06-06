# Exceptions

Structured, informative errors. The ecosystem provides seven exception types under
`CTException`, imported via `import CTBase.Exceptions`.

## Principles

1. **Clear message** — immediately understandable.
2. **Actionable suggestion** — how to fix it.
3. **Rich context** — what was expected, what was received, where.
4. **Typed** — pick the right exception so callers can catch precisely.

## The seven types

| Type | Key fields | Use when |
|---|---|---|
| `IncorrectArgument` | `msg, got, expected, suggestion, context` | a single argument's value is out of domain |
| `PreconditionError` | `msg, reason, suggestion, context` | arguments valid individually, but the call's relation/state/timing is forbidden |
| `NotImplemented` | `msg, required_method, suggestion, context` | interface stub a subtype must implement |
| `ParsingError` | `msg, location, suggestion` | DSL / syntax / structure error |
| `AmbiguousDescription` | `description, candidates, suggestion, context` | a symbol-tuple description matches no catalogue entry |
| `ExtensionError` | `weakdeps, feature, context` | an optional (weak) dependency is not loaded |
| `SolverFailure` | `msg, retcode, suggestion, context` | a numerical solver/integrator failed |

## The choice rule

> **`IncorrectArgument`** = "*this value* is wrong" (domain of **one** argument).
> **`PreconditionError`** = "*this combination / state / timing* is wrong" (a
> **relational** or contextual contract, each argument valid on its own).

Operational heuristic: if the message must mention **two things** ("x relative to y",
"this after that"), it is almost always `PreconditionError`. If it mentions **one**
value ("n must be > 0"), it is `IncorrectArgument`.

Note the fields: `IncorrectArgument` has `got`/`expected` (**no** `reason`);
`PreconditionError` has `reason`. Using the wrong field is a tell that the type is wrong.

## Examples (generic)

```julia
import CTBase.Exceptions

# Single-argument domain violation
throw(Exceptions.IncorrectArgument(
    "dimension must be positive";
    got = "n = -1", expected = "n > 0",
    suggestion = "pass a positive integer for n",
    context = "make_thing",
))

# Relational / state violation
throw(Exceptions.PreconditionError(
    "cannot combine A with B";
    reason = "A carries x, B carries (x, p): the handoff is undefined",
    suggestion = "combine objects of the same kind",
    context = "composition",
))

# Interface stub on an abstract type
function run(s::AbstractStrategy, x)
    throw(Exceptions.NotImplemented(
        "run not implemented for $(typeof(s))";
        required_method = "run(::$(typeof(s)), x)",
        suggestion = "define run for your strategy type",
        context = "AbstractStrategy contract",
    ))
end

# Optional dependency missing (extension stub)
throw(Exceptions.ExtensionError(:SomeBackend; feature = "AD", context = "build"))

# Numerical failure
throw(Exceptions.SolverFailure(
    "integration failed"; retcode = ":Unstable",
    suggestion = "reduce the step or check initial conditions",
))
```

## Testing exceptions

```julia
Test.@test_throws Exceptions.IncorrectArgument bad_call()

err = try bad_call() catch e; e end
Test.@test err isa Exceptions.IncorrectArgument
Test.@test occursin("must be positive", err.msg)
```

## Anti-patterns

```julia
error("something went wrong")                 # ❌ untyped, vague
throw(Exceptions.IncorrectArgument("bad"))    # ❌ no got/expected/suggestion
throw(Exceptions.IncorrectArgument("already finalized"))  # ❌ should be PreconditionError
throw(Exceptions.PreconditionError("n must be > 0"))      # ❌ should be IncorrectArgument
```

## Checklist

- [ ] Exception type matches the situation (single value vs relational vs contract vs …).
- [ ] Message clear and specific; `got`/`expected` set when applicable.
- [ ] Actionable `suggestion`; `context` for non-trivial errors.
- [ ] Fields valid for the chosen type (`reason` only on `PreconditionError`).
- [ ] Covered by a `@test_throws`.
