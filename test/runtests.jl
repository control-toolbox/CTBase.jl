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

Each group `name` corresponds to a `test_<name>.jl` file defining a
`test_<name>()` function.
"""
function default_tests()
    # Keys correspond to `test_<name>.jl` files + `test_<name>()` entrypoints.
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
const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference) # to test functions from CTFlowsODE not in CTFlows

# Macro to check if an expression is type-stable and inferred correctly
macro test_inferred(expr)
    # Purpose: Verify that the expression is type-stable and inferred correctly.
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

# Optional CLI selection: pass symbols like `default` or `code_quality`.
# Special value `all` enables everything.
const TEST_SELECTIONS = isempty(ARGS) ? Symbol[] : Symbol.(ARGS)

function selected_tests()
    # Determine which test groups to run based on CLI selection.
    tests = default_tests()
    sels = TEST_SELECTIONS

    # No selection: use defaults
    if isempty(sels)
        return tests
    end

    # Single :all selection: enable everything
    if length(sels) == 1 && sels[1] == :all
        for k in keys(tests)
            tests[k] = true
        end
        return tests
    end

    # Otherwise, start with everything disabled
    for k in keys(tests)
        tests[k] = false
    end

    # Enable explicit selections
    for sel in sels
        if sel == :all
            for k in keys(tests)
                tests[k] = true
            end
            break
        end
        if haskey(tests, sel)
            tests[sel] = true
        end
    end

    return tests
end

const SELECTED_TESTS = selected_tests()

@testset verbose = VERBOSE showtiming = SHOWTIMING "CTParser tests" begin
    for (name, enabled) in SELECTED_TESTS
        enabled || continue
        @testset "$(name)" begin
            # Convention:
            # - file:     `test_<name>.jl`
            # - function: `test_<name>()`
            test_name = Symbol(:test_, name)
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end