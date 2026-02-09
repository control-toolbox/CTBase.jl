# Test Runner Guide

This guide explains how to set up a modular testing infrastructure for Julia packages using the **TestRunner** extension of `CTBase.jl`. This setup enables granular test execution and is friendly both for human developers and AI agents.

## Architecture Overview

A robust testing architecture typically involves:

1. **Test Runner**: A `runtests.jl` file that allows running specific test groups via command-line arguments.
2. **Test Suite Structure**: Modular test files, each containing a main entry point function.

### Recommended Directory Structure

We recommend placing your tests in a `suite` subdirectory to keep the top-level `test/` folder clean.

```text
MyPackage.jl/
├── src/
│   └── ...
├── test/
│   ├── runtests.jl          # Main test runner
│   └── suite/               # Directory containing test files
│       ├── test_utils.jl
│       ├── test_core.jl
│       └── ...
└── ...
```

!!! warning "Restriction"
    The `test/` directory **must not** contain a subdirectory named `test`.
    This would conflict with the automatic `test/` prefix stripping (see [Path prefix stripping](@ref)).

## Setting up `runtests.jl`

The `runtests.jl` file is the entry point for your test suite. By using `CTBase.run_tests`, you enable a powerful mechanism to filter and execute specific tests using command-line arguments. This is crucial for fast iteration cycles.

### Example `test/runtests.jl`

```julia
# Load dependencies
using Test
using CTBase # Provides run_tests
using MyPackage # Your package

# Define where your tests are located
const TEST_DIR = @__DIR__

# Run tests using the CTBase test runner
CTBase.run_tests(;
    args=String.(ARGS),                 # Pass command line arguments
    testset_name="MyPackage Tests",     # Name of the main testset
    available_tests=[                   # List of available test groups/files
        "suite/*"                       # Use glob pattern to include all tests in suite/
    ],
    filename_builder = name -> "test_$(name).jl",
    funcname_builder = name -> "test_$(name)",
    test_dir=TEST_DIR,                  # Directory containing test files
)
```

### Keyword Arguments

| Argument | Type | Default | Description |
| :------- | :--- | :------ | :---------- |
| `args` | `AbstractVector{<:AbstractString}` | `String[]` | Command-line arguments (typically `String.(ARGS)`) |
| `testset_name` | `String` | `"Tests"` | Name of the main `@testset` |
| `available_tests` | `Vector` | `Symbol[]` | Allowed tests (Symbols, Strings, or glob patterns). Empty = auto-discovery |
| `filename_builder` | `Function` | `identity` | `name → filename` mapping |
| `funcname_builder` | `Function` | `identity` | `name → function_name` mapping (return `nothing` to skip eval) |
| `eval_mode` | `Bool` | `true` | Whether to call the function after `include` |
| `verbose` | `Bool` | `true` | Verbose `@testset` output |
| `showtiming` | `Bool` | `true` | Show timing in `@testset` output |
| `test_dir` | `String` | `joinpath(pwd(), "test")` | Root directory for test files |
| `on_test_start` | `Function` or `nothing` | `nothing` | Callback before eval (see [Callbacks](@ref)) |
| `on_test_done` | `Function` or `nothing` | `nothing` | Callback after eval (see [Callbacks](@ref)) |
| `progress` | `Bool` | `true` | Show built-in progress bar. Ignored when `on_test_done` is provided |

## Writing Test Files

To support the modular execution model, each test file should define a function (typically matching the filename) that contains the tests. This avoids scope pollution and makes the tests easy to invoke programmatically.

### Example `test/suite/test_utils.jl`

```julia
# The function name matches the `funcname_builder` logic in runtests.jl
function test_utils()
    @testset "Utilities" begin
        @test MyPackage.add(1, 1) == 2
        @test MyPackage.sub(2, 1) == 1
    end
end
```

## Running Tests

### Default (all available tests)

```bash
julia --project -e 'using Pkg; Pkg.test("MyPackage")'
```

### Run a specific test group

```bash
julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["utils"])'
julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["core", "utils"])'
```

### Path prefix stripping

Selection arguments starting with `test/` are **automatically stripped**, so the following are equivalent:

```bash
# These two commands run the same tests:
julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["suite"])'
julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["test/suite"])'
```

This is convenient when tab-completing paths from the project root.

### CLI flags

- `-a` or `--all` — run all available tests (same as no arguments).
- `-n` or `--dryrun` — print the list of tests that would run, without executing them.
- Coverage flags (`coverage=true`, `--coverage`, etc.) are silently filtered out.

### Directory selection

Bare directory names are automatically expanded. For example, `suite/exceptions` is treated as `suite/exceptions/*`, selecting all test files in that directory.

## Progress Bar

By default, `run_tests` displays a progress bar after each test completes:

```text
[████████░░░░░░░░░░░░] ✓ [08/19] suite/exceptions/test_display.jl (2.5s)
[█████████░░░░░░░░░░░] ✓ [09/19] suite/exceptions/test_exceptions.jl (0.6s)
[██████████░░░░░░░░░░] ✗ [10/19] suite/exceptions/test_types.jl FAILED, (0.9s)
```

### Visual elements

- **Bar**: `█` (filled) and `░` (empty), enclosed in `[…]`
- **Status symbol**: `✓` (green, success), `✗` (red, failure/error), `○` (yellow, skipped)
- **Index**: zero-padded `[01/19]` for alignment
- **Spec**: test identifier (relative path or symbol name)
- **Time**: wall-clock elapsed time for the eval phase
- **FAILED**: appended in bold red when the test failed

### Adaptive bar width

The bar width adapts to the number of tests:

- **≤ 20 tests**: width equals the total number of tests (one block per test).
- **> 20 tests**: fixed width of 20 characters. Some tests will not visually advance the bar (the fill is computed as `round(Int, index / total * 20)`).

### Failure detection

The progress bar correctly detects **both** types of failures:

- **Exceptions**: errors thrown during test execution (caught via `try/catch`).
- **`@test` assertion failures**: detected by scanning the enclosing `DefaultTestSet` results before and after eval. This is more reliable than checking `anynonpass`, which is only updated when a testset finishes.

### Disabling the progress bar

Set `progress=false` to disable the built-in progress display:

```julia
CTBase.run_tests(; args=String.(ARGS), progress=false)
```

The progress bar is also automatically disabled when a custom `on_test_done` callback is provided.

## Callbacks

The `on_test_start` and `on_test_done` callbacks allow custom actions during the test lifecycle. Both receive a `TestRunInfo` struct.

### `TestRunInfo`

```julia
struct TestRunInfo
    spec::Union{Symbol,String}          # Test identifier
    filename::String                     # Absolute path of the test file
    func_symbol::Union{Symbol,Nothing}  # Function to call (nothing if eval_mode=false)
    index::Int                           # 1-based index in the selected list
    total::Int                           # Total number of selected tests
    status::Symbol                       # See below
    error::Union{Exception,Nothing}     # Captured exception (only when status == :error)
    elapsed::Union{Float64,Nothing}     # Wall-clock seconds (only in on_test_done)
end
```

### Status values

| Status | When | Callback |
| :----- | :--- | :------- |
| `:pre_eval` | After `include`, before `eval` | `on_test_start` |
| `:post_eval` | After successful `eval` | `on_test_done` |
| `:test_failed` | After `eval` with `@test` failures (no exception) | `on_test_done` |
| `:error` | After `eval` raised an exception | `on_test_done` |
| `:skipped` | When `eval_mode=false` or `on_test_start` returned `false` | `on_test_done` |

### `on_test_start`

Called after the test file is included but before the function is evaluated. Must return a `Bool`:

- `true` — proceed with eval.
- `false` — skip eval (triggers `on_test_done` with `:skipped`).

### `on_test_done`

Called after eval completes (or after skip/error). The built-in progress bar is implemented as a default `on_test_done` callback.

### Example: custom callbacks

```julia
CTBase.run_tests(;
    args=String.(ARGS),
    on_test_start = info -> begin
        print("  [$(info.index)/$(info.total)] $(info.spec)...")
        return true  # proceed with eval
    end,
    on_test_done = info -> begin
        if info.status == :post_eval
            println(" ✓ ($(round(info.elapsed; digits=1))s)")
        elseif info.status == :error || info.status == :test_failed
            println(" ✗ FAILED")
        elseif info.status == :skipped
            println(" ○ skipped")
        end
    end,
)
```

## Advanced Usage

### Filtering Tests with Glob Patterns

You can use glob patterns to organize tests hierarchically:

```julia
CTBase.run_tests(;
    args=String.(ARGS),
    testset_name="MyPackage Tests",
    available_tests=[
        "suite/core/*",       # All core tests
        "suite/utils/*",      # All utility tests
        "suite/integration/*" # All integration tests
    ],
    # ...
)
```

Selection arguments are matched against multiple representations of each candidate:

- The candidate name (e.g. `:utils`)
- The full relative path (e.g. `suite/test_utils.jl`)
- The path without `.jl` extension
- The basename (e.g. `test_utils.jl`)
- The basename without extension
- The basename without `test_` prefix (e.g. `utils`)

### Custom Test Options

Pass custom options to your test suite:

```julia
# In runtests.jl
const VERBOSE = "--verbose" in ARGS
const SHOWTIMING = "--timing" in ARGS

# In test files
function test_utils()
    @testset "Utilities" verbose=VERBOSE showtiming=SHOWTIMING begin
        # tests here
    end
end
```

## Debugging Test Failures

### Common Issues and Solutions

#### Issue: Test function not found

**Error**: `UndefVarError: test_utils not defined`

**Solution**: Ensure your test file exports the test function to the outer scope:

```julia
# At the end of test/suite/test_utils.jl
test_utils() = TestUtils.test_utils()  # Export to outer scope
```

#### Issue: Module conflicts

**Error**: `WARNING: replacing module TestUtils`

**Solution**: Use unique module names for each test file:

```julia
module TestUtilsModule  # Unique name
using Test
using MyPackage

function test_utils()
    @testset "Utilities" begin
        # tests
    end
end

end # module

test_utils() = TestUtilsModule.test_utils()
```

#### Issue: Tests not discovered

**Error**: No tests run when specifying a test name

**Solution**: Check that your `filename_builder` and `funcname_builder` match your file structure:

```julia
# If your files are named "utils_test.jl"
filename_builder = name -> "$(name)_test.jl"

# If your functions are named "run_utils_tests"
funcname_builder = name -> "run_$(name)_tests"
```

#### Issue: `@test` failure shown as success

The progress bar detects `@test` failures by scanning the enclosing testset results before and after eval. If you see a `✓` for a test that should have failed, make sure the test function is wrapped in a `@testset` block so that failures are recorded in the results.

### Debugging with Verbose Output

Run tests with verbose output to see detailed information:

```bash
julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["--verbose", "utils"])'
```

## Best Practices

1. **One test function per file**: Keep test files focused and easy to navigate
2. **Use descriptive names**: Name test files and functions clearly (e.g., `test_optimization.jl`, `test_optimization()`)
3. **Organize by feature**: Group related tests in subdirectories
4. **Fast tests first**: Place quick unit tests before slow integration tests
5. **Isolate test state**: Each test should be independent and not rely on execution order
6. **Use test fixtures**: Create helper functions for common test setup
7. **Document test requirements**: Note any special dependencies or setup needed
8. **No `test/` subdirectory in `test/`**: Avoid naming a subdirectory `test` inside your test directory

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@v1
      - name: Run all tests
        run: julia --project -e 'using Pkg; Pkg.test()'
      - name: Run specific test group
        run: julia --project -e 'using Pkg; Pkg.test(test_args=["core"])'
```

## See Also

- [Exception Handling](exceptions.md): Understanding test failures and exceptions
- [Coverage Guide](coverage.md): Measuring test coverage
