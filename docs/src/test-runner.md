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
    # Function to map a test name in ARGS (like "utils") to a filename
    filename_builder = name -> "test_$(name).jl",
    # Function to map a test name in ARGS to the function to call inside that file
    funcname_builder = name -> "test_$(name)",
    test_dir=TEST_DIR,                  # Directory containing test files
    verbose=true,                       # Show verbose output
    showtiming=true,                    # Show timing information
)
```

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

Note:

- Passing `-a` or `--all` is equivalent to running without arguments.
- Passing `--dry-run` will print the list of tests that would be run, but not execute them.

## Advanced Usage

### Filtering Tests with Glob Patterns

You can use glob patterns to organize tests hierarchically:

```julia
CTBase.run_tests(;
    args=String.(ARGS),
    testset_name="MyPackage Tests",
    available_tests=[
        "suite/core/*",      # All core tests
        "suite/utils/*",     # All utility tests
        "suite/integration/*" # All integration tests
    ],
    # ...
)
```

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
