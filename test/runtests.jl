using OrderedCollections: OrderedDict
"""
Return the default set of tests enabled for CTParser.

## How to run tests

This test runner supports selecting which test groups to execute via command-line
arguments (available as `ARGS`). When running through `Pkg.test`, the same values
are provided via `test_args`.

- No args: run the default selection (see `default_tests()`).

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase")'
```

- One arg: run only that test group.

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["utils"])'
```

- Several args: run the union of the selected groups.

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["utils","integration"])'
```

- Special arg `all`: run all available groups.

```bash
julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["all"])'
```

- Special arg `coverage=true`: ignored by this runner (so it does not affect test selection).
  Use it only to ask `Pkg.test(...; coverage=true)` to generate `.cov` files, then run the
  post-processing artifact from the package root.

```bash
julia --project=@. -e '
using Pkg
Pkg.test("CTBase"; coverage=true, test_args=["utils"])
include("coverage_artifact.jl")
CoverageArtifact.run()
'
```

Each group `name` corresponds to a `test_<n>.jl` file defining a
`test_<n>()` function.
"""
function default_tests()
    # Keys correspond to `test_<n>.jl` files + `test_<n>()` entrypoints.
    # Values indicate which test groups are enabled when no CLI selection is provided.
    return OrderedDict(
        :code_quality => true,
        :default => true,
        :description => true,
        :exceptions => true,
        :utils => true,
        :documenter_reference => true,
        :integration => true,
    )
end

# Test dependencies and shared configuration.
using CTBase
using Test
using Aqua
using Documenter
using Markdown
using MarkdownAST

# Optional extension module access (loaded only when the package defines it).
const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)

# Macro to check if an expression is type-stable and inferred correctly
macro test_inferred(expr)
    q = quote
        try
            @inferred $expr
            @test true
        catch e
            @test false
            println("Error in @inferred: ", e)
        end
    end
    return esc(q)
end

# Controls the top-level `@testset` output formatting.
const VERBOSE = true
const SHOWTIMING = true

# ============================================================================
# Command-line argument parsing
# ============================================================================

function _parse_test_args(args::Vector{String})
    selections = String[]

    for arg in args
        arg in ("coverage=true", "coverage", "--coverage", "coverage=false") && continue
        push!(selections, arg)
    end

    return selections
end

const _SELECTION_ARGS = _parse_test_args(String.(ARGS))
const TEST_SELECTIONS = isempty(_SELECTION_ARGS) ? Symbol[] : Symbol.(_SELECTION_ARGS)

# ============================================================================
# Test selection logic
# ============================================================================

function selected_tests()
    tests = default_tests()
    sels = TEST_SELECTIONS

    isempty(sels) && return tests

    # Enable all tests if :all is requested
    if :all in sels
        for k in keys(tests)
            tests[k] = true
        end
        return tests
    end

    # Otherwise, enable only selected tests
    for k in keys(tests)
        tests[k] = false
    end
    for sel in sels
        haskey(tests, sel) && (tests[sel] = true)
    end

    return tests
end

const SELECTED_TESTS = selected_tests()

@testset verbose = VERBOSE showtiming = SHOWTIMING "CTParser tests" begin
    for (name, enabled) in SELECTED_TESTS
        enabled || continue
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end